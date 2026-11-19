import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final l = d.loans.where((x) => x.id == id).firstOrNull;
    if (l == null) return const Scaffold(body: SizedBox());
    final months = ((l.end.year - l.start.year) * 12 + l.end.month - l.start.month).clamp(1, 600);
    final plan = Calc.loan(l.principal, l.rate, months);
    return Screen(title: l.name, subtitle: l.lender, actions: [IconPill(Icons.edit_outlined, () => loanForm(context, ref, edit: l))], children: [
      Glass(child: Column(children: [
        Center(child: Ring(l.progress, label: '${(l.progress * 100).toStringAsFixed(0)}%', caption: 'repaid', color: C.good, size: 130)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(children: [Text(money(l.outstanding), style: T.num(17)), Text('Outstanding', style: T.caption)])),
          Expanded(child: Column(children: [Text(money(l.emi), style: T.num(17)), Text('EMI', style: T.caption)])),
          Expanded(child: Column(children: [Text(money(plan.totalInterest), style: T.num(17)), Text('Est. interest', style: T.caption)])),
        ]),
      ])).rise(),
      const SizedBox(height: 14),
      GoldButton('Record EMI payment', icon: Icons.payments_outlined, onTap: () async {
        final r = await formSheet(context, 'Loan payment', const [TextF('amount', 'Amount (₹)', number: true, required: true), DateF('date', 'Date', required: true)], initial: {'amount': l.emi, 'date': DateTime.now()});
        if (r == null) return;
        l.payments.insert(0, {'date': (r['date'] as DateTime).toIso8601String(), 'amount': r['amount']});
        l.outstanding = (l.outstanding - (r['amount'] as double)).clamp(0, double.infinity);
        await ref.read(dataProvider.notifier).saveLoan(l);
        HapticFeedback.mediumImpact();
      }),
      const SectionHeader('Payment history'),
      if (l.payments.isEmpty) Text('No payments recorded.', style: T.muted),
      for (final p in l.payments.take(24)) ListRow(leading: const IconBadge(Icons.check_circle_outline, color: C.good), title: money((p['amount'] as num).toDouble()), subtitle: dShort(DateTime.parse(p['date']))),
      const SectionHeader('Repayment schedule (estimate)'),
      for (final r in plan.schedule.take(12))
        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          SizedBox(width: 34, child: Text('${r.month}', style: T.caption)), Expanded(child: Text('P ${money(r.principal)}  ·  I ${money(r.interest)}', style: T.muted)), Text(money(r.balance), style: T.body),
        ])),
      if (plan.schedule.length > 12) Text('… ${plan.schedule.length - 12} more months', style: T.caption),
    ]);
  }
}

