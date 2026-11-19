import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Thin wrappers over AES-256-GCM and PBKDF2-HMAC-SHA256.
/// No keys or passwords are hard-coded anywhere in the app.
class Crypt {
  static int kdfIterations = 120000; // lowered only by tests
  static final _aes = AesGcm.with256bits();

  static Uint8List randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  /// Derives a 32-byte key from a secret. Runs in a background isolate so the UI never janks.
  static Future<Uint8List> derive(String secret, List<int> salt, {int? iterations}) {
    final iters = iterations ?? kdfIterations;
    return Isolate.run(() async {
        final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iters, bits: 256);
        final k = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(secret)), nonce: salt);
        return Uint8List.fromList(await k.extractBytes());
      });
  }

  /// Output layout: nonce(12) | ciphertext | mac(16)
  static Future<Uint8List> seal(List<int> key, List<int> plain) async {
    final box = await _aes.encrypt(plain, secretKey: SecretKey(key));
    return Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Throws [SecretBoxAuthenticationError] when the key is wrong or data was tampered.
  static Future<Uint8List> open(List<int> key, List<int> sealed) async {
    final nonce = sealed.sublist(0, 12);
    final mac = sealed.sublist(sealed.length - 16);
    final ct = sealed.sublist(12, sealed.length - 16);
    final out = await _aes.decrypt(SecretBox(ct, nonce: nonce, mac: Mac(mac)), secretKey: SecretKey(key));
    return Uint8List.fromList(out);
  }

  /// Sub-key for document files so the raw DB key is never used directly for files.
  static Future<Uint8List> subKey(List<int> root, String label) async {
    final mac = await Hmac.sha256().calculateMac(utf8.encode(label), secretKey: SecretKey(root));
    return Uint8List.fromList(mac.bytes);
  }

  static String hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  static Uint8List unhex(String s) =>
      Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);
  static String b64(List<int> b) => base64Encode(b);
  static Uint8List ub64(String s) => base64Decode(s);

  /// Human-friendly recovery code, e.g. 7KQ2-M9XA-...; ~100 bits of entropy.
  static String recoveryCode() {
    const a = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    String g() => List.generate(4, (_) => a[r.nextInt(a.length)]).join();
    return List.generate(5, (_) => g()).join('-');
  }
}
