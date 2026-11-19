import 'dart:io';
import 'dart:typed_data';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/core/data/blob_backend.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemBlobs implements BlobBackend {
  final m = <String, Uint8List>{};
  @override
  Future<Uint8List?> read(String name) async => m[name];
  @override
  Future<void> write(String name, Uint8List bytes) async => m[name] = bytes;
  @override
  Future<void> delete(String name) async => m.remove(name);
  @override
  Future<List<String>> list() async => m.keys.toList();
}

void main() {
  group('Offline guarantee', () {
    test('no networking code in lib/', () {
      final banned = RegExp(r'HttpClient|http\.get|http\.post|package:http/|package:dio|WebSocket|Socket\.connect|RawSocket|dart:html|XMLHttpRequest|fetch\(|Uri\.parse\(.https?:');
      final hits = <String>[];
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final text = f.readAsStringSync();
        if (banned.hasMatch(text)) hits.add(f.path);
      }
      expect(hits, isEmpty, reason: 'network APIs found in: $hits');
    });

    test('no networking packages or cloud SDKs in pubspec', () {
      final y = File('pubspec.yaml').readAsStringSync();
      for (final pkg in ['http:', 'dio:', 'firebase_', 'supabase', 'cloud_firestore', 'google_fonts', 'sentry', 'analytics', 'crashlytics']) {
        expect(y.contains(pkg), isFalse, reason: pkg);
      }
    });

    test('release Android manifest does not request the INTERNET permission', () {
      expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync().contains('android.permission.INTERNET'), isFalse);
    });

    test('iOS has no App Transport Security exceptions', () {
      expect(File('ios/Runner/Info.plist').readAsStringSync().contains('NSAppTransportSecurity'), isFalse);
    });

    test('fonts and images are bundled, not downloaded', () {
      expect(File('assets/fonts/Inter.ttf').existsSync(), isTrue);
      expect(File('assets/brand/logo.png').existsSync(), isTrue);
    });
  });

  group('Encrypted blob store (desktop / web persistence)', () {
    test('data survives a reopen but is never readable in the blob', () async {
      final blobs = _MemBlobs();
      final key = Crypt.hex(Crypt.randomBytes(32));
      final s1 = EncryptedBlobStore(blobs);
      await s1.open(key);
      await s1.put('card', 'a', {'id': 'a', 'bank': 'HDFC Bank', 'last4': '4321'});
      final raw = String.fromCharCodes(blobs.m['records.enc']!);
      expect(raw.contains('HDFC'), isFalse);
      expect(raw.contains('4321'), isFalse);
      await s1.close();
      final s2 = EncryptedBlobStore(blobs);
      await s2.open(key);
      expect((await s2.loadAll())['card']!.single['bank'], 'HDFC Bank');
      // wrong key cannot open it
      final s3 = EncryptedBlobStore(blobs);
      await expectLater(s3.open(Crypt.hex(Crypt.randomBytes(32))), throwsA(anything));
      await s2.remove('card', 'a');
      expect((await s2.loadAll())['card'] ?? [], isEmpty);
    });

    test('encrypted documents round trip and secure delete', () async {
      final blobs = _MemBlobs();
      final svc = DocumentService(Crypt.randomBytes(32), blobs);
      await svc.save('d1', Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(blobs.m['doc_d1.enc']!.length, greaterThan(5)); // nonce + mac overhead
      expect(await svc.read('d1'), [1, 2, 3, 4, 5]);
      await svc.secureDelete('d1');
      await expectLater(svc.read('d1'), throwsA(anything));
      await DocumentService(Crypt.randomBytes(32), blobs).save('d2', Uint8List.fromList([9]));
      await expectLater(svc.read('d2'), throwsA(anything)); // other key cannot read
    });
  });

  group('Backup export / import (device change)', () {
    setUp(() => Crypt.kdfIterations = 1000);

    test('round trip keeps data and documents; wrong password and foreign files rejected', () async {
      final data = {
        'version': 1,
        'cards': [
          {'id': 'c1', 'bank': 'Axis Bank', 'last4': '1109'}
        ],
        'benefits': [],
        'txns': [],
      };
      final bytes = await BackupService.build(data: data, docs: {'d1': Uint8List.fromList([7, 7, 7])}, password: 'correct-horse-1');
      expect(String.fromCharCodes(bytes).contains('Axis'), isFalse); // ciphertext only
      expect(String.fromCharCodes(bytes).contains('1109'), isFalse);
      final back = await BackupService.open(bytes, 'correct-horse-1');
      expect(back.cards, 1);
      expect(back.documents, 1);
      expect(back.docs['d1'], [7, 7, 7]);
      expect(back.summary, contains('1 card'));
      await expectLater(BackupService.open(bytes, 'wrong-password-1'), throwsA(isA<AuthFailure>()));
      await expectLater(BackupService.open(Uint8List.fromList([1, 2, 3]), 'x'), throwsA(isA<AuthFailure>()));
      expect(BackupService.fileName(DateTime(2026, 3, 9)), 'cardvault-2026-03-09.cvbackup');
    });
  });
}
