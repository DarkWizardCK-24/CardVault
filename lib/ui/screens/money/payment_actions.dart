import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= payment planner
Future<void> addPayment(BuildContext context, WidgetRef ref, [String? cardId]) async {
  final r = await formSheet(context, 'Record payment', const [
    CardF('cardId', 'Card', required: true), TextF('amount', 'Amount paid (₹)', number: true, required: true),
    TextF('totalDue', 'Total amount due (₹)', number: true), TextF('minDue', 'Minimum due (₹)', number: true),
    DateF('date', 'Payment date', required: true), TextF('note', 'Confirmation note / reference', multiline: true),
  ], initial: {'cardId': cardId ?? ref.read(dataProvider).creditCards.firstOrNull?.id ?? '', 'date': DateTime.now()}, save: 'Save payment');
  if (r == null) return;
  await ref.read(dataProvider.notifier).savePayment(Payment(cardId: r['cardId'], amount: r['amount'], totalDue: r['totalDue'], minDue: r['minDue'], date: r['date'], note: r['note'] ?? ''));
  if (context.mounted) toast(context, 'Payment recorded · outstanding updated');
}

