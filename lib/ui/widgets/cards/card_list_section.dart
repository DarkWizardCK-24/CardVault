import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Searchable, filterable, sortable list of every card in the vault.
class CardListSection extends ConsumerStatefulWidget {
  const CardListSection({super.key});
  @override
  ConsumerState<CardListSection> createState() => _CardListSectionState();
}

class _CardListSectionState extends ConsumerState<CardListSection> {
  String q = '';
  int status = 0, sort = 0;
  static const sorts = ['Custom order', 'Bank A–Z', 'Highest limit', 'Highest outstanding', 'Expiry soon'];
  static const statuses = ['Live', 'Active', 'Blocked', 'Expired', 'Archived', 'Replaced'];

  List<CardItem> _filtered(VaultData d) {
    final list = d.cards.where((c) {
      final ok = switch (status) {
        1 => c.status == CardStatus.active && !c.isExpired,
        2 => c.status == CardStatus.blocked,
        3 => c.isExpired || c.status == CardStatus.expired,
        4 => c.status == CardStatus.archived,
        5 => c.status == CardStatus.replaced,
        _ => c.status != CardStatus.archived,
      };
      final text = '${c.title} ${c.bank} ${c.network} ${c.last4} ${c.holder} ${c.product}'.toLowerCase();
      return ok && (q.isEmpty || text.contains(q.toLowerCase()));
    }).toList();
    switch (sort) {
      case 1:
        list.sort((a, b) => a.bank.compareTo(b.bank));
      case 2:
        list.sort((a, b) => b.creditLimit.compareTo(a.creditLimit));
      case 3:
        list.sort((a, b) => b.outstanding.compareTo(a.outstanding));
      case 4:
        list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered(ref.watch(dataProvider));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('All cards'),
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: 'Search bank, nickname, last 4…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: PopupMenuButton<int>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded, size: 20),
            color: C.charcoal,
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => [for (var i = 0; i < sorts.length; i++) CheckedPopupMenuItem(value: i, checked: sort == i, child: Text(sorts[i]))],
          ),
        ),
      ),
      const SizedBox(height: 12),
      ChipBar(items: statuses, index: status, onChanged: (i) => setState(() => status = i)),
      const SizedBox(height: 14),
      if (list.isEmpty)
        const EmptyState(icon: Icons.search_off_rounded, title: 'No cards found', message: 'Try a different search or filter.')
      else
        for (final (i, c) in list.indexed)
          ListRow(
            leading: MiniCard(c, width: 62),
            title: c.title,
            subtitle: '${cardSubtitle(c)} · ••${c.last4}',
            trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (c.favourite) const Icon(Icons.star_rounded, color: C.gold, size: 18),
              if (c.status != CardStatus.active) Tag(c.status.name, color: c.status == CardStatus.blocked ? C.bad : C.warn),
            ]),
            onTap: () => openCard(context, c.id),
            onLongPress: () => cardActions(context, ref, c),
          ).rise(i.clamp(0, 6)),
    ]);
  }
}
