import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class NavDest {
  final IconData icon, activeIcon;
  final String label;
  const NavDest(this.icon, this.activeIcon, this.label);
}

/// The five top-level destinations.
const kDestinations = [
  NavDest(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Home'),
  NavDest(Icons.credit_card_outlined, Icons.credit_card_rounded, 'Cards'),
  NavDest(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendar'),
  NavDest(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Money'),
  NavDest(Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
];

/// Floating glass bottom bar for phones: equal-width items, always-visible labels and a
/// gradient indicator that glides to the selected tab.
class BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = kDestinations.length;
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 30, offset: const Offset(0, 12)),
                  BoxShadow(color: C.violet.withValues(alpha: .10), blurRadius: 40, spreadRadius: -6),
                ],
              ),
              child: Glass(
                radius: 30,
                padding: const EdgeInsets.all(6),
                tint: [const Color(0xFF1C1F2A).withValues(alpha: .92), const Color(0xFF12141B).withValues(alpha: .95)],
                child: SizedBox(
                  height: 60,
                  child: Stack(children: [
                    // sliding gradient indicator
                    AnimatedAlign(
                      duration: 420.ms,
                      curve: Curves.easeOutBack,
                      alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / n,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(colors: [C.gold.withValues(alpha: .26), C.violet.withValues(alpha: .18)]),
                              border: Border.all(color: C.gold.withValues(alpha: .45)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == index,
                            label: kDestinations[i].label,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(i);
                              },
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                AnimatedScale(
                                  scale: i == index ? 1.12 : 1,
                                  duration: 300.ms,
                                  curve: Curves.easeOutBack,
                                  child: i == index
                                      ? ShaderMask(
                                          shaderCallback: (r) => C.goldGradient.createShader(r),
                                          child: Icon(kDestinations[i].activeIcon, size: 23, color: Colors.white),
                                        )
                                      : Icon(kDestinations[i].icon, size: 22, color: C.muted),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: 250.ms,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10.5,
                                    letterSpacing: .2,
                                    fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                                    color: i == index ? C.gold : C.muted,
                                  ),
                                  child: Text(kDestinations[i].label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                                ),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical navigation rail for tablets, desktop and web. Shows labels when [extended].
class SideRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onLock;
  final bool extended;
  const SideRail({super.key, required this.index, required this.onTap, required this.onLock, this.extended = true});

  @override
  Widget build(BuildContext context) => Container(
        width: extended ? 232 : 84,
        margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
        child: Glass(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          tint: [C.charcoal.withValues(alpha: .96), C.graphite.withValues(alpha: .96)],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
              if (extended) const SizedBox(width: 6),
              const CvLogo(size: 40),
              if (extended) ...[
                const SizedBox(width: 12),
                Text('CardVault', style: T.display(21)),
              ],
            ]),
            const SizedBox(height: 26),
            for (var n = 0; n < kDestinations.length; n++) _RailItem(dest: kDestinations[n], selected: n == index, extended: extended, onTap: () => onTap(n)),
            const Spacer(),
            Container(height: 1, color: C.border, margin: const EdgeInsets.symmetric(vertical: 12)),
            _RailItem(dest: const NavDest(Icons.lock_outline_rounded, Icons.lock_rounded, 'Lock vault'), selected: false, extended: extended, onTap: onLock),
            if (extended)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Row(children: [
                  const Icon(Icons.wifi_off_rounded, size: 14, color: C.good),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Offline · encrypted', style: T.caption.copyWith(color: C.good))),
                ]),
              ),
          ]),
        ),
      );
}

class _RailItem extends StatelessWidget {
  final NavDest dest;
  final bool selected, extended;
  final VoidCallback onTap;
  const _RailItem({required this.dest, required this.selected, required this.extended, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: dest.label,
          child: Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: AnimatedContainer(
              duration: 300.ms,
              curve: Curves.easeOutCubic,
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
              decoration: BoxDecoration(
                gradient: selected ? C.goldGradient : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                Icon(selected ? dest.activeIcon : dest.icon, size: 22, color: selected ? C.obsidian : C.muted),
                if (extended) ...[
                  const SizedBox(width: 14),
                  Text(dest.label, style: T.h3.copyWith(fontSize: 14.5, color: selected ? C.obsidian : C.text)),
                ],
              ]),
            ),
          ),
        ),
      );
}
