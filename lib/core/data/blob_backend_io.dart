import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'blob_backend.dart';

BlobBackend create() => _FileBlobBackend();

/// Files in the app-private support directory (never a shared or user-visible folder).
class _FileBlobBackend implements BlobBackend {
  Directory? _dir;
  Future<Directory> get dir async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'vault_blobs'));
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  Future<File> _f(String name) async => File(p.join((await dir).path, name));

  @override
  Future<Uint8List?> read(String name) async {
    final f = await _f(name);
    return await f.exists() ? await f.readAsBytes() : null;
  }

  @override
  Future<void> write(String name, Uint8List bytes) async => (await _f(name)).writeAsBytes(bytes, flush: true);

  @override
  Future<void> delete(String name) async {
    final f = await _f(name);
    if (!await f.exists()) return;
    final r = Random.secure();
    await f.writeAsBytes(Uint8List.fromList(List.generate(await f.length(), (_) => r.nextInt(256))), flush: true);
    await f.delete();
  }

  @override
  Future<List<String>> list() async => [for (final e in (await dir).listSync()) if (e is File) p.basename(e.path)];
}
