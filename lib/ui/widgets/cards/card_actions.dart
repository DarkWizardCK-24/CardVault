import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ----------------------------------------------------------------- quick actions
Future<void> cardActions(BuildContext context, WidgetRef ref, CardItem c) async {
  HapticFeedback.mediumImpact();
  final n = ref.read(dataProvider.notifier);
  Widget row(IconData i, String t, VoidCallback f, {Color? color}) => ListTile(
        leading: Icon(i, color: color ?? C.silver), title: Text(t, style: T.body.copyWith(color: color)),
        onTap: () {
          Navigator.pop(context);
          f();
        },
      );
  await sheet(context, SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [MiniCard(c, width: 56), const SizedBox(width: 14), Expanded(child: Text(c.title, style: T.h2))])),
    row(Icons.open_in_new_rounded, 'Open details', () => openCard(context, c.id)),
    row(c.favourite ? Icons.star_rounded : Icons.star_outline_rounded, c.favourite ? 'Remove from favourites' : 'Add to favourites', () {
      c.favourite = !c.favourite;
      n.saveCard(c);
    }, color: C.gold),
    row(Icons.edit_outlined, 'Edit card', () => openCardForm(context, c)),
    row(Icons.folder_special_outlined, 'Add to collection', () => pickCollection(context, ref, c)),
    row(c.status == CardStatus.blocked ? Icons.lock_open_rounded : Icons.block_rounded, c.status == CardStatus.blocked ? 'Mark as active' : 'Mark as blocked', () {
      c.status = c.status == CardStatus.blocked ? CardStatus.active : CardStatus.blocked;
      n.saveCard(c);
    }),
    row(Icons.archive_outlined, 'Archive', () {
      c.status = CardStatus.archived;
      n.saveCard(c);
      toast(context, 'Archived ${c.title}');
    }),
    row(Icons.delete_outline_rounded, 'Delete', () async {
      if (await confirm(context, 'Delete card?', '${c.title} and its benefits will be permanently removed from this device.', action: 'Delete', danger: true)) {
        await n.deleteCard(c.id);
      }
    }, color: C.bad),
  ])));
}

