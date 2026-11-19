import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final active = d.subs.where((s) => s.active).toList();
    return Screen(title: 'Subscriptions', subtitle: 'Recurring payments', actions: [IconPill(Icons.add_rounded, () => subForm(context, ref))], children: [
      Row(children: [
        Expanded(child: StatTile('Monthly', money(d.monthlySubs), Icons.calendar_view_month_rounded)), const SizedBox(width: 12),
        Expanded(child: StatTile('Yearly', compactMoney(active.fold(0.0, (a, s) => a + s.annual)), Icons.event_repeat_rounded)),
      ]).rise(),
      const SectionHeader('All subscriptions'),
      if (d.subs.isEmpty) EmptyState(icon: Icons.autorenew_rounded, title: 'No subscriptions', message: 'Track OTT, cloud and other recurring charges with renewal reminders.', action: 'Add subscription', onAction: () => subForm(context, ref)),
      for (final (i, s) in d.subs.indexed)
        ListRow(
          leading: IconBadge(Icons.autorenew_rounded, color: s.active ? C.gold : C.muted), title: s.name,
          subtitle: '${s.category} · ${d.card(s.cardId)?.title ?? 'No card'} · renews ${dDay(s.renewal)}',
          trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(s.amount), style: T.num(15)), Tag(s.active ? (s.yearly ? 'Yearly' : 'Monthly') : 'Cancelled', color: s.active ? C.silver : C.muted)]),
          onTap: () => subForm(context, ref, edit: s),
        ).rise(i.clamp(0, 6)),
    ]);
  }
}

