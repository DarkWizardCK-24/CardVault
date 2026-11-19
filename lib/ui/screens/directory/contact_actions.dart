import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

Future<void> contactForm(BuildContext context, WidgetRef ref, {Contact? edit, bool note = false}) async {
  final isNote = edit?.personalNote ?? note;
  final r = await formSheet(context, isNote ? 'Emergency note' : (edit == null ? 'Add bank contact' : 'Edit bank contact'), isNote
      ? const [TextF('bank', 'Title', required: true), TextF('instructions', 'Note', multiline: true, required: true)]
      : const [
          TextF('bank', 'Bank', required: true, hint: 'e.g. HDFC Bank'), TextF('phone', 'Customer care number'), TextF('lostCardPhone', 'Lost-card / blocking number'),
          TextF('website', 'Website'), TextF('instructions', 'Blocking instructions (your own)', multiline: true),
        ], initial: edit?.toMap() ?? {}, onDelete: edit == null ? null : () => ref.read(dataProvider.notifier).deleteContact(edit.id));
  if (r == null) return;
  final c = edit ?? Contact(personalNote: isNote);
  c.bank = r['bank'];
  c.phone = r['phone'] ?? '';
  c.lostCardPhone = r['lostCardPhone'] ?? '';
  c.website = r['website'] ?? '';
  c.instructions = r['instructions'] ?? '';
  await ref.read(dataProvider.notifier).saveContact(c);
}

