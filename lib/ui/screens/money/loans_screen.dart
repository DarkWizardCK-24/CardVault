import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Screen(title: 'Loans', subtitle: 'Balances & repayment', actions: [IconPill(Icons.add_rounded, () => loanForm(context, ref))], children: [
      if (d.loans.isEmpty) EmptyState(icon: Icons.account_balance_outlined, title: 'No loans', message: 'Track balances, EMIs and repayment progress.', action: 'Add loan', onAction: () => loanForm(context, ref)),
      for (final (i, l) in d.loans.indexed)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Glass(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(l.id))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(l.name, style: T.h2)), Text(money(l.emi), style: T.num(16, c: C.gold)), Text(' /mo', style: T.caption)]),
            Text('${l.lender} · ${l.rate}% · ends ${dMonth(l.end)}', style: T.muted),
            const SizedBox(height: 14), Progress(l.progress, color: C.good), const SizedBox(height: 6),
            Text('${money(l.outstanding)} left of ${money(l.principal)} · ${(l.progress * 100).toStringAsFixed(0)}% repaid', style: T.caption),
          ]),
        )).rise(i.clamp(0, 6)),
    ]);
  }
}

