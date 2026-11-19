import 'package:cardvault/core/models/models.dart';
import 'package:cardvault/core/data/repo.dart';

/// Illustrative sample data (fake numbers that pass no real-account lookup).
Future<void> loadDemo(DataNotifier n, VaultData d) async {
  final y = DateTime.now().year;
  final cards = [
    CardItem(bank: 'HDFC Bank', product: 'Regalia', themeId: 'hdfc_regalia', network: 'Visa', holder: 'ARJUN MEHTA', last4: '4321', number: '4111111111111111',
        expMonth: 8, expYear: y + 3, creditLimit: 450000, outstanding: 82000, annualFee: 2500, joiningFee: 2500, rewardPoints: 18450, forexMarkup: 2, billingDay: 12, dueDay: 2,
        annualFeeDate: DateTime(y + 1, 3, 15), favourite: true, travel: true, support: 'See back of card'),
    CardItem(bank: 'ICICI Bank', product: 'Amazon Pay', themeId: 'icici_amazon', network: 'Visa', holder: 'ARJUN MEHTA', last4: '8842', expMonth: 3, expYear: y + 2,
        creditLimit: 250000, outstanding: 31500, rewardPoints: 4200, billingDay: 5, dueDay: 25, daily: true, favourite: true),
    CardItem(bank: 'Axis Bank', product: 'Magnus', themeId: 'axis_magnus', network: 'Mastercard', holder: 'ARJUN MEHTA', last4: '1109', expMonth: 11, expYear: y + 4,
        creditLimit: 800000, outstanding: 142000, annualFee: 12500, joiningFee: 12500, rewardPoints: 56000, forexMarkup: 3.5, billingDay: 20, dueDay: 10, travel: true,
        annualFeeDate: DateTime(y + 1, 1, 20)),
    CardItem(bank: 'American Express', product: 'Platinum', themeId: 'amex_platinum', network: 'American Express', holder: 'ARJUN MEHTA', last4: '3005', expMonth: 6, expYear: y + 3,
        creditLimit: 600000, outstanding: 24000, annualFee: 60000, rewardPoints: 22000, billingDay: 8, dueDay: 28, travel: true),
    CardItem(bank: 'State Bank of India', product: 'Debit Classic', themeId: 'sbi_debit', network: 'RuPay', kind: CardKind.debit, holder: 'ARJUN MEHTA', last4: '7712',
        expMonth: 12, expYear: y + 2, daily: true),
    CardItem(bank: 'Kotak Mahindra Bank', product: '811 Debit', themeId: 'kotak_811', network: 'Visa', kind: CardKind.debit, holder: 'ARJUN MEHTA', last4: '5560', expMonth: 5, expYear: y + 1),
  ];
  for (final c in cards) {
    await n.saveCard(c, isNew: true);
  }
  final hdfc = cards[0].id, amazon = cards[1].id, axis = cards[2].id;
  final now = DateTime.now();
  await n.saveBenefit(Benefit(title: 'Domestic lounge visits', category: 'Airport lounge – domestic', cardId: hdfc, usageLimit: 12, remaining: 9, validUntil: DateTime(y + 1, 3, 31), terms: 'Min. spend per quarter applies (your note).'));
  await n.saveBenefit(Benefit(title: 'Amazon Prime cashback', category: 'Cashback', cardId: amazon, validUntil: now.add(const Duration(days: 20)), description: '5% on Amazon purchases'));
  await n.saveBenefit(Benefit(title: 'International lounge', category: 'Airport lounge – international', cardId: axis, usageLimit: 8, remaining: 8, validUntil: DateTime(y + 1, 11, 30)));
  await n.saveBenefit(Benefit(title: 'Fuel surcharge waiver', category: 'Fuel surcharge waiver', cardId: hdfc, validUntil: now.add(const Duration(days: 9))));
  final spends = [('Swiggy', 'Food & dining', 640.0, 1, amazon), ('Amazon', 'Shopping', 3499.0, 2, amazon), ('Indian Oil', 'Fuel', 2500.0, 3, hdfc),
    ('MakeMyTrip', 'Travel', 18400.0, 5, axis), ('BigBasket', 'Groceries', 2210.0, 7, amazon), ('Netflix', 'Entertainment', 649.0, 9, hdfc),
    ('Apollo Pharmacy', 'Health', 1180.0, 12, hdfc), ('Uber', 'Travel', 420.0, 15, amazon), ('Croma', 'Shopping', 24990.0, 40, hdfc), ('Zomato', 'Food & dining', 780.0, 44, amazon)];
  for (final s in spends) {
    await n.saveTxn(Txn(merchant: s.$1, category: s.$2, amount: s.$3, date: now.subtract(Duration(days: s.$4)), cardId: s.$5, paid: s.$4 > 30));
  }
  await n.saveSub(Subscription(name: 'Netflix', amount: 649, cardId: hdfc, renewal: now.add(const Duration(days: 6)), category: 'Entertainment'));
  await n.saveSub(Subscription(name: 'Google One', amount: 1300, yearly: true, cardId: amazon, renewal: now.add(const Duration(days: 80)), category: 'Cloud & software'));
  await n.saveLoan(Loan(name: 'Car loan', lender: 'HDFC Bank', principal: 800000, rate: 9, outstanding: 520000, emi: 16607, start: DateTime(y - 1, now.month, 8), end: DateTime(y + 3, now.month, 8)));
  await n.saveGoal(Goal(name: 'Europe trip', target: 400000, current: 145000, targetDate: DateTime(y + 1, 6, 1)));
  await n.saveCollection(Collection(name: 'Travel', description: 'Miles & lounges', icon: 'flight', colorA: 0xFF5B8DEF, colorB: 0xFF14213D, cardIds: [axis, hdfc, cards[3].id]));
  await n.saveCollection(Collection(name: 'Daily banking', icon: 'bank', cardIds: [amazon, cards[4].id, cards[5].id]));
}
