import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = C.silver});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: T.caption.copyWith(color: color, letterSpacing: .2, fontSize: 11)),
      );
}

class ChipBar extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  const ChipBar({super.key, required this.items, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal, clipBehavior: Clip.hardEdge,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final on = i == index;
            return Pressable(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: 260.ms, curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on ? C.goldGradient : null,
                  color: on ? null : Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? Colors.transparent : C.border),
                ),
                child: Text(items[i], style: T.caption.copyWith(color: on ? C.obsidian : C.text, fontSize: 12.5, letterSpacing: .1, fontWeight: FontWeight.w700)),
              ),
            );
          },
        ),
      );
}

