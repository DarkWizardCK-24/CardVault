import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class PrepayCalc extends StatefulWidget {
  const PrepayCalc({super.key});
  @override
  State<PrepayCalc> createState() => _PrepayState();
}

class _PrepayState extends State<PrepayCalc> {
  final p = TextEditingController(text: '2500000'), r = TextEditingController(text: '8.5'), m = TextEditingController(text: '180'), l = TextEditingController(text: '300000'), a = TextEditingController(text: '24');
  @override
  Widget build(BuildContext context) {
    final pr = numVal(p), rate = numVal(r), mo = numVal(m).toInt(), lump = numVal(l), after = numVal(a).toInt();
    final ok = pr > 0 && mo > 0 && mo <= 600 && lump > 0 && after >= 0 && after < mo;
    final res = ok ? Calc.prepay(pr, rate, mo, lump, after) : null;
    return Column(children: [
      Glass(child: Column(children: [
        numField('Loan amount', p, (_) => setState(() {}), suffix: '₹'), const SizedBox(height: 12),
        Row(children: [Expanded(child: numField('Rate', r, (_) => setState(() {}), suffix: '%')), const SizedBox(width: 12), Expanded(child: numField('Tenure', m, (_) => setState(() {}), suffix: 'mo'))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: numField('Prepayment', l, (_) => setState(() {}), suffix: '₹')), const SizedBox(width: 12), Expanded(child: numField('After month', a, (_) => setState(() {})))]),
      ])),
      const SizedBox(height: 14),
      if (res == null) Text('Check your inputs: the prepayment month must fall within the tenure.', style: T.muted.copyWith(color: C.warn))
      else Glass(tint: [C.good.withValues(alpha: .16), C.good.withValues(alpha: .03)], child: Column(children: [
        Text('Interest saved', style: T.caption), Text(money(res.interestSaved), style: T.display(38, c: C.good)), const SizedBox(height: 10),
        Text('New tenure ${res.newMonths} months (was $mo) · ${mo - res.newMonths} months sooner', style: T.body, textAlign: TextAlign.center),
        Text('EMI stays the same · interest after prepay ${money(res.newTotalInterest)}', style: T.muted, textAlign: TextAlign.center),
      ])),
    ]);
  }
}

