import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CollectionDetailScreen(this.id, {super.key});
  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  bool reorder = false;
  String? sel;
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final col = d.collections.where((c) => c.id == widget.id).firstOrNull;
    if (col == null) return const Scaffold(body: SizedBox());
    final cards = [for (final id in col.cardIds) if (d.card(id) != null) d.card(id)!];
    final total = cards.fold(0.0, (a, c) => a + c.outstanding);
    final limit = cards.fold(0.0, (a, c) => a + c.creditLimit);
    final notes = TextEditingController(text: col.notes);
    final n = ref.read(dataProvider.notifier);
    return Screen(
      title: col.name, subtitle: col.description.isEmpty ? '${cards.length} cards' : col.description,
      actions: [
        IconPill(col.favourite ? Icons.star_rounded : Icons.star_outline_rounded, () { col.favourite = !col.favourite; n.saveCollection(col, silent: true); }, active: col.favourite),
        const SizedBox(width: 8),
        IconPill(Icons.edit_outlined, () => collectionForm(context, ref, col)),
      ],
      children: [
        if (cards.isEmpty)
          const EmptyState(icon: Icons.credit_card_outlined, title: 'Empty collection', message: 'Add cards below to build this stack.')
        else
          CardDeck(cards: cards, selectedId: sel, reorder: reorder, onSelect: (c) => sel = c.id, onOpen: (c) => openCard(context, c.id),
              onLongPress: (c) => cardActions(context, ref, c), onReorder: (l) => n.reorderCards(l, collectionId: col.id)),
        const SizedBox(height: 14),
        if (cards.length > 1) Row(children: [const Spacer(), IconPill(reorder ? Icons.check_rounded : Icons.swap_vert_rounded, () => setState(() => reorder = !reorder), active: reorder, tooltip: 'Reorder')]),
        const SectionHeader('Overview'),
        Row(children: [
          Expanded(child: StatTile('Cards', '${cards.length}', Icons.credit_card_rounded)), const SizedBox(width: 12),
          Expanded(child: StatTile('Outstanding', compactMoney2(total), Icons.account_balance_wallet_outlined)), const SizedBox(width: 12),
          Expanded(child: StatTile('Limit', compactMoney2(limit), Icons.speed_rounded)),
        ]),
        const SectionHeader('Manage cards'),
        for (final c in d.liveCards)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero, activeColor: C.gold, checkColor: C.obsidian, secondary: MiniCard(c, width: 52),
            title: Text(c.title, style: T.body), subtitle: Text('••${c.last4} · ${c.network}', style: T.muted), value: col.cardIds.contains(c.id),
            onChanged: (v) { if (v == true) { col.cardIds.add(c.id); } else { col.cardIds.remove(c.id); } n.saveCollection(col, silent: true); },
          ),
        const SectionHeader('Collection notes'),
        TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Notes for this collection…'), onChanged: (v) { col.notes = v; n.saveCollection(col, silent: true); }),
        const SizedBox(height: 20),
        GoldButton('Delete collection', icon: Icons.delete_outline_rounded, outline: true, onTap: () async {
          if (await confirm(context, 'Delete collection?', 'Cards stay in your vault; only this grouping is removed.', action: 'Delete', danger: true)) {
            await n.deleteCollection(col.id);
            if (context.mounted) Navigator.pop(context);
          }
        }),
      ],
    );
  }
}

