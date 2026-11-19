import 'dart:typed_data';
import 'package:cardvault/core/data/blob_backend.dart';
import 'package:cardvault/core/security/crypto.dart';

/// Encrypted document storage. Every file is AES-256-GCM sealed with a sub-key derived from the
/// vault root key and stored in the app-private area (never in shared storage, gallery or
/// Downloads; browser storage on web). Plaintext exists only in memory while previewing.
class DocumentService {
  final Uint8List rootKey;
  final BlobBackend _backend;
  DocumentService(this.rootKey, [BlobBackend? backend]) : _backend = backend ?? createBlobBackend();

  static String _name(String id) => 'doc_$id.enc';

  Future<void> save(String id, Uint8List plain) async {
    final key = await Crypt.subKey(rootKey, 'documents');
    await _backend.write(_name(id), await Crypt.seal(key, plain));
  }

  Future<Uint8List> read(String id) async {
    final blob = await _backend.read(_name(id));
    if (blob == null) throw StateError('Document file missing');
    final key = await Crypt.subKey(rootKey, 'documents');
    return Crypt.open(key, blob);
  }

  /// Overwrites the ciphertext before removing it (best effort — flash wear-levelling means
  /// no software can guarantee physical erasure).
  Future<void> secureDelete(String id) => _backend.delete(_name(id));

  Future<void> wipeAll() async {
    for (final n in await _backend.list()) {
      if (n.startsWith('doc_')) await _backend.delete(n);
    }
  }
}
