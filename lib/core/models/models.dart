// Data models. NOTE: by design there is NO field for CVV, ATM PIN, OTP or
// banking passwords anywhere in this app.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

DateTime? _d(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
double _n(dynamic v) => (v as num?)?.toDouble() ?? 0;

enum CardKind { debit, credit }

enum CardStatus { active, blocked, expired, replaced, archived }

abstract class Entity {
  String get id;
  Map<String, dynamic> toMap();
}

class CardItem implements Entity {
  @override
  final String id;
  String bank, holder, nickname, network, product, themeId;
  CardKind kind;
  String number; // full PAN – encrypted at rest (SQLCipher), masked in UI
  String last4;
  int expMonth, expYear;
  DateTime? issueDate;
  double creditLimit, outstanding, annualFee, joiningFee, rewardPoints, forexMarkup;
  int billingDay, dueDay; // day of month, 0 = unset
  DateTime? annualFeeDate;
  String support, notes;
  CardStatus status;
  bool favourite, travel, daily, showExpiry;
  int order;
  int? customColorA, customColorB; // custom theme
  List<String> collectionIds;

  CardItem({
    String? id,
    this.bank = '',
    this.holder = '',
    this.nickname = '',
    this.network = 'Visa',
    this.product = '',
    this.themeId = 'custom',
    this.kind = CardKind.credit,
    this.number = '',
    this.last4 = '',
    this.expMonth = 1,
    this.expYear = 2030,
    this.issueDate,
    this.creditLimit = 0,
    this.outstanding = 0,
    this.annualFee = 0,
    this.joiningFee = 0,
    this.rewardPoints = 0,
    this.forexMarkup = 0,
    this.billingDay = 0,
    this.dueDay = 0,
    this.annualFeeDate,
    this.support = '',
    this.notes = '',
    this.status = CardStatus.active,
    this.favourite = false,
    this.travel = false,
    this.daily = false,
    this.showExpiry = true,
    this.order = 0,
    this.customColorA,
    this.customColorB,
    List<String>? collectionIds,
  })  : id = id ?? newId(),
        collectionIds = collectionIds ?? [];

  double get available => (creditLimit - outstanding).clamp(0, double.infinity);
  double get utilization => creditLimit <= 0 ? 0 : (outstanding / creditLimit * 100);
  String get title => nickname.isNotEmpty ? nickname : '$bank $product'.trim();
  DateTime get expiryDate => DateTime(expYear, expMonth + 1, 0);
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isLive => status == CardStatus.active && !isExpired;

  @override
  Map<String, dynamic> toMap() => {
        'id': id, 'bank': bank, 'holder': holder, 'nickname': nickname, 'network': network,
        'product': product, 'themeId': themeId, 'kind': kind.name, 'number': number,
        'last4': last4, 'expMonth': expMonth, 'expYear': expYear,
        'issueDate': issueDate?.toIso8601String(), 'creditLimit': creditLimit,
        'outstanding': outstanding, 'annualFee': annualFee, 'joiningFee': joiningFee,
        'rewardPoints': rewardPoints, 'forexMarkup': forexMarkup, 'billingDay': billingDay,
        'dueDay': dueDay, 'annualFeeDate': annualFeeDate?.toIso8601String(), 'support': support,
        'notes': notes, 'status': status.name, 'favourite': favourite, 'travel': travel,
        'daily': daily, 'showExpiry': showExpiry, 'order': order,
        'customColorA': customColorA, 'customColorB': customColorB,
        'collectionIds': collectionIds,
      };

  factory CardItem.fromMap(Map<String, dynamic> m) => CardItem(
        id: m['id'], bank: m['bank'] ?? '', holder: m['holder'] ?? '', nickname: m['nickname'] ?? '',
        network: m['network'] ?? 'Visa', product: m['product'] ?? '', themeId: m['themeId'] ?? 'custom',
        kind: CardKind.values.byName(m['kind'] ?? 'credit'), number: m['number'] ?? '',
        last4: m['last4'] ?? '', expMonth: m['expMonth'] ?? 1, expYear: m['expYear'] ?? 2030,
        issueDate: _d(m['issueDate']), creditLimit: _n(m['creditLimit']), outstanding: _n(m['outstanding']),
        annualFee: _n(m['annualFee']), joiningFee: _n(m['joiningFee']), rewardPoints: _n(m['rewardPoints']),
        forexMarkup: _n(m['forexMarkup']), billingDay: m['billingDay'] ?? 0, dueDay: m['dueDay'] ?? 0,
        annualFeeDate: _d(m['annualFeeDate']), support: m['support'] ?? '', notes: m['notes'] ?? '',
        status: CardStatus.values.byName(m['status'] ?? 'active'), favourite: m['favourite'] ?? false,
        travel: m['travel'] ?? false, daily: m['daily'] ?? false, showExpiry: m['showExpiry'] ?? true,
        order: m['order'] ?? 0, customColorA: m['customColorA'], customColorB: m['customColorB'],
        collectionIds: List<String>.from(m['collectionIds'] ?? const []),
      );
}

class Collection implements Entity {
  @override
  final String id;
  String name, description, notes, icon;
  int colorA, colorB;
  bool favourite;
  List<String> cardIds; // ordered
  Collection({String? id, this.name = '', this.description = '', this.notes = '', this.icon = 'star',
      this.colorA = 0xFFD6B779, this.colorB = 0xFF3A2F1A, this.favourite = false, List<String>? cardIds})
      : id = id ?? newId(),
        cardIds = cardIds ?? [];
  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'description': description, 'notes': notes,
        'icon': icon, 'colorA': colorA, 'colorB': colorB, 'favourite': favourite, 'cardIds': cardIds};
  factory Collection.fromMap(Map<String, dynamic> m) => Collection(
      id: m['id'], name: m['name'] ?? '', description: m['description'] ?? '', notes: m['notes'] ?? '',
      icon: m['icon'] ?? 'star', colorA: m['colorA'] ?? 0xFFD6B779, colorB: m['colorB'] ?? 0xFF3A2F1A,
      favourite: m['favourite'] ?? false, cardIds: List<String>.from(m['cardIds'] ?? const []));
}

class Benefit implements Entity {
  @override
  final String id;
  String title, category, description, cardId, terms, notes;
  DateTime? validUntil, reminder;
  int usageLimit, remaining;
  Benefit({String? id, this.title = '', this.category = 'Other', this.description = '', this.cardId = '',
      this.terms = '', this.notes = '', this.validUntil, this.reminder, this.usageLimit = 0, this.remaining = 0})
      : id = id ?? newId();
  bool get expired => validUntil != null && validUntil!.isBefore(DateTime.now());
  @override
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'category': category, 'description': description,
        'cardId': cardId, 'terms': terms, 'notes': notes, 'validUntil': validUntil?.toIso8601String(),
        'reminder': reminder?.toIso8601String(), 'usageLimit': usageLimit, 'remaining': remaining};
  factory Benefit.fromMap(Map<String, dynamic> m) => Benefit(
      id: m['id'], title: m['title'] ?? '', category: m['category'] ?? 'Other', description: m['description'] ?? '',
      cardId: m['cardId'] ?? '', terms: m['terms'] ?? '', notes: m['notes'] ?? '', validUntil: _d(m['validUntil']),
      reminder: _d(m['reminder']), usageLimit: m['usageLimit'] ?? 0, remaining: m['remaining'] ?? 0);
}

class Txn implements Entity {
  @override
  final String id;
  String merchant, category, cardId, notes;
  double amount;
  DateTime date;
  bool paid;
  bool isRefund;
  Txn({String? id, this.merchant = '', this.category = 'Shopping', this.cardId = '', this.notes = '',
      this.amount = 0, DateTime? date, this.paid = false, this.isRefund = false})
      : id = id ?? newId(),
        date = date ?? DateTime.now();
  @override
  Map<String, dynamic> toMap() => {'id': id, 'merchant': merchant, 'category': category, 'cardId': cardId,
        'notes': notes, 'amount': amount, 'date': date.toIso8601String(), 'paid': paid, 'isRefund': isRefund};
  factory Txn.fromMap(Map<String, dynamic> m) => Txn(id: m['id'], merchant: m['merchant'] ?? '',
      category: m['category'] ?? 'Other', cardId: m['cardId'] ?? '', notes: m['notes'] ?? '',
      amount: _n(m['amount']), date: _d(m['date']), paid: m['paid'] ?? false, isRefund: m['isRefund'] ?? false);
}

class Payment implements Entity {
  @override
  final String id;
  String cardId, note;
  double amount, minDue, totalDue;
  DateTime date;
  Payment({String? id, this.cardId = '', this.note = '', this.amount = 0, this.minDue = 0, this.totalDue = 0, DateTime? date})
      : id = id ?? newId(),
        date = date ?? DateTime.now();
  @override
  Map<String, dynamic> toMap() => {'id': id, 'cardId': cardId, 'note': note, 'amount': amount,
        'minDue': minDue, 'totalDue': totalDue, 'date': date.toIso8601String()};
  factory Payment.fromMap(Map<String, dynamic> m) => Payment(id: m['id'], cardId: m['cardId'] ?? '',
      note: m['note'] ?? '', amount: _n(m['amount']), minDue: _n(m['minDue']), totalDue: _n(m['totalDue']), date: _d(m['date']));
}

class Subscription implements Entity {
  @override
  final String id;
  String name, cardId, category, notes;
  double amount;
  bool yearly, active;
  DateTime renewal;
  Subscription({String? id, this.name = '', this.cardId = '', this.category = 'Entertainment', this.notes = '',
      this.amount = 0, this.yearly = false, this.active = true, DateTime? renewal})
      : id = id ?? newId(),
        renewal = renewal ?? DateTime.now().add(const Duration(days: 30));
  double get monthly => yearly ? amount / 12 : amount;
  double get annual => yearly ? amount : amount * 12;
  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'cardId': cardId, 'category': category,
        'notes': notes, 'amount': amount, 'yearly': yearly, 'active': active, 'renewal': renewal.toIso8601String()};
  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(id: m['id'], name: m['name'] ?? '',
      cardId: m['cardId'] ?? '', category: m['category'] ?? 'Other', notes: m['notes'] ?? '',
      amount: _n(m['amount']), yearly: m['yearly'] ?? false, active: m['active'] ?? true, renewal: _d(m['renewal']));
}

class Loan implements Entity {
  @override
  final String id;
  String name, lender, notes;
  double principal, rate, outstanding, emi;
  DateTime start, end;
  List<Map<String, dynamic>> payments; // {date, amount}
  Loan({String? id, this.name = '', this.lender = '', this.notes = '', this.principal = 0, this.rate = 0,
      this.outstanding = 0, this.emi = 0, DateTime? start, DateTime? end, List<Map<String, dynamic>>? payments})
      : id = id ?? newId(),
        start = start ?? DateTime.now(),
        end = end ?? DateTime.now().add(const Duration(days: 365)),
        payments = payments ?? [];
  double get progress => principal <= 0 ? 0 : ((principal - outstanding) / principal).clamp(0, 1);
  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'lender': lender, 'notes': notes, 'principal': principal,
        'rate': rate, 'outstanding': outstanding, 'emi': emi, 'start': start.toIso8601String(),
        'end': end.toIso8601String(), 'payments': payments};
  factory Loan.fromMap(Map<String, dynamic> m) => Loan(id: m['id'], name: m['name'] ?? '', lender: m['lender'] ?? '',
      notes: m['notes'] ?? '', principal: _n(m['principal']), rate: _n(m['rate']), outstanding: _n(m['outstanding']),
      emi: _n(m['emi']), start: _d(m['start']), end: _d(m['end']),
      payments: List<Map<String, dynamic>>.from((m['payments'] ?? const []).map((e) => Map<String, dynamic>.from(e))));
}

class Goal implements Entity {
  @override
  final String id;
  String name, notes;
  double target, current;
  DateTime? targetDate;
  Goal({String? id, this.name = '', this.notes = '', this.target = 0, this.current = 0, this.targetDate}) : id = id ?? newId();
  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'notes': notes, 'target': target, 'current': current,
        'targetDate': targetDate?.toIso8601String()};
  factory Goal.fromMap(Map<String, dynamic> m) => Goal(id: m['id'], name: m['name'] ?? '', notes: m['notes'] ?? '',
      target: _n(m['target']), current: _n(m['current']), targetDate: _d(m['targetDate']));
}

class DocItem implements Entity {
  @override
  final String id;
  String name, type, cardId, fileName, mime, text; // text = optional extracted text
  int size;
  DateTime added;
  DocItem({String? id, this.name = '', this.type = 'Other', this.cardId = '', this.fileName = '', this.mime = '',
      this.text = '', this.size = 0, DateTime? added})
      : id = id ?? newId(),
        added = added ?? DateTime.now();
  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type, 'cardId': cardId, 'fileName': fileName,
        'mime': mime, 'text': text, 'size': size, 'added': added.toIso8601String()};
  factory DocItem.fromMap(Map<String, dynamic> m) => DocItem(id: m['id'], name: m['name'] ?? '', type: m['type'] ?? 'Other',
      cardId: m['cardId'] ?? '', fileName: m['fileName'] ?? '', mime: m['mime'] ?? '', text: m['text'] ?? '',
      size: m['size'] ?? 0, added: _d(m['added']));
}

/// Bank contact / emergency entry. Always user-entered, never "verified".
class Contact implements Entity {
  @override
  final String id;
  String bank, phone, lostCardPhone, website, instructions;
  bool personalNote;
  Contact({String? id, this.bank = '', this.phone = '', this.lostCardPhone = '', this.website = '',
      this.instructions = '', this.personalNote = false})
      : id = id ?? newId();
  @override
  Map<String, dynamic> toMap() => {'id': id, 'bank': bank, 'phone': phone, 'lostCardPhone': lostCardPhone,
        'website': website, 'instructions': instructions, 'personalNote': personalNote};
  factory Contact.fromMap(Map<String, dynamic> m) => Contact(id: m['id'], bank: m['bank'] ?? '', phone: m['phone'] ?? '',
      lostCardPhone: m['lostCardPhone'] ?? '', website: m['website'] ?? '', instructions: m['instructions'] ?? '',
      personalNote: m['personalNote'] ?? false);
}

/// Local activity log entry.
class Activity implements Entity {
  @override
  final String id;
  String text, icon;
  DateTime at;
  Activity({String? id, this.text = '', this.icon = 'dot', DateTime? at}) : id = id ?? newId(), at = at ?? DateTime.now();
  @override
  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'icon': icon, 'at': at.toIso8601String()};
  factory Activity.fromMap(Map<String, dynamic> m) =>
      Activity(id: m['id'], text: m['text'] ?? '', icon: m['icon'] ?? 'dot', at: _d(m['at']));
}
