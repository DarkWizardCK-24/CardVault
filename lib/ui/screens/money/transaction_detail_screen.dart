import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final t = d.txns.where((x) => x.id == id).firstOrNull;
    if (t == null) return const Scaffold(body: SizedBox());
    final c = d.card(t.cardId);
    Widget kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(k, style: T.muted)), Text(v.isEmpty ? '—' : v, style: T.body)]));
    return Screen(title: t.merchant, subtitle: t.category, actions: [IconPill(Icons.edit_outlined, () => txnForm(context, ref, edit: t))], children: [
      Glass(child: Column(children: [
        Text(money(t.amount, decimals: true), style: T.display(40, c: t.isRefund ? C.good : C.gold)).rise(),
        const SizedBox(height: 14),
        kv('Card', c?.title ?? ''), kv('Date', dShort(t.date)), kv('Status', t.paid ? 'Paid' : 'Unpaid'), kv('Type', t.isRefund ? 'Refund' : 'Purchase'), kv('Notes', t.notes),
      ])),
      const SizedBox(height: 16),
      GoldButton(t.paid ? 'Mark unpaid' : 'Mark paid', icon: Icons.check_circle_outline, onTap: () {
        t.paid = !t.paid;
        ref.read(dataProvider.notifier).saveTxn(t);
      }),
      const SizedBox(height: 12),
      GoldButton('Delete', icon: Icons.delete_outline_rounded, outline: true, onTap: () async {
        if (await confirm(context, 'Delete transaction?', 'This cannot be undone.', action: 'Delete', danger: true)) {
          await ref.read(dataProvider.notifier).deleteTxn(t.id);
          if (context.mounted) Navigator.pop(context);
        }
      }),
    ]);
  }
}

