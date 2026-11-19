import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

const kCollectionIcons = <String, IconData>{
  'star': Icons.star_rounded, 'flight': Icons.flight_takeoff_rounded, 'cart': Icons.shopping_bag_outlined,
  'work': Icons.work_outline_rounded, 'bank': Icons.account_balance_outlined, 'shield': Icons.shield_outlined,
  'home': Icons.home_outlined, 'diamond': Icons.diamond_outlined,
};

const kCollectionPalettes = <List<int>>[
  [0xFFD6B779, 0xFF3A2F1A], [0xFF5B8DEF, 0xFF14213D], [0xFFE2662B, 0xFF4A1A0A], [0xFF3FA074, 0xFF0F2E1D],
  [0xFFB06AB3, 0xFF2D0B33], [0xFFB8BEC8, 0xFF20242C],
];

Future<void> pickCollection(BuildContext context, WidgetRef ref, CardItem c) async {
  final d = ref.read(dataProvider);
  await sheet(context, StatefulBuilder(builder: (ctx, set) {
    final cols = ref.read(dataProvider).collections;
    return SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add to collection', style: T.h1), const SizedBox(height: 12),
        if (d.collections.isEmpty) Text('No collections yet — create one first.', style: T.muted),
        for (final col in cols)
          CheckboxListTile(
            activeColor: C.gold, checkColor: C.obsidian, value: col.cardIds.contains(c.id), title: Text(col.name),
            onChanged: (v) async {
              if (v == true) { col.cardIds.add(c.id); } else { col.cardIds.remove(c.id); }
              await ref.read(dataProvider.notifier).saveCollection(col, silent: true);
              set(() {});
            },
          ),
      ]),
    ));
  }));
}

Future<void> collectionForm(BuildContext context, WidgetRef ref, [Collection? edit]) async {
  final col = edit ?? Collection();
  final name = TextEditingController(text: col.name);
  final desc = TextEditingController(text: col.description);
  await sheet(context, StatefulBuilder(builder: (ctx, set) => SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(edit == null ? 'New collection' : 'Edit collection', style: T.h1), const SizedBox(height: 14),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Collection name')), const SizedBox(height: 12),
      TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')), const SizedBox(height: 14),
      Text('ICON', style: T.label), const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final e in kCollectionIcons.entries)
          GestureDetector(onTap: () => set(() => col.icon = e.key), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 48, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: col.icon == e.key ? C.gold.withValues(alpha: .2) : C.charcoal, border: Border.all(color: col.icon == e.key ? C.gold : C.border)),
            child: Icon(e.value, color: col.icon == e.key ? C.gold : C.silver))),
      ]),
      const SizedBox(height: 14), Text('COVER GRADIENT', style: T.label), const SizedBox(height: 8),
      Wrap(spacing: 10, children: [
        for (final p in kCollectionPalettes)
          GestureDetector(onTap: () => set(() { col.colorA = p[0]; col.colorB = p[1]; }), child: Container(width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(p[0]), Color(p[1])]), border: Border.all(color: col.colorA == p[0] ? C.gold : Colors.white24, width: col.colorA == p[0] ? 3 : 1)))),
      ]),
      const SizedBox(height: 22),
      GoldButton('Save', onTap: () async {
        if (name.text.trim().isEmpty) return;
        col.name = name.text.trim();
        col.description = desc.text.trim();
        await ref.read(dataProvider.notifier).saveCollection(col);
        if (ctx.mounted) Navigator.pop(ctx);
      }),
    ]),
  )));
}

String compactMoney2(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹${v.toStringAsFixed(0)}';
}

