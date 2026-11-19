import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Responsive app shell: bottom bar on phones, side rail on tablets / desktop / web.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  static const _pages = [OverviewScreen(), CardsScreen(), ToolsScreen(), BenefitsScreen(), DocumentsScreen(), SecurityScreen()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(tabProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = Bp.isWide(width);
    void go(int n) => ref.read(tabProvider.notifier).set(n);

    final data = ref.watch(dataProvider);
    // The empty states already offer their own call to action, so the FAB only appears once there is content.
    final fab = switch (i) {
      1 when data.cards.isNotEmpty => ('Add card', Icons.add_card_rounded, () => openCardForm(context)),
      3 when data.benefits.isNotEmpty => ('Add benefit', Icons.add_rounded, () => addBenefit(context, ref)),
      4 when data.docs.isNotEmpty => ('Import', Icons.upload_file_rounded, () => importDocument(context, ref)),
      _ => null,
    };

    final body = AnimatedSwitcher(
      duration: 380.ms,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) =>
          FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .015), end: Offset.zero).animate(a), child: c)),
      child: KeyedSubtree(key: ValueKey(i), child: _pages[i]),
    );

    return Scaffold(
      extendBody: !useRail,
      body: useRail
          ? Row(children: [
              SideRail(index: i, onTap: go, onLock: () => ref.read(authProvider.notifier).lock(), extended: width >= 1180),
              Expanded(child: body),
            ])
          : body,
      floatingActionButton: fab == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: useRail ? 8 : 74),
              child: QuickFab(label: fab.$1, icon: fab.$2, onTap: fab.$3, compact: !useRail, key: ValueKey(fab.$1)),
            ),
      bottomNavigationBar: useRail ? null : BottomNavBar(index: i, onTap: go),
    );
  }
}
