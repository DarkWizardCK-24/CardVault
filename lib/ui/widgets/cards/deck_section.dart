import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ----------------------------------------------------------------- deck section
/// Deck + selector + selected-card summary. Used by Overview and Card Vault.
class DeckSection extends ConsumerStatefulWidget {
  final double peek;
  final int visible;
  final bool initialExpanded;
  const DeckSection({super.key, this.peek = .5, this.visible = 3, this.initialExpanded = false});
  @override
  ConsumerState<DeckSection> createState() => _DeckSectionState();
}

class _DeckSectionState extends ConsumerState<DeckSection> {
  late bool expanded = widget.initialExpanded;
  bool reorder = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final fi = ref.watch(deckFilterProvider);
    final names = stackNames(d);
    final idx = fi.clamp(0, names.length - 1);
    final cards = stackCards(d, idx);
    final sel = ref.watch(selectedCardProvider);
    final selected = cards.where((c) => c.id == sel).firstOrNull ?? (cards.isEmpty ? null : cards.first);
    final colId = idx >= kStacks.length ? d.collections[idx - kStacks.length].id : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ChipBar(items: names, index: idx, onChanged: (i) {
        ref.read(deckFilterProvider.notifier).set(i);
        ref.read(selectedCardProvider.notifier).set(null);
        setState(() => reorder = false);
      }),
      const SizedBox(height: 18),
      if (cards.isEmpty)
        EmptyState(
          icon: Icons.credit_card_off_outlined,
          title: d.cards.isEmpty ? 'Your vault is empty' : 'Nothing in this stack',
          message: d.cards.isEmpty ? 'Add your first card to see the signature layered deck come alive.' : 'Cards matching this stack will appear here.',
          action: d.cards.isEmpty ? 'Add a card' : null,
          onAction: () => openCardForm(context),
        )
      else ...[
        CardDeck(
          cards: cards, selectedId: selected?.id,
          expanded: expanded, reorder: reorder, peek: widget.peek, visible: widget.visible,
          onSelect: (c) => ref.read(selectedCardProvider.notifier).set(c.id),
          onOpen: (c) => openCard(context, c.id),
          onLongPress: (c) => cardActions(context, ref, c),
          onReorder: (l) => ref.read(dataProvider.notifier).reorderCards(l, collectionId: colId),
        ),
        const SizedBox(height: 16),
        _toolbar(cards, selected),
        if (selected != null && !reorder) SelectedCardInfo(selected).rise(1),
      ],
    ]);
  }

  Widget _toolbar(List<CardItem> cards, CardItem? sel) => Row(children: [
        Text('${cards.length} card${cards.length == 1 ? '' : 's'}', style: T.muted),
        const Spacer(),
        if (cards.length > 1) ...[
          IconPill(reorder ? Icons.check_rounded : Icons.swap_vert_rounded, () => setState(() {
                reorder = !reorder;
                if (reorder) expanded = false;
              }), tooltip: reorder ? 'Done reordering' : 'Reorder cards', active: reorder),
          const SizedBox(width: 8),
          if (!reorder)
            IconPill(expanded ? Icons.layers_rounded : Icons.view_agenda_outlined, () => setState(() => expanded = !expanded),
                tooltip: expanded ? 'Collapse deck' : 'Expand deck', active: expanded),
        ],
        const SizedBox(width: 8),
        if (sel != null && !reorder) IconPill(Icons.open_in_new_rounded, () => openCard(context, sel.id), tooltip: 'Open details'),
      ]);
}

