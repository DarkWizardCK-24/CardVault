import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= loans
Future<void> loanForm(BuildContext context, WidgetRef ref, {Loan? edit}) async {
  final r = await formSheet(context, edit == null ? 'Add loan' : 'Edit loan', const [
    TextF('name', 'Loan name', required: true), TextF('lender', 'Lender'), TextF('principal', 'Principal (₹)', number: true, required: true),
    TextF('rate', 'Interest rate % p.a.', number: true), TextF('outstanding', 'Outstanding balance (₹)', number: true), TextF('emi', 'Monthly EMI (₹)', number: true),
    DateF('start', 'Start date', required: true), DateF('end', 'End date', required: true), TextF('notes', 'Notes', multiline: true),
  ], initial: edit == null ? {'start': DateTime.now(), 'end': DateTime.now().add(const Duration(days: 365 * 3))} : {...edit.toMap(), 'start': edit.start, 'end': edit.end},
      onDelete: edit == null ? null : () => ref.read(dataProvider.notifier).deleteLoan(edit.id));
  if (r == null) return;
  final l = edit ?? Loan();
  l.name = r['name'];
  l.lender = r['lender'] ?? '';
  l.principal = r['principal'];
  l.rate = r['rate'];
  l.outstanding = (r['outstanding'] as double) == 0 && edit == null ? r['principal'] : r['outstanding'];
  l.emi = r['emi'];
  l.start = r['start'];
  l.end = r['end'];
  l.notes = r['notes'] ?? '';
  await ref.read(dataProvider.notifier).saveLoan(l);
  NotificationService.instance.sync(ref.read(dataProvider));
}

