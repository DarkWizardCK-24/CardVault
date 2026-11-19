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

/// The six top-level destinations.
const kDestinations = [
  NavDest(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Overview'),
  NavDest(Icons.credit_card_outlined, Icons.credit_card_rounded, 'Card Vault'),
  NavDest(Icons.calculate_outlined, Icons.calculate_rounded, 'Tools'),
  NavDest(Icons.card_giftcard_outlined, Icons.card_giftcard_rounded, 'Benefits'),
  NavDest(Icons.folder_open_outlined, Icons.folder_rounded, 'Documents'),
  NavDest(Icons.shield_outlined, Icons.shield_rounded, 'Security'),
];

/// Floating glass bottom bar used on phones and narrow windows.
class BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Glass(
                radius: 28,
                padding: const EdgeInsets.all(8),
                tint: [C.charcoal.withValues(alpha: .94), C.graphite.withValues(alpha: .94)],
                child: Row(children: [
                  for (var n = 0; n < kDestinations.length; n++)
                    Expanded(
                      flex: n == index ? 22 : 10,
                      child: Semantics(
                        button: true,
                        selected: n == index,
                        label: kDestinations[n].label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(n);
                          },
                          child: AnimatedContainer(
                            duration: 380.ms,
                            curve: Curves.easeOutBack,
                            height: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(gradient: n == index ? C.goldGradient : null, borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(n == index ? kDestinations[n].activeIcon : kDestinations[n].icon, size: 21, color: n == index ? C.obsidian : C.muted),
                              if (n == index)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text(kDestinations[n].label.split(' ').first,
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            softWrap: false,
                                            style: const TextStyle(color: C.obsidian, fontSize: 11.5, fontWeight: FontWeight.w800))
                                        .animate()
                                        .fadeIn(delay: 120.ms, duration: 220.ms),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      );
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
