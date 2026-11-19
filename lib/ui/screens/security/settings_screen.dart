import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================ settings
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Screen(title: 'Settings', subtitle: 'CardVault 1.0', children: [
      Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('About your data', style: T.h3), const SizedBox(height: 8),
        Text('• Everything is stored locally and encrypted.\n• No accounts, analytics, telemetry or network requests.\n• Currency: Indian Rupee (₹).\n• Figures are entered by you — CardVault does not connect to banks and does not provide credit scores.', style: T.muted),
      ])).rise(),
      const SectionHeader('Data'),
      ListRow(leading: const IconBadge(Icons.auto_awesome_outlined), title: 'Load sample data', subtitle: d.cards.isEmpty ? 'Explore the app with example cards' : 'Adds example cards to your vault', onTap: () async {
        if (await confirm(context, 'Add sample data?', 'Adds illustrative cards, benefits and transactions. You can delete them anytime.', action: 'Add')) {
          await loadDemo(ref.read(dataProvider.notifier), d);
          if (context.mounted) toast(context, 'Sample data added');
        }
      }),
      const SectionHeader('Danger zone'),
      ListRow(leading: const IconBadge(Icons.delete_forever_outlined, color: C.bad), title: 'Erase vault', subtitle: 'Deletes all data and keys from this device', onTap: () async {
        if (!await confirm(context, 'Erase everything?', 'All cards, documents and keys are permanently destroyed. Without a backup this cannot be undone.', action: 'Erase', danger: true)) return;
        if (!context.mounted || !await stepUpAuth(context, ref)) return;
        await docService(ref).wipeAll();
        await ref.read(authProvider.notifier).destroy();
        if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      }),
    ]);
  }
}

