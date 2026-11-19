import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= goals
Future<void> goalForm(BuildContext context, WidgetRef ref, {Goal? edit}) async {
  final r = await formSheet(context, edit == null ? 'New goal' : 'Edit goal', const [
    TextF('name', 'Goal name', required: true), TextF('target', 'Target amount (₹)', number: true, required: true), TextF('current', 'Saved so far (₹)', number: true),
    DateF('targetDate', 'Target date'), TextF('notes', 'Notes', multiline: true),
  ], initial: edit?.toMap().map((k, v) => MapEntry(k, k == 'targetDate' ? edit.targetDate : v)) ?? {}, onDelete: edit == null ? null : () => ref.read(dataProvider.notifier).deleteGoal(edit.id));
  if (r == null) return;
  final g = edit ?? Goal();
  g.name = r['name'];
  g.target = r['target'];
  g.current = r['current'];
  g.targetDate = r['targetDate'];
  g.notes = r['notes'] ?? '';
  await ref.read(dataProvider.notifier).saveGoal(g);
}

