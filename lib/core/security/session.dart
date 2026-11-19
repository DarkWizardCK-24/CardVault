import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/data/repo.dart';
import 'package:cardvault/core/services/backup_service.dart';
import 'package:cardvault/core/services/documents.dart';
import 'package:cardvault/core/services/notifications.dart';
import 'package:cardvault/core/security/crypto.dart';
import 'package:cardvault/core/security/vault_service.dart';

enum AuthStatus { booting, needsSetup, locked, unlocked }

class AuthState {
  final AuthStatus status;
  final bool bioReady;
  const AuthState(this.status, {this.bioReady = false});
}

final kvProvider = Provider<SecureKv>((ref) => KeychainKv());
final vaultServiceProvider = Provider<VaultService>((ref) => VaultService(ref.read(kvProvider)));

/// Root key lives only in memory while unlocked and is dropped on lock.
class AuthController extends Notifier<AuthState> {
  Uint8List? _root;
  Uint8List? get rootKey => _root;
  VaultService get _svc => ref.read(vaultServiceProvider);

  @override
  AuthState build() => const AuthState(AuthStatus.booting);

  Future<void> boot() async {
    final setUp = await _svc.isSetUp();
    if (!setUp) {
      state = const AuthState(AuthStatus.needsSetup);
      return;
    }
    final bio = await _svc.hasBiometricKey() && await _svc.biometricsAvailable();
    state = AuthState(AuthStatus.locked, bioReady: bio);
  }

  Future<void> _open(Uint8List root) async {
    _root = root;
    await ref.read(storeProvider).open(Crypt.hex(root));
    await ref.read(dataProvider.notifier).load();
    state = AuthState(AuthStatus.unlocked, bioReady: state.bioReady);
    // ignore: unawaited_futures
    NotificationService.instance.sync(ref.read(dataProvider));
  }

  /// Creates the vault. Returns the one-time recovery code.
  Future<String> setup(String password, {bool biometrics = false}) async {
    final r = await _svc.setup(password);
    var bio = false;
    if (biometrics && await _svc.biometricsAvailable()) bio = await _svc.enableBiometrics(r.root);
    state = AuthState(AuthStatus.locked, bioReady: bio);
    pendingRoot = r.root;
    return r.recovery;
  }

  Uint8List? pendingRoot;

  /// Called after the user confirms they saved the recovery code.
  Future<void> finishSetup({BackupPayload? restore}) async {
    final r = pendingRoot!;
    pendingRoot = null;
    await _open(r);
    final d = ref.read(dataProvider.notifier);
    if (restore != null) {
      // Device change: bring everything (and encrypted documents) back under the NEW vault key.
      await d.importAll(restore.data);
      final docs = DocumentService(r);
      for (final e in restore.docs.entries) {
        await docs.save(e.key, e.value);
      }
      final st = ref.read(dataProvider).settings..biometrics = state.bioReady;
      await d.saveSettings(st);
      await d.log('Restored from backup', 'backup');
    } else {
      await d.saveSettings(Settings(biometrics: state.bioReady));
    }
    // ignore: unawaited_futures
    NotificationService.instance.sync(ref.read(dataProvider));
  }

  Future<void> unlockWithPassword(String pw) async => _open(await _svc.unlockWithPassword(pw));

  Future<bool> unlockWithBiometrics() async {
    final k = await _svc.unlockWithBiometrics();
    if (k == null) return false;
    await _open(k);
    return true;
  }

  Future<void> recover(String code, String newPw) async => _open(await _svc.recover(code, newPw));

  Future<void> lock() async {
    if (state.status != AuthStatus.unlocked) return;
    _root = null;
    await ref.read(storeProvider).close();
    ref.read(dataProvider.notifier).clear();
    final bio = await _svc.hasBiometricKey() && await _svc.biometricsAvailable();
    state = AuthState(AuthStatus.locked, bioReady: bio);
  }

  /// Destroys the vault completely (keys + data).
  Future<void> destroy() async {
    await ref.read(dataProvider.notifier).wipeAll();
    await ref.read(storeProvider).close();
    await _svc.wipeKeys();
    await NotificationService.instance.cancelAll();
    _root = null;
    state = const AuthState(AuthStatus.needsSetup);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
