import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================ reminders
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(dataProvider).settings;
    final n = ref.read(dataProvider.notifier);
    Future<void> save() async {
      await n.saveSettings(st);
      await NotificationService.instance.sync(ref.read(dataProvider));
    }
    return Screen(title: 'Reminders', subtitle: 'Local notifications only', children: [
      Glass(child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Enable reminders', style: T.body), subtitle: Text('Scheduled on this device — nothing is sent online', style: T.muted), value: st.notificationsOn, onChanged: (v) async {
          if (v && !await NotificationService.instance.requestPermission() && NotificationService.instance.supported) {
            if (context.mounted) toast(context, 'Allow notifications in system settings');
          }
          st.notificationsOn = v;
          await save();
        }),
      ])).rise(),
      const SectionHeader('Remind me before'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final dd in [0, 1, 2, 3, 7, 14, 30])
          FilterChip(
            label: Text(dd == 0 ? 'On the day' : '$dd day${dd == 1 ? '' : 's'}'), selected: st.remindDays.contains(dd), selectedColor: C.gold.withValues(alpha: .25), checkmarkColor: C.gold,
            onSelected: (v) async {
              if (v) { st.remindDays.add(dd); } else if (st.remindDays.length > 1) { st.remindDays.remove(dd); }
              await save();
            },
          ),
      ]),
      const SectionHeader('Time of day'),
      Glass(child: Row(children: [
        Expanded(child: Text('${st.remindHour.toString().padLeft(2, '0')}:00', style: T.num(24))),
        Expanded(flex: 3, child: Slider(value: st.remindHour.toDouble(), min: 6, max: 22, divisions: 16, activeColor: C.gold, onChanged: (v) { st.remindHour = v.round(); n.saveSettings(st); }, onChangeEnd: (_) => save())),
      ])),
      const SectionHeader('Frequency'),
      ChipBar(items: const ['Once per lead time', 'Daily until due'], index: st.frequency == 'daily' ? 1 : 0, onChanged: (i) async {
        st.frequency = i == 1 ? 'daily' : 'once';
        await save();
      }),
      const SizedBox(height: 18),
      Text('Reminders cover card expiry, billing and due dates, annual fees, benefit expiry, subscription renewals and loan EMIs. Notifications never include card numbers.', style: T.caption),
    ]);
  }
}

