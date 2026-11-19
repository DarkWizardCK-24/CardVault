import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

const kTxnCats = ['Shopping', 'Food & dining', 'Groceries', 'Fuel', 'Travel', 'Bills & utilities', 'Entertainment', 'Health', 'EMI', 'Other'];

IconData catIcon(String c) => switch (c) {
      'Shopping' => Icons.shopping_bag_outlined, 'Food & dining' => Icons.restaurant_outlined, 'Groceries' => Icons.local_grocery_store_outlined,
      'Fuel' => Icons.local_gas_station_outlined, 'Travel' => Icons.flight_outlined, 'Bills & utilities' => Icons.bolt_outlined,
      'Entertainment' => Icons.movie_outlined, 'Health' => Icons.favorite_border_rounded, 'EMI' => Icons.event_repeat_rounded, _ => Icons.receipt_long_outlined,
    };

// ============================================================= transactions
Future<void> txnForm(BuildContext context, WidgetRef ref, {Txn? edit}) async {
  final r = await formSheet(context, edit == null ? 'Add transaction' : 'Edit transaction', const [
    TextF('merchant', 'Merchant', required: true), TextF('amount', 'Amount (₹)', number: true, required: true),
    DropF('category', 'Category', kTxnCats), CardF('cardId', 'Card', required: true), DateF('date', 'Date', required: true),
    SwitchF('paid', 'Marked as paid'), SwitchF('isRefund', 'Refund / credit'), TextF('notes', 'Notes', multiline: true),
  ], initial: edit == null ? {'date': DateTime.now(), 'category': 'Shopping', 'cardId': ref.read(dataProvider).cards.firstOrNull?.id ?? ''} : {...edit.toMap(), 'date': edit.date},
      onDelete: edit == null ? null : () async {
        if (await confirm(context, 'Delete transaction?', 'Remove “${edit.merchant}”?', action: 'Delete', danger: true)) ref.read(dataProvider.notifier).deleteTxn(edit.id);
      });
  if (r == null) return;
  final t = edit ?? Txn();
  t.merchant = r['merchant'];
  t.amount = r['amount'];
  t.category = r['category'] ?? 'Other';
  t.cardId = r['cardId'] ?? '';
  t.date = r['date'] ?? DateTime.now();
  t.paid = r['paid'] == true;
  t.isRefund = r['isRefund'] == true;
  t.notes = r['notes'] ?? '';
  await ref.read(dataProvider.notifier).saveTxn(t);
}

