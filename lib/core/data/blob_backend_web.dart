import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'blob_backend.dart';

BlobBackend create() => _WebBlobBackend();

/// Browser localStorage (ciphertext only; roughly 5 MB per origin).
class _WebBlobBackend implements BlobBackend {
  static const _prefix = 'cardvault.';

  @override
  Future<Uint8List?> read(String name) async {
    final v = web.window.localStorage.getItem('$_prefix$name');
    return v == null ? null : base64Decode(v);
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    try {
      web.window.localStorage.setItem('$_prefix$name', base64Encode(bytes));
    } catch (_) {
      throw StateError('Browser storage is full. Export a backup and remove some documents.');
    }
  }

  @override
  Future<void> delete(String name) async => web.window.localStorage.removeItem('$_prefix$name');

  @override
  Future<List<String>> list() async {
    final s = web.window.localStorage;
    return [
      for (var i = 0; i < s.length; i++)
        if (s.key(i)!.startsWith(_prefix)) s.key(i)!.substring(_prefix.length),
    ];
  }
}
