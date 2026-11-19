import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cardvault/core/security/crypto.dart';

/// Key/value abstraction so security flows are unit-testable without a device.
abstract class SecureKv {
  Future<String?> read(String k);
  Future<void> write(String k, String v);
  Future<void> delete(String k);
  Future<void> clear();
}

class KeychainKv implements SecureKv {
  // iOS: Keychain (this-device-only, available after first unlock). Android: Keystore-backed.
  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  @override
  Future<String?> read(String k) => _s.read(key: k);
  @override
  Future<void> write(String k, String v) => _s.write(key: k, value: v);
  @override
  Future<void> delete(String k) => _s.delete(key: k);
  @override
  Future<void> clear() => _s.deleteAll();
}

class MemoryKv implements SecureKv {
  final m = <String, String>{};
  @override
  Future<String?> read(String k) async => m[k];
  @override
  Future<void> write(String k, String v) async => m[k] = v;
  @override
  Future<void> delete(String k) async => m.remove(k);
  @override
  Future<void> clear() async => m.clear();
}

class AuthFailure implements Exception {
  final String message;
  final Duration? lockedFor;
  AuthFailure(this.message, {this.lockedFor});
  @override
  String toString() => message;
}

/// Owns the vault root key (the SQLCipher key).
///
/// * A random 256-bit root key is created at setup – never derived from a hard-coded value.
/// * The root key is stored only *wrapped* (AES-GCM) under a key derived from the master
///   password (PBKDF2) and, separately, under a key derived from a one-time recovery code.
///   There is deliberately no "reset password" path that bypasses encryption.
/// * Biometric unlock keeps a copy of the root key in the OS Keychain / Keystore, released
///   only after a successful biometric prompt.
class VaultService {
  final SecureKv kv;
  final LocalAuthentication _la = LocalAuthentication();
  VaultService(this.kv);

  static const _kSalt = 'cv.salt', _kWrap = 'cv.wrap', _kRecSalt = 'cv.rsalt', _kRecWrap = 'cv.rwrap';
  static const _kBio = 'cv.bio', _kFails = 'cv.fails', _kLock = 'cv.lock';

  Future<bool> isSetUp() async => (await kv.read(_kWrap)) != null;

  static String? validatePassword(String p) {
    if (p.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'[0-9]').hasMatch(p)) return 'Mix letters and numbers';
    return null;
  }

  /// Returns (rootKey, recoveryCode). The recovery code is shown exactly once.
  Future<({Uint8List root, String recovery})> setup(String password) async {
    final err = validatePassword(password);
    if (err != null) throw AuthFailure(err);
    final root = Crypt.randomBytes(32);
    final salt = Crypt.randomBytes(16);
    final rsalt = Crypt.randomBytes(16);
    final recovery = Crypt.recoveryCode();
    final pk = await Crypt.derive(password, salt);
    final rk = await Crypt.derive(recovery, rsalt);
    await kv.write(_kSalt, Crypt.b64(salt));
    await kv.write(_kRecSalt, Crypt.b64(rsalt));
    await kv.write(_kWrap, Crypt.b64(await Crypt.seal(pk, root)));
    await kv.write(_kRecWrap, Crypt.b64(await Crypt.seal(rk, root)));
    await kv.write(_kFails, '0');
    return (root: root, recovery: recovery);
  }

  // ---- Throttling: exponential back-off after 3 failures ----
  Future<Duration?> lockRemaining() async {
    final v = await kv.read(_kLock);
    if (v == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(int.parse(v));
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  static Duration backoff(int fails) {
    if (fails < 3) return Duration.zero;
    final secs = 15 * (1 << (fails - 3).clamp(0, 10));
    return Duration(seconds: secs.clamp(15, 3600));
  }

  Future<Never> _fail(String msg) async {
    final n = (int.tryParse(await kv.read(_kFails) ?? '0') ?? 0) + 1;
    await kv.write(_kFails, '$n');
    final d = backoff(n);
    if (d > Duration.zero) {
      await kv.write(_kLock, '${DateTime.now().add(d).millisecondsSinceEpoch}');
      throw AuthFailure('Too many attempts. Try again in ${d.inSeconds}s.', lockedFor: d);
    }
    throw AuthFailure(msg);
  }

  Future<void> _ok() async {
    await kv.write(_kFails, '0');
    await kv.delete(_kLock);
  }

  Future<Uint8List> unlockWithPassword(String password) async {
    final left = await lockRemaining();
    if (left != null) throw AuthFailure('Locked. Try again in ${left.inSeconds + 1}s.', lockedFor: left);
    final salt = Crypt.ub64((await kv.read(_kSalt))!);
    final wrap = Crypt.ub64((await kv.read(_kWrap))!);
    final pk = await Crypt.derive(password, salt);
    try {
      final root = await Crypt.open(pk, wrap);
      await _ok();
      return root;
    } catch (_) {
      return _fail('Incorrect master password');
    }
  }

  /// Recovery requires the one-time code AND forces a new master password. Data stays encrypted.
  Future<Uint8List> recover(String code, String newPassword) async {
    final err = validatePassword(newPassword);
    if (err != null) throw AuthFailure(err);
    final left = await lockRemaining();
    if (left != null) throw AuthFailure('Locked. Try again in ${left.inSeconds + 1}s.', lockedFor: left);
    final rsalt = Crypt.ub64((await kv.read(_kRecSalt))!);
    final rwrap = Crypt.ub64((await kv.read(_kRecWrap))!);
    final rk = await Crypt.derive(code.trim().toUpperCase(), rsalt);
    Uint8List root;
    try {
      root = await Crypt.open(rk, rwrap);
    } catch (_) {
      return _fail('Invalid recovery code');
    }
    await _ok();
    await _rewrap(root, newPassword);
    return root;
  }

  Future<void> _rewrap(Uint8List root, String password) async {
    final salt = Crypt.randomBytes(16);
    final pk = await Crypt.derive(password, salt);
    await kv.write(_kSalt, Crypt.b64(salt));
    await kv.write(_kWrap, Crypt.b64(await Crypt.seal(pk, root)));
  }

  Future<void> changePassword(Uint8List root, String newPassword) async {
    final err = validatePassword(newPassword);
    if (err != null) throw AuthFailure(err);
    await _rewrap(root, newPassword);
  }

  /// Issue a fresh recovery code (invalidates the old one).
  Future<String> regenerateRecovery(Uint8List root) async {
    final rsalt = Crypt.randomBytes(16);
    final code = Crypt.recoveryCode();
    final rk = await Crypt.derive(code, rsalt);
    await kv.write(_kRecSalt, Crypt.b64(rsalt));
    await kv.write(_kRecWrap, Crypt.b64(await Crypt.seal(rk, root)));
    return code;
  }

  // ---- Biometrics ----
  Future<bool> biometricsAvailable() async {
    try {
      return await _la.canCheckBiometrics && (await _la.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _prompt(String reason) async {
    try {
      return await _la.authenticate(
          localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> enableBiometrics(Uint8List root) async {
    if (!await _prompt('Enable biometric unlock for CardVault')) return false;
    await kv.write(_kBio, Crypt.b64(root));
    return true;
  }

  Future<void> disableBiometrics() => kv.delete(_kBio);
  Future<bool> hasBiometricKey() async => (await kv.read(_kBio)) != null;

  Future<Uint8List?> unlockWithBiometrics() async {
    final k = await kv.read(_kBio);
    if (k == null) return null;
    if (!await _prompt('Unlock CardVault')) return null;
    return Crypt.ub64(k);
  }

  /// Step-up check before revealing sensitive fields (full card number).
  Future<bool> reauthenticate({String? password}) async {
    if (password != null) {
      try {
        await unlockWithPassword(password);
        return true;
      } on AuthFailure {
        return false;
      }
    }
    if (!await hasBiometricKey()) return false;
    return _prompt('Reveal protected card details');
  }

  Future<void> wipeKeys() => kv.clear();

  // ---- Encrypted backups (password-based, independent of the vault key) ----
  static Future<String> encryptBackup(Map<String, dynamic> data, String password) async {
    final salt = Crypt.randomBytes(16);
    final key = await Crypt.derive(password, salt);
    final sealed = await Crypt.seal(key, utf8.encode(jsonEncode(data)));
    return jsonEncode({'cardvault': 1, 'salt': Crypt.b64(salt), 'data': Crypt.b64(sealed)});
  }

  static Future<Map<String, dynamic>> decryptBackup(String file, String password) async {
    try {
      final j = jsonDecode(file) as Map<String, dynamic>;
      final key = await Crypt.derive(password, Crypt.ub64(j['salt']));
      final plain = await Crypt.open(key, Crypt.ub64(j['data']));
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } catch (_) {
      throw AuthFailure('Wrong backup password or the file is corrupted');
    }
  }
}
