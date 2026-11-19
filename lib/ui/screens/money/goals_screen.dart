import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Screen(title: 'Goals', subtitle: 'Financial targets', actions: [IconPill(Icons.add_rounded, () => goalForm(context, ref))], children: [
      if (d.goals.isEmpty) EmptyState(icon: Icons.flag_outlined, title: 'No goals yet', message: 'Set a target and watch the progress fill up.', action: 'Add goal', onAction: () => goalForm(context, ref)),
      for (final (i, g) in d.goals.indexed)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Glass(
          onTap: () => goalForm(context, ref, edit: g),
          child: Row(children: [
            Ring(g.progress, label: '${(g.progress * 100).toStringAsFixed(0)}%', size: 78),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: T.h2), const SizedBox(height: 2),
              Text('${money(g.current)} of ${money(g.target)}', style: T.muted),
              if (g.targetDate != null) Text('By ${dShort(g.targetDate!)}', style: T.caption.copyWith(color: C.gold)),
            ])),
          ]),
        )).rise(i.clamp(0, 6)),
    ]);
  }
}

