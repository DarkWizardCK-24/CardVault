import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TxnState();
}

class _TxnState extends ConsumerState<TransactionsScreen> {
  String q = '';
  int f = 0;
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final l = d.txns.where((t) => (f == 0 || (f == 1 && !t.paid) || (f == 2 && t.paid)) && (q.isEmpty || '${t.merchant} ${t.category} ${t.notes}'.toLowerCase().contains(q.toLowerCase()))).toList();
    return Screen(
      title: 'Transactions', subtitle: 'Manually tracked',
      actions: [IconPill(Icons.add_rounded, () => txnForm(context, ref))],
      children: [
        TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(hintText: 'Search merchant, category…', prefixIcon: Icon(Icons.search_rounded, size: 20))),
        const SizedBox(height: 12),
        ChipBar(items: const ['All', 'Unpaid', 'Paid'], index: f, onChanged: (i) => setState(() => f = i)),
        const SizedBox(height: 14),
        if (d.cards.isEmpty) const EmptyState(icon: Icons.credit_card_off_outlined, title: 'Add a card first', message: 'Transactions are linked to one of your cards.')
        else if (l.isEmpty) EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions', message: 'Record spends to unlock reports and analytics.', action: 'Add transaction', onAction: () => txnForm(context, ref))
        else for (final (i, t) in l.indexed) TxnRow(t).rise(i.clamp(0, 6)),
      ],
    );
  }
}

