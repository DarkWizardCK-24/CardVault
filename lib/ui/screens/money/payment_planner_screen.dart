import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class PaymentPlannerScreen extends ConsumerWidget {
  const PaymentPlannerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final ev = buildEvents(d, monthsAhead: 2).where((e) => e.type == 'due' || e.type == 'billing' || e.type == 'emi').toList();
    final now = DateTime.now();
    final monthDue = ev.where((e) => e.type == 'due' && e.date.month == now.month).length;
    final monthPaid = d.payments.where((p) => p.date.year == now.year && p.date.month == now.month).fold(0.0, (a, p) => a + p.amount);
    return Screen(
      title: 'Payment Planner', subtitle: 'Dues & statements you entered',
      actions: [IconPill(Icons.add_rounded, () => addPayment(context, ref))],
      children: [
        Row(children: [
          Expanded(child: StatTile('Outstanding', compactMoney(d.totalOutstanding), Icons.account_balance_wallet_outlined, color: C.warn)), const SizedBox(width: 12),
          Expanded(child: StatTile('Paid this month', compactMoney(monthPaid), Icons.check_circle_outline, color: C.good)),
        ]).rise(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: StatTile('Dues this month', '$monthDue', Icons.event_available_outlined)), const SizedBox(width: 12),
          Expanded(child: StatTile('Monthly EMI', compactMoney(d.monthlyLoanEmi), Icons.event_repeat_rounded)),
        ]).rise(1),
        const SectionHeader('Upcoming'),
        if (ev.isEmpty) const EmptyState(icon: Icons.event_available_outlined, title: 'Nothing scheduled', message: 'Set billing and due days on a credit card to see them here.'),
        for (final (i, e) in ev.take(14).indexed)
          ListRow(
            leading: IconBadge(e.type == 'due' ? Icons.payments_outlined : (e.type == 'emi' ? Icons.event_repeat_rounded : Icons.receipt_outlined), color: e.type == 'due' ? C.warn : C.silver),
            title: e.title, subtitle: '${e.subtitle} · ${dShort(e.date)}', trailing: Text(relDays(e.date), style: T.caption.copyWith(color: C.gold)),
            onTap: e.type == 'due' && e.cardId.isNotEmpty ? () => addPayment(context, ref, e.cardId) : null,
          ).rise(i.clamp(0, 6)),
        const SectionHeader('Payment history'),
        if (d.payments.isEmpty) Text('No payments recorded yet.', style: T.muted),
        for (final p in d.payments.take(20))
          ListRow(
            leading: const IconBadge(Icons.check_circle_outline, color: C.good), title: d.card(p.cardId)?.title ?? 'Card',
            subtitle: '${dShort(p.date)}${p.note.isEmpty ? '' : ' · ${p.note}'}',
            trailing: Text(money(p.amount), style: T.num(15, c: C.good)),
            onLongPress: () async {
              if (await confirm(context, 'Delete payment record?', 'The card’s outstanding amount will not change.', action: 'Delete', danger: true)) ref.read(dataProvider.notifier).deletePayment(p.id);
            },
          ),
      ],
    );
  }
}

