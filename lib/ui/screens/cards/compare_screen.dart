import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Side-by-side comparison of the user's OWN cards. Never recommends or ranks.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});
  @override
  ConsumerState<CompareScreen> createState() => _CompareState();
}

class _CompareState extends ConsumerState<CompareScreen> {
  final picked = <String>[];
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final cards = [for (final id in picked) if (d.card(id) != null) d.card(id)!];
    String ben(CardItem c, bool Function(Benefit) t) {
      final l = d.benefits.where((b) => b.cardId == c.id && t(b)).toList();
      return l.isEmpty ? '—' : l.map((b) => b.title).join(', ');
    }
    final rows = <(String, String Function(CardItem))>[
      ('Annual fee', (c) => money(c.annualFee)), ('Joining fee', (c) => money(c.joiningFee)),
      ('Credit limit', (c) => c.creditLimit == 0 ? '—' : money(c.creditLimit)), ('Reward points', (c) => c.rewardPoints.toStringAsFixed(0)),
      ('Forex markup', (c) => c.forexMarkup == 0 ? '—' : '${c.forexMarkup}%'),
      ('Cashback', (c) => ben(c, (b) => b.category == 'Cashback')),
      ('Lounge access', (c) => ben(c, (b) => b.category.contains('lounge'))),
      ('Fuel benefits', (c) => ben(c, (b) => b.category.contains('Fuel'))),
      ('Other benefits', (c) => ben(c, (b) => !(b.category == 'Cashback' || b.category.contains('lounge') || b.category.contains('Fuel')))),
    ];
    return Screen(title: 'Compare cards', subtitle: 'Your own recorded data', children: [
      Text('Select 2–3 cards. This view only lays out what you entered — it does not recommend a card.', style: T.muted),
      const SizedBox(height: 14),
      SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal, clipBehavior: Clip.none, itemCount: d.liveCards.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = d.liveCards.elementAt(i);
            final on = picked.contains(c.id);
            return Pressable(
              onTap: () => setState(() {
                if (on) { picked.remove(c.id); } else if (picked.length < 3) { picked.add(c.id); }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: on ? C.gold : C.border, width: on ? 2 : 1), color: on ? C.gold.withValues(alpha: .1) : null),
                child: MiniCard(c, width: 108),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 18),
      if (cards.length < 2)
        const EmptyState(icon: Icons.compare_arrows_rounded, title: 'Pick two cards', message: 'Choose at least two to see them side by side.')
      else
        Glass(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [const SizedBox(width: 84), for (final c in cards) Expanded(child: Column(children: [MiniCard(c, width: 70), const SizedBox(height: 6), Text(c.title, style: T.caption.copyWith(color: C.text), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)]))]),
            const Divider(height: 24),
            for (final (i, r) in rows.indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: C.border))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 84, child: Text(r.$1, style: T.caption)),
                  for (final c in cards) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text(r.$2(c), textAlign: TextAlign.center, style: T.body.copyWith(fontSize: 12.5)))),
                ]),
              ),
          ]),
        ).rise(),
    ]);
  }
}

