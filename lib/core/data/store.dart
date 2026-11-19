import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:cardvault/core/data/blob_backend.dart';
import 'package:cardvault/core/security/crypto.dart';

/// Storage abstraction behind the repository.
///  * Android / iOS  -> [SqlCipherStore] (AES-256 encrypted SQLite).
///  * Windows / web  -> [EncryptedBlobStore] (AES-256-GCM sealed file / browser blob).
///  * Tests          -> [MemoryStore].
abstract class RecordStore {
  Future<void> open(String hexKey);
  Future<Map<String, List<Map<String, dynamic>>>> loadAll();
  Future<void> put(String kind, String id, Map<String, dynamic> data);
  Future<void> remove(String kind, String id);
  Future<void> wipe();
  Future<void> close();
}

/// Encrypted SQLite (SQLCipher). One generic table keeps every module's CRUD
/// transactional and migration-friendly (JSON payload per row).
class SqlCipherStore implements RecordStore {
  Database? _db;
  @override
  Future<void> open(String hexKey) async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'cardvault.db'),
      password: hexKey,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE records(kind TEXT NOT NULL, id TEXT NOT NULL, data TEXT NOT NULL, PRIMARY KEY(kind,id))');
        await db.execute('CREATE INDEX idx_kind ON records(kind)');
      },
    );
    // Overwrite freed pages so deleted records do not linger inside the file.
    await _db!.rawQuery('PRAGMA secure_delete = ON');
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> loadAll() async {
    final rows = await _db!.query('records');
    final out = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      (out[r['kind'] as String] ??= []).add(jsonDecode(r['data'] as String) as Map<String, dynamic>);
    }
    return out;
  }

  @override
  Future<void> put(String kind, String id, Map<String, dynamic> data) =>
      _db!.insert('records', {'kind': kind, 'id': id, 'data': jsonEncode(data)}, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> remove(String kind, String id) => _db!.delete('records', where: 'kind=? AND id=?', whereArgs: [kind, id]);

  @override
  Future<void> wipe() async {
    await _db?.delete('records');
    await _db?.execute('VACUUM');
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// In-memory store used by unit and widget tests.
class MemoryStore implements RecordStore {
  final data = <String, Map<String, Map<String, dynamic>>>{};
  @override
  Future<void> open(String hexKey) async {}
  @override
  Future<Map<String, List<Map<String, dynamic>>>> loadAll() async =>
      data.map((k, v) => MapEntry(k, v.values.map((e) => Map<String, dynamic>.from(jsonDecode(jsonEncode(e)))).toList()));
  @override
  Future<void> put(String kind, String id, Map<String, dynamic> d) async =>
      (data[kind] ??= {})[id] = Map<String, dynamic>.from(jsonDecode(jsonEncode(d)));
  @override
  Future<void> remove(String kind, String id) async => data[kind]?.remove(id);
  @override
  Future<void> wipe() async => data.clear();
  @override
  Future<void> close() async {}
}

/// Persistent store for platforms where SQLCipher is unavailable. The whole record set is kept
/// in memory while unlocked and written back as ONE AES-256-GCM sealed blob under a sub-key of
/// the vault key — nothing readable ever touches disk / localStorage.
class EncryptedBlobStore extends MemoryStore {
  static const _name = 'records.enc';
  final BlobBackend backend;
  Uint8List? _key;
  EncryptedBlobStore(this.backend);

  @override
  Future<void> open(String hexKey) async {
    _key = await Crypt.subKey(Crypt.unhex(hexKey), 'records');
    final blob = await backend.read(_name);
    data.clear();
    if (blob != null) {
      final plain = await Crypt.open(_key!, blob);
      final m = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      for (final k in m.keys) {
        data[k] = {for (final r in (m[k] as List)) (r as Map<String, dynamic>)['id'] as String: Map<String, dynamic>.from(r)};
      }
    }
  }

  Future<void> _flush() async {
    if (_key == null) return;
    final out = {for (final e in data.entries) e.key: e.value.values.toList()};
    await backend.write(_name, await Crypt.seal(_key!, utf8.encode(jsonEncode(out))));
  }

  @override
  Future<void> put(String kind, String id, Map<String, dynamic> d) async {
    await super.put(kind, id, d);
    await _flush();
  }

  @override
  Future<void> remove(String kind, String id) async {
    await super.remove(kind, id);
    await _flush();
  }

  @override
  Future<void> wipe() async {
    await super.wipe();
    await backend.delete(_name);
  }

  @override
  Future<void> close() async {
    data.clear();
    _key = null;
  }
}

bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

RecordStore createStore() => isMobile ? SqlCipherStore() : EncryptedBlobStore(createBlobBackend());
