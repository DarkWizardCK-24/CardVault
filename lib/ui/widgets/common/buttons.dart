import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;
  final bool outline;
  const GoldButton(this.label, {super.key, this.icon, this.onTap, this.busy = false, this.outline = false});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: busy ? null : () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Container(
          height: 54, alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: outline ? null : C.goldGradient,
            borderRadius: BorderRadius.circular(18),
            border: outline ? Border.all(color: C.gold.withValues(alpha: .6)) : null,
            boxShadow: outline ? null : [BoxShadow(color: C.gold.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: C.obsidian))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: outline ? C.gold : C.obsidian), const SizedBox(width: 8)],
                  Text(label, style: T.h3.copyWith(color: outline ? C.gold : C.obsidian)),
                ]),
        ),
      );
}

class IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;
  const IconPill(this.icon, this.onTap, {super.key, this.tooltip, this.active = false});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: active ? C.gold.withValues(alpha: .16) : Colors.white.withValues(alpha: .06),
              shape: BoxShape.circle,
              border: Border.all(color: active ? C.gold.withValues(alpha: .6) : C.border),
            ),
            child: Icon(icon, size: 20, color: active ? C.gold : C.text),
          ),
        ),
      );
}

