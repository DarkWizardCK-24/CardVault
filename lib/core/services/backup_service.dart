import 'dart:convert';
import 'dart:typed_data';
import 'package:cardvault/core/security/vault_service.dart';

/// Decrypted contents of a `.cvbackup` file.
class BackupPayload {
  final Map<String, dynamic> data;

  /// Document id -> decrypted bytes.
  final Map<String, Uint8List> docs;
  const BackupPayload(this.data, this.docs);

  int count(String key) => (data[key] as List?)?.length ?? 0;
  int get cards => count('cards');
  int get documents => docs.length;
  String get summary =>
      '$cards card${cards == 1 ? '' : 's'}, ${count('benefits')} benefits, ${count('txns')} transactions, $documents document${documents == 1 ? '' : 's'}';
}

/// Builds and reads encrypted backup files. Pure Dart: no I/O, no network.
/// The file is AES-256-GCM encrypted with a key derived (PBKDF2) from a password the user
/// chooses at export time, so it is independent of the device and can be restored anywhere.
class BackupService {
  static const extension = 'cvbackup';

  static String fileName([DateTime? now]) {
    final d = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    return 'cardvault-$d.$extension';
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> data,
    required Map<String, Uint8List> docs,
    required String password,
  }) async {
    final payload = {
      ...data,
      'docFiles': {for (final e in docs.entries) e.key: base64Encode(e.value)},
      'exportedAt': DateTime.now().toIso8601String(),
    };
    final enc = await VaultService.encryptBackup(payload, password);
    return Uint8List.fromList(utf8.encode(enc));
  }

  /// Throws [AuthFailure] for a wrong password, corrupted or foreign files.
  static Future<BackupPayload> open(Uint8List bytes, String password) async {
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      throw AuthFailure('This is not a CardVault backup file');
    }
    final m = await VaultService.decryptBackup(text, password);
    if (m['version'] == null || m['cards'] == null) throw AuthFailure('This is not a CardVault backup file');
    final files = Map<String, dynamic>.from(m['docFiles'] ?? {});
    final docs = <String, Uint8List>{for (final e in files.entries) e.key: base64Decode(e.value as String)};
    m.remove('docFiles');
    return BackupPayload(m, docs);
  }
}
