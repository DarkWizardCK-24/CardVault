import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/models/models.dart';
import 'package:cardvault/core/data/store.dart';

class Settings {
  int autoLockSeconds;
  bool biometrics, maskNumbers, hideExpiryOnDeck, notificationsOn;
  List<int> remindDays; // days before an event
  int remindHour;
  String frequency; // once | daily-until
  String? lastBackup; // ISO timestamp of the last exported backup
  Settings({this.autoLockSeconds = 60, this.biometrics = false, this.maskNumbers = true,
      this.hideExpiryOnDeck = false, this.notificationsOn = true, List<int>? remindDays, this.remindHour = 9,
      this.frequency = 'once', this.lastBackup})
      : remindDays = remindDays ?? [7, 1];
  Map<String, dynamic> toMap() => {'id': 'main', 'autoLockSeconds': autoLockSeconds, 'biometrics': biometrics,
        'maskNumbers': maskNumbers, 'hideExpiryOnDeck': hideExpiryOnDeck, 'notificationsOn': notificationsOn,
        'remindDays': remindDays, 'remindHour': remindHour, 'frequency': frequency, 'lastBackup': lastBackup};
  factory Settings.fromMap(Map<String, dynamic> m) => Settings(
      autoLockSeconds: m['autoLockSeconds'] ?? 60, biometrics: m['biometrics'] ?? false,
      maskNumbers: m['maskNumbers'] ?? true, hideExpiryOnDeck: m['hideExpiryOnDeck'] ?? false,
      notificationsOn: m['notificationsOn'] ?? true, remindDays: List<int>.from(m['remindDays'] ?? [7, 1]),
      remindHour: m['remindHour'] ?? 9, frequency: m['frequency'] ?? 'once', lastBackup: m['lastBackup']);
}

class VaultData {
  final bool loaded;
  final List<CardItem> cards;
  final List<Collection> collections;
  final List<Benefit> benefits;
  final List<Txn> txns;
  final List<Payment> payments;
  final List<Subscription> subs;
  final List<Loan> loans;
  final List<Goal> goals;
  final List<DocItem> docs;
  final List<Contact> contacts;
  final List<Activity> activity;
  final Settings settings;
  const VaultData({this.loaded = false, this.cards = const [], this.collections = const [], this.benefits = const [],
      this.txns = const [], this.payments = const [], this.subs = const [], this.loans = const [],
      this.goals = const [], this.docs = const [], this.contacts = const [], this.activity = const [],
      required this.settings});

  CardItem? card(String id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  Iterable<CardItem> get liveCards => cards.where((c) => c.status != CardStatus.archived);
  Iterable<CardItem> get creditCards => liveCards.where((c) => c.kind == CardKind.credit);

  // ---- Aggregates (all computed locally from user-entered figures) ----
  double get totalLimit => creditCards.where((c) => c.isLive).fold(0.0, (a, c) => a + c.creditLimit);
  double get totalOutstanding => creditCards.fold(0.0, (a, c) => a + c.outstanding);
  double get totalAvailable => creditCards.where((c) => c.isLive).fold(0.0, (a, c) => a + c.available);
  double get utilization => totalLimit <= 0 ? 0 : totalOutstanding / totalLimit * 100;
  double get annualFees => liveCards.fold(0.0, (a, c) => a + c.annualFee);
  double get rewardPoints => liveCards.fold(0.0, (a, c) => a + c.rewardPoints);
  int get activeDebit => liveCards.where((c) => c.kind == CardKind.debit && c.isLive).length;
  int get activeCredit => liveCards.where((c) => c.kind == CardKind.credit && c.isLive).length;
  double get monthlyLoanEmi => loans.where((l) => l.outstanding > 0).fold(0.0, (a, l) => a + l.emi);
  double get monthlySubs => subs.where((s) => s.active).fold(0.0, (a, s) => a + s.monthly);
}

class CalEvent {
  final DateTime date;
  final String title, subtitle, type; // type: expiry|billing|due|fee|benefit|sub|emi|renewal
  final String cardId;
  const CalEvent(this.date, this.title, this.subtitle, this.type, [this.cardId = '']);
}

/// Builds every dated event for calendar, dashboard and notifications.
List<CalEvent> buildEvents(VaultData d, {int monthsAhead = 14}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month + monthsAhead, now.day);
  final out = <CalEvent>[];
  DateTime? monthly(int day, int offset) {
    if (day <= 0) return null;
    final base = DateTime(today.year, today.month + offset, 1);
    final last = DateTime(base.year, base.month + 1, 0).day;
    return DateTime(base.year, base.month, day.clamp(1, last));
  }

  for (final c in d.liveCards) {
    if (c.status == CardStatus.replaced) continue;
    out.add(CalEvent(c.expiryDate, '${c.title} expires', 'Card expiry · •••• ${c.last4}', 'expiry', c.id));
    if (c.annualFeeDate != null) {
      var f = c.annualFeeDate!;
      while (f.isBefore(today)) {
        f = DateTime(f.year + 1, f.month, f.day);
      }
      out.add(CalEvent(f, '${c.title} annual fee', 'Fee ₹${c.annualFee.toStringAsFixed(0)}', 'fee', c.id));
    }
    for (var o = 0; o < monthsAhead; o++) {
      final b = monthly(c.billingDay, o);
      if (b != null && !b.isBefore(today)) out.add(CalEvent(b, '${c.title} statement', 'Billing date', 'billing', c.id));
      final du = monthly(c.dueDay, o);
      if (du != null && !du.isBefore(today)) {
        out.add(CalEvent(du, '${c.title} payment due', c.outstanding > 0 ? 'Outstanding ₹${c.outstanding.toStringAsFixed(0)}' : 'Payment due date', 'due', c.id));
      }
    }
  }
  for (final b in d.benefits) {
    if (b.validUntil != null) out.add(CalEvent(b.validUntil!, '${b.title} ends', 'Benefit expiry', 'benefit', b.cardId));
    if (b.reminder != null) out.add(CalEvent(b.reminder!, b.title, 'Benefit reminder', 'renewal', b.cardId));
  }
  for (final s in d.subs.where((s) => s.active)) {
    var r = s.renewal;
    var guard = 0;
    while (r.isBefore(today) && guard++ < 600) {
      r = s.yearly ? DateTime(r.year + 1, r.month, r.day) : DateTime(r.year, r.month + 1, r.day);
    }
    while (!r.isAfter(end) && guard++ < 1200) {
      out.add(CalEvent(r, '${s.name} renews', '₹${s.amount.toStringAsFixed(0)} · ${s.yearly ? 'yearly' : 'monthly'}', 'sub', s.cardId));
      r = s.yearly ? DateTime(r.year + 1, r.month, r.day) : DateTime(r.year, r.month + 1, r.day);
    }
  }
  for (final l in d.loans.where((l) => l.outstanding > 0)) {
    for (var o = 0; o < monthsAhead; o++) {
      final m = monthly(l.start.day, o);
      if (m != null && !m.isBefore(today) && !m.isAfter(l.end)) {
        out.add(CalEvent(m, '${l.name} EMI', '₹${l.emi.toStringAsFixed(0)} · ${l.lender}', 'emi'));
      }
    }
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

final storeProvider = Provider<RecordStore>((ref) => createStore());

final dataProvider = NotifierProvider<DataNotifier, VaultData>(DataNotifier.new);

class DataNotifier extends Notifier<VaultData> {
  RecordStore get _s => ref.read(storeProvider);

  @override
  VaultData build() => VaultData(settings: Settings());

  Future<void> load() async {
    final all = await _s.loadAll();
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) => (all[k] ?? []).map(f).toList();
    final cards = l('card', CardItem.fromMap)..sort((a, b) => a.order.compareTo(b.order));
    final act = l('activity', Activity.fromMap)..sort((a, b) => b.at.compareTo(a.at));
    final st = (all['settings'] ?? []).isEmpty ? Settings() : Settings.fromMap(all['settings']!.first);
    state = VaultData(
      loaded: true, cards: cards, collections: l('collection', Collection.fromMap),
      benefits: l('benefit', Benefit.fromMap), txns: l('txn', Txn.fromMap)..sort((a, b) => b.date.compareTo(a.date)),
      payments: l('payment', Payment.fromMap)..sort((a, b) => b.date.compareTo(a.date)),
      subs: l('sub', Subscription.fromMap), loans: l('loan', Loan.fromMap), goals: l('goal', Goal.fromMap),
      docs: l('doc', DocItem.fromMap), contacts: l('contact', Contact.fromMap), activity: act, settings: st,
    );
  }

  void clear() => state = VaultData(settings: Settings());

  VaultData _copy({List<CardItem>? cards, List<Collection>? collections, List<Benefit>? benefits, List<Txn>? txns,
          List<Payment>? payments, List<Subscription>? subs, List<Loan>? loans, List<Goal>? goals,
          List<DocItem>? docs, List<Contact>? contacts, List<Activity>? activity, Settings? settings}) =>
      VaultData(loaded: true, cards: cards ?? state.cards, collections: collections ?? state.collections,
          benefits: benefits ?? state.benefits, txns: txns ?? state.txns, payments: payments ?? state.payments,
          subs: subs ?? state.subs, loans: loans ?? state.loans, goals: goals ?? state.goals,
          docs: docs ?? state.docs, contacts: contacts ?? state.contacts, activity: activity ?? state.activity,
          settings: settings ?? state.settings);

  List<T> _upsert<T extends Entity>(List<T> l, T e) {
    final i = l.indexWhere((x) => x.id == e.id);
    return i < 0 ? [...l, e] : ([...l]..[i] = e);
  }

  Future<void> log(String text, [String icon = 'dot']) async {
    final a = Activity(text: text, icon: icon);
    await _s.put('activity', a.id, a.toMap());
    state = _copy(activity: [a, ...state.activity].take(200).toList());
  }

  // ---- Cards ----
  Future<void> saveCard(CardItem c, {bool isNew = false}) async {
    if (isNew) c.order = state.cards.length;
    await _s.put('card', c.id, c.toMap());
    state = _copy(cards: _upsert(state.cards, c));
    await log(isNew ? 'Added card ${c.title}' : 'Updated card ${c.title}', 'card');
  }

  Future<void> deleteCard(String id) async {
    final c = state.card(id);
    await _s.remove('card', id);
    for (final b in state.benefits.where((b) => b.cardId == id).toList()) {
      await _s.remove('benefit', b.id);
    }
    for (final col in state.collections) {
      if (col.cardIds.remove(id)) await _s.put('collection', col.id, col.toMap());
    }
    state = _copy(cards: state.cards.where((x) => x.id != id).toList(),
        benefits: state.benefits.where((b) => b.cardId != id).toList(), collections: [...state.collections]);
    if (c != null) await log('Deleted card ${c.title}', 'trash');
  }

  Future<void> reorderCards(List<CardItem> ordered, {String? collectionId}) async {
    if (collectionId != null) {
      final col = state.collections.firstWhere((c) => c.id == collectionId);
      col.cardIds = ordered.map((c) => c.id).toList();
      await saveCollection(col, silent: true);
      return;
    }
    // reorder only the visible subset, keeping relative slots of the rest
    final slots = ordered.map((c) => state.cards.indexOf(c)).toList()..sort();
    final all = [...state.cards];
    for (var i = 0; i < ordered.length; i++) {
      all[slots[i]] = ordered[i];
    }
    for (var i = 0; i < all.length; i++) {
      all[i].order = i;
      await _s.put('card', all[i].id, all[i].toMap());
    }
    state = _copy(cards: all);
  }

  // ---- Collections ----
  Future<void> saveCollection(Collection c, {bool silent = false}) async {
    final isNew = !state.collections.any((x) => x.id == c.id);
    await _s.put('collection', c.id, c.toMap());
    state = _copy(collections: _upsert(state.collections, c));
    if (!silent) await log('${isNew ? 'Created' : 'Updated'} collection ${c.name}', 'folder');
  }

  Future<void> deleteCollection(String id) async {
    await _s.remove('collection', id);
    state = _copy(collections: state.collections.where((c) => c.id != id).toList());
  }

  // ---- Generic entity helpers ----
  Future<void> saveBenefit(Benefit b) async {
    await _s.put('benefit', b.id, b.toMap());
    state = _copy(benefits: _upsert(state.benefits, b));
  }

  Future<void> deleteBenefit(String id) async {
    await _s.remove('benefit', id);
    state = _copy(benefits: state.benefits.where((x) => x.id != id).toList());
  }

  Future<void> saveTxn(Txn t) async {
    final isNew = !state.txns.any((x) => x.id == t.id);
    await _s.put('txn', t.id, t.toMap());
    final l = _upsert(state.txns, t)..sort((a, b) => b.date.compareTo(a.date));
    state = _copy(txns: l);
    if (isNew) await log('Recorded ₹${t.amount.toStringAsFixed(0)} at ${t.merchant}', 'receipt');
  }

  Future<void> deleteTxn(String id) async {
    await _s.remove('txn', id);
    state = _copy(txns: state.txns.where((x) => x.id != id).toList());
  }

  Future<void> savePayment(Payment p) async {
    await _s.put('payment', p.id, p.toMap());
    final l = _upsert(state.payments, p)..sort((a, b) => b.date.compareTo(a.date));
    state = _copy(payments: l);
    // Paying reduces tracked outstanding on the card.
    final c = state.card(p.cardId);
    if (c != null && p.amount > 0) {
      c.outstanding = (c.outstanding - p.amount).clamp(0, double.infinity);
      await saveCard(c);
    }
    await log('Payment ₹${p.amount.toStringAsFixed(0)} recorded', 'pay');
  }

  Future<void> deletePayment(String id) async {
    await _s.remove('payment', id);
    state = _copy(payments: state.payments.where((x) => x.id != id).toList());
  }

  Future<void> saveSub(Subscription s) async {
    await _s.put('sub', s.id, s.toMap());
    state = _copy(subs: _upsert(state.subs, s));
  }

  Future<void> deleteSub(String id) async {
    await _s.remove('sub', id);
    state = _copy(subs: state.subs.where((x) => x.id != id).toList());
  }

  Future<void> saveLoan(Loan l) async {
    await _s.put('loan', l.id, l.toMap());
    state = _copy(loans: _upsert(state.loans, l));
  }

  Future<void> deleteLoan(String id) async {
    await _s.remove('loan', id);
    state = _copy(loans: state.loans.where((x) => x.id != id).toList());
  }

  Future<void> saveGoal(Goal g) async {
    await _s.put('goal', g.id, g.toMap());
    state = _copy(goals: _upsert(state.goals, g));
  }

  Future<void> deleteGoal(String id) async {
    await _s.remove('goal', id);
    state = _copy(goals: state.goals.where((x) => x.id != id).toList());
  }

  Future<void> saveDoc(DocItem d) async {
    await _s.put('doc', d.id, d.toMap());
    state = _copy(docs: _upsert(state.docs, d));
  }

  Future<void> deleteDoc(String id) async {
    await _s.remove('doc', id);
    state = _copy(docs: state.docs.where((x) => x.id != id).toList());
  }

  Future<void> saveContact(Contact c) async {
    await _s.put('contact', c.id, c.toMap());
    state = _copy(contacts: _upsert(state.contacts, c));
  }

  Future<void> deleteContact(String id) async {
    await _s.remove('contact', id);
    state = _copy(contacts: state.contacts.where((x) => x.id != id).toList());
  }

  Future<void> saveSettings(Settings s) async {
    await _s.put('settings', 'main', s.toMap());
    state = _copy(settings: s);
  }

  /// Raw export/import for encrypted backups.
  Map<String, dynamic> exportAll() => {
        'version': 1,
        'cards': state.cards.map((e) => e.toMap()).toList(),
        'collections': state.collections.map((e) => e.toMap()).toList(),
        'benefits': state.benefits.map((e) => e.toMap()).toList(),
        'txns': state.txns.map((e) => e.toMap()).toList(),
        'payments': state.payments.map((e) => e.toMap()).toList(),
        'subs': state.subs.map((e) => e.toMap()).toList(),
        'loans': state.loans.map((e) => e.toMap()).toList(),
        'goals': state.goals.map((e) => e.toMap()).toList(),
        'docs': state.docs.map((e) => e.toMap()).toList(),
        'contacts': state.contacts.map((e) => e.toMap()).toList(),
        'settings': state.settings.toMap(),
      };

  Future<void> importAll(Map<String, dynamic> m) async {
    await _s.wipe();
    Future<void> put(String key, String kind) async {
      for (final e in (m[key] as List? ?? [])) {
        await _s.put(kind, e['id'], Map<String, dynamic>.from(e));
      }
    }

    await put('cards', 'card');
    await put('collections', 'collection');
    await put('benefits', 'benefit');
    await put('txns', 'txn');
    await put('payments', 'payment');
    await put('subs', 'sub');
    await put('loans', 'loan');
    await put('goals', 'goal');
    await put('docs', 'doc');
    await put('contacts', 'contact');
    if (m['settings'] != null) await _s.put('settings', 'main', Map<String, dynamic>.from(m['settings']));
    await load();
    await log('Backup restored', 'backup');
  }

  Future<void> wipeAll() async {
    await _s.wipe();
    state = VaultData(loaded: true, settings: Settings());
  }
}
