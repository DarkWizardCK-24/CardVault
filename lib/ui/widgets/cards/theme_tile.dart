import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class ThemeTile extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;
  const ThemeTile({super.key, required this.selected, required this.label, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 220.ms, width: 104, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? C.gold.withValues(alpha: .12) : Colors.white.withValues(alpha: .04),
            border: Border.all(color: selected ? C.gold : C.border, width: selected ? 1.5 : 1),
          ),
          child: Column(children: [
            Expanded(child: SizedBox.expand(child: child)),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.caption.copyWith(color: selected ? C.gold : C.muted, fontSize: 11)),
          ]),
        ),
      );
}

