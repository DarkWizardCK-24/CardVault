import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class InterestCalc extends StatefulWidget {
  const InterestCalc({super.key});
  @override
  State<InterestCalc> createState() => _InterestState();
}

class _InterestState extends State<InterestCalc> {
  final p = TextEditingController(text: '100000'), r = TextEditingController(text: '8'), y = TextEditingController(text: '3');
  int mode = 0;
  @override
  Widget build(BuildContext context) {
    final pr = numVal(p), rate = numVal(r), yrs = numVal(y);
    final si = Calc.simpleInterest(pr, rate, yrs);
    final ci = Calc.compoundInterest(pr, rate, yrs, 12);
    final interest = mode == 0 ? si : ci;
    return Column(children: [
      Glass(child: Column(children: [
        ChipBar(items: const ['Simple', 'Compound (monthly)'], index: mode, onChanged: (v) => setState(() => mode = v)),
        const SizedBox(height: 14),
        numField('Principal', p, (_) => setState(() {}), suffix: '₹'), const SizedBox(height: 12),
        Row(children: [Expanded(child: numField('Rate', r, (_) => setState(() {}), suffix: '% p.a.')), const SizedBox(width: 12), Expanded(child: numField('Time', y, (_) => setState(() {}), suffix: 'years'))]),
      ])),
      const SizedBox(height: 14),
      Glass(tint: [C.gold.withValues(alpha: .16), C.gold.withValues(alpha: .04)], child: Column(children: [
        Text('Interest', style: T.caption), Text(money(interest), style: T.display(38, c: C.gold)), const SizedBox(height: 10),
        Text('Total amount  ${money(pr + interest)}', style: T.body),
      ])),
    ]);
  }
}

