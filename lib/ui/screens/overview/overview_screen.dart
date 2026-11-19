import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Dashboard. Single column on phones; deck on the left and details on the right when wide.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, box) {
            final side = gutterFor(box.maxWidth, 1180);
            final wide = box.maxWidth >= 780;
            final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              BackupReminderBanner(d),
              if (wide) const SizedBox(height: 4),
              const SectionHeader('Quick actions'),
              const QuickActionsRow(),
              SectionHeader('Financial overview', trailing: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen())), child: const Text('Insights'))),
              Text('Figures you entered — not live banking data.', style: T.caption),
              const SizedBox(height: 10),
              FinancialGrid(d),
              UpcomingSection(d),
              RecentActivity(d),
            ]);
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(side, 12, side, 130),
              children: [
                const OverviewHeader().rise(),
                const SizedBox(height: 22),
                wide
                    ? TwoPane(leftWidth: 400, left: const DeckSection(peek: .5, visible: 2).rise(1), right: right)
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const DeckSection(peek: .5, visible: 2).rise(1),
                        right,
                      ]),
                const SizedBox(height: 18),
                Center(child: Text('Everything stays on this device · fully offline', style: T.caption)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
