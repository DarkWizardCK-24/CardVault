import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Full local activity log, grouped by day.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(dataProvider).activity;
    return Screen(title: 'Activity', subtitle: '${items.length} recorded on this device', children: [
      if (items.isEmpty)
        const EmptyState(icon: Icons.history_rounded, title: 'No activity yet', message: 'Changes you make in the vault are logged here.')
      else
        Glass(padding: const EdgeInsets.fromLTRB(14, 8, 14, 8), child: ActivityTimeline(items)).rise(),
    ]);
  }
}
