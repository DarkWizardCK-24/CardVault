import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int i = 0;
  static const names = ['Personal', 'Home', 'Car', 'Card EMI', 'Interest', 'Prepay'];
  @override
  Widget build(BuildContext context) {
    final tools = [
      (Icons.receipt_long_outlined, 'Transactions', () => const TransactionsScreen()),
      (Icons.insert_chart_outlined_rounded, 'Spending', () => const SpendingScreen()),
      (Icons.payments_outlined, 'Payments', () => const PaymentPlannerScreen()),
      (Icons.account_balance_wallet_outlined, 'Finances', () => const FinanceOverviewScreen()),
      (Icons.autorenew_rounded, 'Subscriptions', () => const SubscriptionsScreen()),
      (Icons.account_balance_outlined, 'Loans', () => const LoansScreen()),
      (Icons.flag_outlined, 'Goals', () => const GoalsScreen()),
      (Icons.calendar_month_rounded, 'Calendar', () => const CalendarScreen()),
      (Icons.pie_chart_outline_rounded, 'Insights', () => const InsightsScreen()),
    ];
    return Screen(title: 'Tools', subtitle: 'Calculators & money trackers', children: [
      ChipBar(items: names, index: i, onChanged: (v) => setState(() => i = v)),
      const SizedBox(height: 16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(a), child: c)),
        child: switch (i) {
          0 => const LoanCalc(key: ValueKey(0), title: 'Personal loan', p: 500000, r: 11, m: 36, pMin: 50000, pMax: 2500000, pStep: 10000, mMin: 6, mMax: 84),
          1 => const LoanCalc(key: ValueKey(1), title: 'Home loan', p: 5000000, r: 8.5, m: 240, pMin: 500000, pMax: 50000000, pStep: 100000, rMax: 20, mMin: 12, mMax: 360),
          2 => const LoanCalc(key: ValueKey(2), title: 'Car loan', p: 800000, r: 9, m: 60, pMin: 100000, pMax: 5000000, pStep: 25000, rMax: 25, mMin: 12, mMax: 96),
          3 => const LoanCalc(key: ValueKey(3), title: 'Credit card EMI', p: 50000, r: 15, m: 12, pMin: 5000, pMax: 500000, pStep: 5000, rMin: 5, rMax: 45, mMin: 3, mMax: 60),
          4 => const InterestCalc(key: ValueKey(4)),
          _ => const PrepayCalc(key: ValueKey(5)),
        },
      ),
      const SectionHeader('Money tools'),
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisExtent: 104, mainAxisSpacing: 12, crossAxisSpacing: 12),
        children: [
          for (final (k, t) in tools.indexed)
            Glass(
              padding: const EdgeInsets.all(10), radius: 20,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t.$3())),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(t.$1, color: C.gold, size: 26), const SizedBox(height: 8), Text(t.$2, style: T.caption.copyWith(color: C.text), textAlign: TextAlign.center)]),
            ).rise(k),
        ],
      ),
    ]);
  }
}

