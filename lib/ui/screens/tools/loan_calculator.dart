import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// EMI calculator used for personal, home, car and card-EMI loans (only the ranges differ).
class LoanCalc extends StatefulWidget {
  final String title;
  final double p, r;
  final int m;

  /// Slider ranges for principal (₹), interest rate (% p.a.) and tenure (months).
  final double pMin, pMax, pStep, rMin, rMax;
  final int mMin, mMax;
  const LoanCalc({
    super.key,
    required this.title,
    required this.p,
    required this.r,
    required this.m,
    required this.pMin,
    required this.pMax,
    required this.pStep,
    this.rMin = 1,
    this.rMax = 30,
    required this.mMin,
    required this.mMax,
  });
  @override
  State<LoanCalc> createState() => _LoanCalcState();
}

class _LoanCalcState extends State<LoanCalc> {
  late final p = TextEditingController(text: widget.p.toStringAsFixed(0));
  late final r = TextEditingController(text: '${widget.r}');
  late final m = TextEditingController(text: '${widget.m}');

  @override
  void dispose() {
    p.dispose();
    r.dispose();
    m.dispose();
    super.dispose();
  }

  String _tenure(int months) {
    if (months < 12) return '$months months';
    final y = months ~/ 12, rem = months % 12;
    return rem == 0 ? '$y year${y == 1 ? '' : 's'}' : '$y yr $rem mo';
  }

  @override
  Widget build(BuildContext context) {
    final pr = numVal(p), rate = numVal(r), mo = numVal(m).toInt();
    final ok = pr > 0 && mo > 0 && mo <= 600 && rate >= 0 && rate <= 100;
    final res = ok ? Calc.loan(pr, rate, mo) : null;
    void refresh(String _) => setState(() {});
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Glass(
        child: Column(children: [
          SliderField(label: 'Loan amount', controller: p, min: widget.pMin, max: widget.pMax, step: widget.pStep, suffix: '₹', hint: pr > 0 ? compactMoney(pr) : null, onChanged: refresh),
          const SizedBox(height: 8),
          SliderField(label: 'Interest rate', controller: r, min: widget.rMin, max: widget.rMax, step: .1, suffix: '% p.a.', onChanged: refresh),
          const SizedBox(height: 8),
          SliderField(label: 'Tenure', controller: m, min: widget.mMin.toDouble(), max: widget.mMax.toDouble(), suffix: 'months', hint: mo > 0 ? _tenure(mo) : null, onChanged: refresh),
        ]),
      ),
      const SizedBox(height: 14),
      if (res == null)
        Text('Enter a valid principal, rate (0–100%) and tenure (1–600 months).', style: T.muted.copyWith(color: C.warn))
      else ...[
        Glass(
          tint: [C.gold.withValues(alpha: .16), C.gold.withValues(alpha: .04)],
          child: Column(children: [
            Text('Monthly EMI', style: T.caption),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
                tween: Tween(end: res.emi), duration: const Duration(milliseconds: 500), builder: (_, v, _) => Text(money(v), style: T.display(40, c: C.gold))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(children: [Text(money(pr), style: T.num(15)), Text('Principal', style: T.caption)])),
              Expanded(child: Column(children: [Text(money(res.totalInterest), style: T.num(15)), Text('Total interest', style: T.caption)])),
              Expanded(child: Column(children: [Text(money(res.totalPayment), style: T.num(15)), Text('Total repayment', style: T.caption)])),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Glass(child: Donut({'Principal': pr, 'Interest': res.totalInterest}, size: 130)),
        const SizedBox(height: 14),
        GoldButton('Amortization schedule', icon: Icons.table_rows_rounded, outline: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AmortizationScreen(res, widget.title)))),
      ],
    ]);
  }
}
