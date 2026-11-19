import 'package:cardvault/core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calculators', () {
    test('EMI matches the standard reducing-balance formula', () {
      expect(Calc.emi(1000000, 10, 120), closeTo(13215.07, .01));
      expect(Calc.emi(120000, 0, 12), 10000);
      expect(Calc.emi(0, 10, 12), 0);
    });
    test('amortization fully repays principal and totals are consistent', () {
      final r = Calc.loan(500000, 11, 36);
      expect(r.schedule.length, 36);
      expect(r.schedule.last.balance, closeTo(0, .01));
      expect(r.schedule.fold(0.0, (a, x) => a + x.principal), closeTo(500000, .5));
      expect(r.totalPayment, closeTo(500000 + r.totalInterest, .01));
    });
    test('interest', () {
      expect(Calc.simpleInterest(100000, 8, 3), 24000);
      expect(Calc.compoundInterest(100000, 12, 1, 12), closeTo(12682.50, .01));
    });
    test('prepayment shortens tenure and saves interest', () {
      final r = Calc.prepay(2500000, 8.5, 180, 300000, 24);
      expect(r.newMonths, lessThan(180));
      expect(r.interestSaved, greaterThan(0));
    });
  });

  group('Validation', () {
    test('luhn', () {
      expect(Validate.luhn('4111 1111 1111 1111'), isTrue);
      expect(Validate.luhn('4111 1111 1111 1112'), isFalse);
      expect(Validate.cardNumber(''), isNull);
      expect(Validate.cardNumber('4111111111111112'), isNotNull);
      expect(Validate.cardNumber('abcd'), isNotNull);
    });
    test('last4, day, amount', () {
      expect(Validate.last4('1234'), isNull);
      expect(Validate.last4('12a4'), isNotNull);
      expect(Validate.day('32'), isNotNull);
      expect(Validate.day('15'), isNull);
      expect(Validate.amount('-5'), isNotNull);
      expect(Validate.amount('1,200.50'), isNull);
    });
    test('masking never exposes more than last 4', () {
      expect(maskNumber('4111111111111111', ''), '•••• •••• •••• 1111');
    });
    test('INR formatting uses Indian grouping', () => expect(money(1234567), '₹12,34,567'));
  });

  group('Models', () {
    test('card secrets never leak into titles, subtitles or the activity text', () {
      final c = CardItem(bank: 'HDFC Bank', number: '4111111111111111', cvv: '987', pin: '6543');
      for (final shown in [c.title, 'Added card ${c.title}']) {
        expect(shown.contains('987'), isFalse);
        expect(shown.contains('6543'), isFalse);
        expect(shown.contains('4111111111111111'), isFalse);
      }
      // there is still no OTP / banking password field
      final keys = c.toMap().keys.map((k) => k.toLowerCase()).join(' ');
      for (final banned in ['otp', 'password']) {
        expect(keys.contains(banned), isFalse, reason: banned);
      }
    });
    test('round trip', () {
      final c = CardItem(bank: 'HDFC Bank', last4: '1111', creditLimit: 1000, outstanding: 250, collectionIds: ['a']);
      final d = CardItem.fromMap(c.toMap());
      expect(d.bank, 'HDFC Bank');
      expect(d.utilization, 25);
      expect(d.available, 750);
      expect(d.collectionIds, ['a']);
    });
  });

  group('Data layer (CRUD, aggregates, events)', () {
    ProviderContainer make() {
      final c = ProviderContainer(overrides: [storeProvider.overrideWithValue(MemoryStore())]);
      addTearDown(c.dispose);
      return c;
    }

    test('card + transaction CRUD persists across reload', () async {
      final c = make();
      final n = c.read(dataProvider.notifier);
      final card = CardItem(bank: 'Axis Bank', last4: '9999', creditLimit: 100000, outstanding: 40000, dueDay: 10, billingDay: 1);
      await n.saveCard(card, isNew: true);
      await n.saveTxn(Txn(merchant: 'Shop', amount: 500, cardId: card.id));
      await n.load();
      final d = c.read(dataProvider);
      expect(d.cards.length, 1);
      expect(d.txns.single.merchant, 'Shop');
      expect(d.utilization, 40);
      expect(d.totalAvailable, 60000);
      card.nickname = 'Edited';
      await n.saveCard(card);
      expect(c.read(dataProvider).cards.single.nickname, 'Edited');
      await n.deleteCard(card.id);
      expect(c.read(dataProvider).cards, isEmpty);
    });

    test('payment reduces outstanding', () async {
      final c = make();
      final n = c.read(dataProvider.notifier);
      final card = CardItem(creditLimit: 1000, outstanding: 600);
      await n.saveCard(card, isNew: true);
      await n.savePayment(Payment(cardId: card.id, amount: 250));
      expect(c.read(dataProvider).card(card.id)!.outstanding, 350);
    });

    test('calendar events include due, billing and expiry', () async {
      final c = make();
      final n = c.read(dataProvider.notifier);
      await n.saveCard(CardItem(bank: 'X', last4: '1', billingDay: 5, dueDay: 20, expYear: DateTime.now().year + 1), isNew: true);
      final types = buildEvents(c.read(dataProvider)).map((e) => e.type).toSet();
      expect(types, containsAll(['due', 'billing', 'expiry']));
    });

    test('export then import restores data', () async {
      final c = make();
      final n = c.read(dataProvider.notifier);
      await n.saveCard(CardItem(bank: 'Kotak', last4: '4242'), isNew: true);
      await n.saveGoal(Goal(name: 'Trip', target: 100));
      final dump = n.exportAll();
      await n.wipeAll();
      expect(c.read(dataProvider).cards, isEmpty);
      await n.importAll(dump);
      expect(c.read(dataProvider).cards.single.bank, 'Kotak');
      expect(c.read(dataProvider).goals.single.name, 'Trip');
    });
  });

  group('Security flows', () {
    setUp(() => Crypt.kdfIterations = 1000);

    test('AES-GCM round trip and tamper detection', () async {
      final k = Crypt.randomBytes(32);
      final sealed = await Crypt.seal(k, [1, 2, 3, 4]);
      expect(await Crypt.open(k, sealed), [1, 2, 3, 4]);
      final other = await Crypt.seal(k, [9]);
      await expectLater(Crypt.open(Crypt.randomBytes(32), other), throwsA(anything));
      sealed[sealed.length - 1] ^= 1;
      await expectLater(Crypt.open(k, sealed), throwsA(anything));
    });

    test('setup, unlock, wrong password, recovery', () async {
      final svc = VaultService(MemoryKv());
      expect(await svc.isSetUp(), isFalse);
      final r = await svc.setup('hunter2hunter');
      expect(await svc.isSetUp(), isTrue);
      expect(await svc.unlockWithPassword('hunter2hunter'), r.root);
      await expectLater(svc.unlockWithPassword('wrongpass1'), throwsA(isA<AuthFailure>()));
      final rec = await svc.recover(r.recovery, 'newpassword9');
      expect(rec, r.root); // same root key => data stays decryptable
      expect(await svc.unlockWithPassword('newpassword9'), r.root);
      await expectLater(svc.unlockWithPassword('hunter2hunter'), throwsA(isA<AuthFailure>()));
      await expectLater(svc.recover('AAAA-BBBB-CCCC-DDDD-EEEE', 'another1pass'), throwsA(isA<AuthFailure>()));
    });

    test('weak passwords rejected', () {
      expect(VaultService.validatePassword('short1'), isNotNull);
      expect(VaultService.validatePassword('onlyletters'), isNotNull);
      expect(VaultService.validatePassword('goodpass123'), isNull);
    });

    test('throttling kicks in after repeated failures', () async {
      final svc = VaultService(MemoryKv());
      await svc.setup('hunter2hunter');
      for (var i = 0; i < 2; i++) {
        await expectLater(svc.unlockWithPassword('bad-pass-1'), throwsA(isA<AuthFailure>()));
      }
      await expectLater(svc.unlockWithPassword('bad-pass-1'), throwsA(predicate((e) => e is AuthFailure && e.lockedFor != null)));
      expect(await svc.lockRemaining(), isNotNull);
      // even the correct password is refused while locked
      await expectLater(svc.unlockWithPassword('hunter2hunter'), throwsA(isA<AuthFailure>()));
      expect(VaultService.backoff(2), Duration.zero);
      expect(VaultService.backoff(4) > VaultService.backoff(3), isTrue);
    });

    test('root key is never stored in plaintext in secure storage', () async {
      final kv = MemoryKv();
      final svc = VaultService(kv);
      final r = await svc.setup('hunter2hunter');
      for (final v in kv.m.values) {
        expect(v.contains(Crypt.b64(r.root)), isFalse);
        expect(v.contains(Crypt.hex(r.root)), isFalse);
      }
    });

    test('encrypted backup round trip and wrong password', () async {
      final enc = await VaultService.encryptBackup({'cards': [{'id': 'x', 'last4': '1111'}]}, 'backup-pass-1');
      expect(enc.contains('1111'), isFalse);
      final back = await VaultService.decryptBackup(enc, 'backup-pass-1');
      expect(back['cards'][0]['id'], 'x');
      await expectLater(VaultService.decryptBackup(enc, 'nope-nope-1'), throwsA(isA<AuthFailure>()));
    });
  });
}
