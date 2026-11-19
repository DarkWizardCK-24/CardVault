import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Home. Single column on phones; deck on the left and the summary on the right when wide.
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
            final wide = box.maxWidth >= 860;
            final summary = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HeroSummary(d).rise(1),
              const SizedBox(height: 18),
              const QuickActionsRow(),
              const SizedBox(height: 16),
              FinancialGrid(d),
              BackupReminderBanner(d),
            ]);
            final feed = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ExpiringCards(d),
              UpcomingSection(d),
              RecentActivity(d),
            ]);
            return ListView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(side, 12, side, 130),
              children: [
                const OverviewHeader().rise(),
                const SizedBox(height: 20),
                if (wide)
                  TwoPane(
                    leftWidth: 420,
                    left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const DeckSection(peek: .5, visible: 2).rise(1), feed]),
                    right: summary,
                  )
                else ...[
                  summary,
                  const SectionHeader('Your cards'),
                  const DeckSection(peek: .5, visible: 2).rise(2),
                  feed,
                ],
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
