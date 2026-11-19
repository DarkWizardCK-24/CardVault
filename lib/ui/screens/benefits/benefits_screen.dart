import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});
  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  int f = 0;
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final soon = DateTime.now().add(const Duration(days: 30));
    var l = d.benefits.where((b) => switch (f) {
          1 => !b.expired && b.validUntil != null && b.validUntil!.isBefore(soon),
          2 => b.category.contains('lounge'),
          3 => b.category == 'Cashback' || b.category == 'Reward points',
          4 => b.expired,
          _ => true,
        }).toList()
      ..sort((a, b) => (a.validUntil ?? DateTime(2100)).compareTo(b.validUntil ?? DateTime(2100)));
    final expiring = d.benefits.where((b) => !b.expired && b.validUntil != null && b.validUntil!.isBefore(soon)).length;
    return Screen(
      title: 'Benefits', subtitle: 'Recorded by you · no online lookups',
      actions: [IconPill(Icons.add_rounded, () => addBenefit(context, ref), tooltip: 'Add benefit', active: true)],
      children: [
        Row(children: [
          Expanded(child: StatTile('Benefits', '${d.benefits.length}', Icons.card_giftcard_rounded)), const SizedBox(width: 12),
          Expanded(child: StatTile('Expiring in 30d', '$expiring', Icons.hourglass_bottom_rounded, color: expiring > 0 ? C.warn : C.good)),
        ]).rise(),
        const SizedBox(height: 16),
        ChipBar(items: const ['All', 'Expiring', 'Lounge', 'Rewards', 'Expired'], index: f, onChanged: (i) => setState(() => f = i)),
        const SizedBox(height: 16),
        if (l.isEmpty)
          EmptyState(icon: Icons.card_giftcard_rounded, title: 'No benefits yet', message: 'Track lounge visits, cashback, waivers and more — with usage counters and reminders.', action: 'Add benefit', onAction: () => addBenefit(context, ref))
        else
          for (final (i, b) in l.indexed) BenefitRow(b).rise(i.clamp(0, 6)),
      ],
    );
  }
}

