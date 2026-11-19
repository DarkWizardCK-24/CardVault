import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Card Vault tab: the layered deck plus a searchable list (side by side when wide).
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Screen(
      title: 'Card Vault',
      subtitle: '${d.liveCards.length} cards secured',
      maxWidth: 1180,
      actions: [
        IconPill(Icons.compare_arrows_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())), tooltip: 'Compare cards'),
        const SizedBox(width: 8),
        IconPill(Icons.folder_special_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionsScreen())), tooltip: 'Collections'),
        const SizedBox(width: 8),
        IconPill(Icons.backup_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())), tooltip: 'Backup & restore'),
      ],
      children: [
        TwoPane(
          leftWidth: 430,
          left: const DeckSection().rise(),
          right: const CardListSection(),
        ),
      ],
    );
  }
}
