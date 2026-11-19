import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= subscriptions
const kSubCats = ['Entertainment', 'Music', 'Cloud & software', 'News', 'Fitness', 'Shopping', 'Utilities', 'Other'];

Future<void> subForm(BuildContext context, WidgetRef ref, {Subscription? edit}) async {
  final r = await formSheet(context, edit == null ? 'Add subscription' : 'Edit subscription', const [
    TextF('name', 'Name', required: true), TextF('amount', 'Amount (₹)', number: true, required: true), DropF('billing', 'Billing', ['Monthly', 'Yearly']),
    CardF('cardId', 'Billed to card'), DateF('renewal', 'Next renewal', required: true), DropF('category', 'Category', kSubCats),
    SwitchF('active', 'Active'), TextF('notes', 'Notes', multiline: true),
  ], initial: edit == null ? {'billing': 'Monthly', 'renewal': DateTime.now().add(const Duration(days: 30)), 'active': true, 'category': 'Entertainment'}
      : {...edit.toMap(), 'billing': edit.yearly ? 'Yearly' : 'Monthly', 'renewal': edit.renewal},
      onDelete: edit == null ? null : () => ref.read(dataProvider.notifier).deleteSub(edit.id));
  if (r == null) return;
  final s = edit ?? Subscription();
  s.name = r['name'];
  s.amount = r['amount'];
  s.yearly = r['billing'] == 'Yearly';
  s.cardId = r['cardId'] ?? '';
  s.renewal = r['renewal'];
  s.category = r['category'] ?? 'Other';
  s.active = r['active'] == true;
  s.notes = r['notes'] ?? '';
  await ref.read(dataProvider.notifier).saveSub(s);
  NotificationService.instance.sync(ref.read(dataProvider));
}

