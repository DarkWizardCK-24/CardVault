import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class QuickFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Icon-only circle (phones) so it never hides list content; full pill on wide layouts.
  final bool compact;
  const QuickFab({super.key, required this.label, required this.icon, required this.onTap, this.compact = false});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Pressable(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Container(
              height: compact ? 58 : 52,
              width: compact ? 58 : null,
              padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: C.goldGradient,
                borderRadius: BorderRadius.circular(29),
                boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .38), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: compact
                  ? Icon(icon, color: C.obsidian, size: 26)
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, color: C.obsidian, size: 22),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(color: C.obsidian, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
            ),
          ),
        ),
      ).animate().scale(begin: const Offset(.6, .6), duration: 450.ms, curve: Curves.easeOutBack).fadeIn();
}
