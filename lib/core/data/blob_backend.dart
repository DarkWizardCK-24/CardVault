import 'dart:typed_data';
import 'blob_backend_io.dart' if (dart.library.js_interop) 'blob_backend_web.dart' as impl;

/// Tiny named-blob storage used by the encrypted store and the document vault on
/// platforms without SQLCipher (desktop, web). Only ever receives ciphertext.
abstract class BlobBackend {
  Future<Uint8List?> read(String name);
  Future<void> write(String name, Uint8List bytes);

  /// Best-effort secure delete (overwrites first where the medium allows it).
  Future<void> delete(String name);
  Future<List<String>> list();
}

BlobBackend createBlobBackend() => impl.create();
