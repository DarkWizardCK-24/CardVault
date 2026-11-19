import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Card number', () {
    final f = CardNumberFormatter();
    String fmt(String s) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s)).text;

    test('groups digits in fours', () => expect(fmt('4111111111111111'), '4111 1111 1111 1111'));
    test('never accepts more than 16 digits', () => expect(fmt('41111111111111119999'), '4111 1111 1111 1111'));
    test('strips non-digits', () => expect(fmt('4111-1111 abc'), '4111 1111'));
    test('validator requires exactly 16 digits', () {
      expect(Validate.cardNumber('4111 1111 1111 1111'), isNull);
      expect(Validate.cardNumber('4111 1111 1111 111'), isNotNull);
      expect(Validate.cardNumber(''), isNull); // optional
    });
  });

  group('CVV and PIN', () {
    test('CVV is 3 or 4 digits', () {
      expect(Validate.cvv('123'), isNull);
      expect(Validate.cvv('1234'), isNull);
      expect(Validate.cvv('12'), isNotNull);
      expect(Validate.cvv('12a'), isNotNull);
      expect(Validate.cvv(''), isNull);
    });
    test('PIN is 4 to 6 digits', () {
      expect(Validate.pin('1234'), isNull);
      expect(Validate.pin('123456'), isNull);
      expect(Validate.pin('123'), isNotNull);
      expect(Validate.pin('1234567'), isNotNull);
    });
  });

  test('CVV, PIN and extra details survive a save/load round trip', () {
    final c = CardItem(bank: 'Bank of India', cvv: '321', pin: '4455', extras: [
      CardExtra(label: 'CRN', value: '99887766'),
      CardExtra(label: 'Net-banking user ID', value: 'user1', secret: true),
    ]);
    final back = CardItem.fromMap(c.toMap());
    expect(back.cvv, '321');
    expect(back.pin, '4455');
    expect(back.extras.map((e) => e.label), ['CRN', 'Net-banking user ID']);
    expect(back.extras.last.secret, isTrue);
  });

  test('older records without the new fields still load', () {
    final back = CardItem.fromMap({'id': 'x', 'bank': 'HDFC Bank'});
    expect(back.cvv, '');
    expect(back.pin, '');
    expect(back.extras, isEmpty);
  });

  test('Bank of India is listed with its own card styles', () {
    expect(kBanks, contains('Bank of India'));
    expect(themesForBank('Bank of India').first.bank, 'Bank of India');
  });

  test('expiry helpers', () {
    final now = DateTime.now();
    final soon = DateTime(now.year, now.month + 1);
    final c = CardItem(expMonth: soon.month, expYear: soon.year);
    expect(c.expiringSoon, isTrue);
    expect(c.isExpired, isFalse);
    final far = CardItem(expMonth: 1, expYear: now.year + 4);
    expect(far.expiringSoon, isFalse);
  });
}
