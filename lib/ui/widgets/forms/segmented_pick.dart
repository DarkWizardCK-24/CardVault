import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';

class SegmentedPick extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentedPick(this.items, this.index, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.charcoal, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: 250.ms, height: 40, alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: i == index ? C.goldGradient : null, borderRadius: BorderRadius.circular(12)),
                  child: Text(items[i], style: T.h3.copyWith(color: i == index ? C.obsidian : C.muted, fontSize: 14)),
                ),
              ),
            ),
        ]),
      );
}

