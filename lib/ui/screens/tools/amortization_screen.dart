import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class AmortizationScreen extends StatelessWidget {
  final LoanResult res;
  final String title;
  const AmortizationScreen(this.res, this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    final yearly = <int, List<AmortRow>>{};
    for (final r in res.schedule) {
      (yearly[(r.month - 1) ~/ 12 + 1] ??= []).add(r);
    }
    return Screen(title: 'Amortization', subtitle: title, children: [
      Glass(child: Bars([for (final y in yearly.keys.take(10)) 'Y$y'], [for (final y in yearly.keys.take(10)) yearly[y]!.fold(0.0, (a, r) => a + r.interest)], height: 150)),
      const SectionHeader('Interest paid per year'),
      for (final (i, r) in res.schedule.indexed)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${r.month}', style: T.caption)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Principal ${money(r.principal)}', style: T.body.copyWith(fontSize: 13)),
              Text('Interest ${money(r.interest)}', style: T.caption),
            ])),
            Text(money(r.balance), style: T.num(14)),
          ]),
        ).rise(i < 8 ? i : 0),
    ]);
  }
}

