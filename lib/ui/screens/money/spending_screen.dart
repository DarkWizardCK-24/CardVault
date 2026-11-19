import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= spending analytics
class SpendingScreen extends ConsumerWidget {
  const SpendingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
    double sum(Iterable<Txn> l) => l.fold(0.0, (a, t) => a + (t.isRefund ? -t.amount : t.amount));
    final per = [for (final m in months) sum(d.txns.where((t) => t.date.year == m.year && t.date.month == m.month))];
    final thisMonth = d.txns.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    final cat = <String, double>{};
    for (final t in thisMonth.where((t) => !t.isRefund)) {
      cat[t.category] = (cat[t.category] ?? 0) + t.amount;
    }
    final byCard = <String, double>{};
    for (final t in thisMonth) {
      final n = d.card(t.cardId)?.title ?? 'Unknown';
      byCard[n] = (byCard[n] ?? 0) + t.amount;
    }
    final kind = <String, double>{'Credit': 0, 'Debit': 0};
    for (final t in thisMonth) {
      final c = d.card(t.cardId);
      if (c != null) kind[c.kind == CardKind.credit ? 'Credit' : 'Debit'] = kind[c.kind == CardKind.credit ? 'Credit' : 'Debit']! + t.amount;
    }
    final year = sum(d.txns.where((t) => t.date.year == now.year));
    // outstanding trend: cumulative unpaid per month
    var run = 0.0;
    final trend = [for (final m in months) run += sum(d.txns.where((t) => !t.paid && t.date.year == m.year && t.date.month == m.month))];
    final labels = [for (final m in months) ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][m.month - 1]];
    return Screen(title: 'Spending', subtitle: 'Calculated from your records', children: [
      Row(children: [
        Expanded(child: StatTile('This month', compactMoney(sum(thisMonth)), Icons.calendar_today_rounded)), const SizedBox(width: 12),
        Expanded(child: StatTile('${now.year} total', compactMoney(year), Icons.stacked_bar_chart_rounded)),
      ]).rise(),
      const SectionHeader('Monthly expenses'),
      Glass(child: Bars(labels, per.map((e) => e < 0 ? 0.0 : e).toList())).rise(1),
      const SectionHeader('Category-wise · this month'),
      Glass(child: Donut(cat, center: compactMoney(cat.values.fold(0.0, (a, b) => a + b)))).rise(2),
      const SectionHeader('Card-wise · this month'),
      Glass(child: Donut(byCard)).rise(3),
      const SectionHeader('Credit vs debit'),
      Glass(child: Donut(kind)).rise(4),
      const SectionHeader('Unpaid balance trend'),
      Glass(child: LineTrend(labels, trend)).rise(5),
    ]);
  }
}

