import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final live = d.liveCards.toList();
    Map<String, double> count(String Function(CardItem) f) {
      final m = <String, double>{};
      for (final c in live) {
        m[f(c)] = (m[f(c)] ?? 0) + 1;
      }
      return m;
    }
    final state = <String, double>{
      'Active': d.cards.where((c) => c.status == CardStatus.active && !c.isExpired).length.toDouble(),
      'Blocked': d.cards.where((c) => c.status == CardStatus.blocked).length.toDouble(),
      'Expired': d.cards.where((c) => c.isExpired || c.status == CardStatus.expired).length.toDouble(),
    };
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
    final per = [for (final m in months) d.txns.where((t) => t.date.year == m.year && t.date.month == m.month).fold(0.0, (a, t) => a + (t.isRefund ? -t.amount : t.amount))];
    final cat = <String, double>{};
    for (final t in d.txns.where((t) => !t.isRefund && t.date.isAfter(now.subtract(const Duration(days: 30))))) {
      cat[t.category] = (cat[t.category] ?? 0) + t.amount;
    }
    final soon = now.add(const Duration(days: 30));
    final expiringBenefits = d.benefits.where((b) => !b.expired && b.validUntil != null && b.validUntil!.isBefore(soon)).toList();
    final upcoming = buildEvents(d, monthsAhead: 2).where((e) => e.type == 'due' && e.date.isBefore(soon)).length;
    final mLabels = [for (final m in months) ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][m.month - 1]];
    return Screen(title: 'Insights', subtitle: 'Calculated from local records', children: [
      StatGrid(
        children: [
          StatTile('Total cards', '${live.length}', Icons.credit_card_rounded), StatTile('Total limits', compactMoney(d.totalLimit), Icons.speed_rounded),
          StatTile('Outstanding', compactMoney(d.totalOutstanding), Icons.account_balance_wallet_outlined, color: C.warn), StatTile('Available credit', compactMoney(d.totalAvailable), Icons.savings_outlined, color: C.good),
          StatTile('Annual fees', compactMoney(d.annualFees), Icons.receipt_long_outlined), StatTile('Reward points', d.rewardPoints.toStringAsFixed(0), Icons.stars_rounded),
          StatTile('Dues in 30 days', '$upcoming', Icons.event_available_outlined), StatTile('Benefits expiring', '${expiringBenefits.length}', Icons.hourglass_bottom_rounded, color: expiringBenefits.isEmpty ? C.good : C.warn),
        ].indexed.map((e) => e.$2.rise(e.$1)).toList(),
      ),
      const SectionHeader('Cards by bank'),
      Glass(child: Donut(count((c) => c.bank.isEmpty ? 'Other' : c.bank), center: '${live.length}\ncards')).rise(),
      const SectionHeader('Cards by network'),
      Glass(child: Donut(count((c) => c.network))).rise(),
      const SectionHeader('Debit vs credit'),
      Glass(child: Donut(count((c) => c.kind == CardKind.credit ? 'Credit' : 'Debit'))).rise(),
      const SectionHeader('Card status'),
      Glass(child: Donut(state)).rise(),
      const SectionHeader('Monthly spending'),
      Glass(child: Bars(mLabels, per.map((e) => e < 0 ? 0.0 : e).toList())).rise(),
      const SectionHeader('Category distribution · 30 days'),
      Glass(child: Donut(cat)).rise(),
      if (expiringBenefits.isNotEmpty) ...[
        const SectionHeader('Benefits expiring soon'),
        for (final b in expiringBenefits) ListRow(leading: const IconBadge(Icons.hourglass_bottom_rounded, color: C.warn), title: b.title, subtitle: 'Until ${dShort(b.validUntil!)}'),
      ],
    ]);
  }
}

