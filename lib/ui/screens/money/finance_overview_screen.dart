import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ============================================================= financial overview
class FinanceOverviewScreen extends ConsumerWidget {
  const FinanceOverviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final u = d.utilization;
    final loanOut = d.loans.fold(0.0, (a, l) => a + l.outstanding);
    final repaid = d.loans.fold(0.0, (a, l) => a + (l.principal - l.outstanding));
    final principal = d.loans.fold(0.0, (a, l) => a + l.principal);
    return Screen(title: 'Financial overview', subtitle: 'From the figures you entered', children: [
      Glass(child: Row(children: [
        Ring(u / 100, label: '${u.toStringAsFixed(0)}%', caption: 'utilised', color: u > 70 ? C.bad : (u > 40 ? C.warn : C.good)),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Credit utilisation', style: T.h3), const SizedBox(height: 6),
          Text('Outstanding ÷ total limit, using the amounts you entered. Not a credit score.', style: T.muted),
        ])),
      ])).rise(),
      const SectionHeader('Credit'),
      Row(children: [
        Expanded(child: StatTile('Total limit', compactMoney(d.totalLimit), Icons.speed_rounded)), const SizedBox(width: 12),
        Expanded(child: StatTile('Outstanding', compactMoney(d.totalOutstanding), Icons.account_balance_wallet_outlined, color: C.warn)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatTile('Available', compactMoney(d.totalAvailable), Icons.savings_outlined, color: C.good)), const SizedBox(width: 12),
        Expanded(child: StatTile('Annual fees', compactMoney(d.annualFees), Icons.receipt_long_outlined)),
      ]),
      const SectionHeader('Liabilities'),
      Row(children: [
        Expanded(child: StatTile('Loan balance', compactMoney(loanOut), Icons.account_balance_outlined)), const SizedBox(width: 12),
        Expanded(child: StatTile('Monthly EMI', compactMoney(d.monthlyLoanEmi), Icons.event_repeat_rounded)),
      ]),
      const SizedBox(height: 12),
      Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Repayment progress', style: T.h3), const SizedBox(height: 10),
        Progress(principal <= 0 ? 0 : repaid / principal, color: C.good), const SizedBox(height: 6),
        Text('${money(repaid)} repaid of ${money(principal)}', style: T.muted),
      ])),
      const SectionHeader('Recurring'),
      Row(children: [
        Expanded(child: StatTile('Subscriptions / mo', compactMoney(d.monthlySubs), Icons.autorenew_rounded)), const SizedBox(width: 12),
        Expanded(child: StatTile('Obligations / mo', compactMoney(d.monthlySubs + d.monthlyLoanEmi), Icons.event_note_rounded)),
      ]),
    ]);
  }
}

