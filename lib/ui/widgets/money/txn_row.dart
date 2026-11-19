import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class TxnRow extends ConsumerWidget {
  final Txn t;
  const TxnRow(this.t, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(dataProvider).card(t.cardId);
    return ListRow(
      leading: IconBadge(catIcon(t.category)), title: t.merchant,
      subtitle: '${t.category} · ${card?.title ?? 'Unknown card'} · ${dDay(t.date)}',
      trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${t.isRefund ? '+' : ''}${money(t.amount)}', style: T.num(15, c: t.isRefund ? C.good : C.text)),
        Tag(t.paid ? 'Paid' : 'Unpaid', color: t.paid ? C.good : C.warn),
      ]),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(t.id))),
      onLongPress: () => txnForm(context, ref, edit: t),
    );
  }
}

