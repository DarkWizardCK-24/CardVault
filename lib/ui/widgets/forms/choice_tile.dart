import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class ChoiceTile extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback tap;
  const ChoiceTile(this.label, this.on, this.tap, {super.key});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          tap();
        },
        child: AnimatedContainer(
          duration: 220.ms, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? C.gold.withValues(alpha: .18) : Colors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? C.gold : C.border, width: on ? 1.4 : 1),
          ),
          child: Text(label, style: T.body.copyWith(fontSize: 13, color: on ? C.gold : C.text, fontWeight: FontWeight.w600)),
        ),
      );
}

