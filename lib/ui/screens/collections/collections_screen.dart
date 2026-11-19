import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final cols = [...d.collections]..sort((a, b) => (b.favourite ? 1 : 0) - (a.favourite ? 1 : 0));
    return Screen(
      title: 'Collections', subtitle: 'Packages of cards',
      actions: [IconPill(Icons.add_rounded, () => collectionForm(context, ref))],
      children: [
        if (cols.isEmpty)
          EmptyState(icon: Icons.folder_special_outlined, title: 'No collections yet', message: 'Group cards into packages like Travel, Daily Banking or Backup — each gets its own layered deck.', action: 'Create collection', onAction: () => collectionForm(context, ref)),
        for (final (i, col) in cols.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Pressable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionDetailScreen(col.id))),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24), border: Border.all(color: C.border),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(col.colorA).withValues(alpha: .32), Color(col.colorB)]),
                ),
                child: Row(children: [
                  IconBadge(kCollectionIcons[col.icon] ?? Icons.star_rounded, color: Color(col.colorA)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(col.name, style: T.h2), Text(col.description.isEmpty ? '${col.cardIds.length} cards' : col.description, style: T.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  SizedBox(
                    width: 80, height: 44,
                    child: Stack(children: [
                      for (final (k, id) in col.cardIds.take(3).toList().indexed)
                        if (d.card(id) != null) Positioned(left: k * 14.0, top: k * 3.0, child: MiniCard(d.card(id)!, width: 52)),
                    ]),
                  ),
                  if (col.favourite) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.star_rounded, color: C.gold, size: 18)),
                ]),
              ),
            ),
          ).rise(i),
      ],
    );
  }
}

