import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';

class Progress extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;
  const Progress(this.value, {super.key, this.color, this.height = 8});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(children: [
          Container(height: height, color: Colors.white.withValues(alpha: .08)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)), duration: 900.ms, curve: Curves.easeOutCubic,
            builder: (_, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(height: height, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color ?? C.gold, (color ?? C.gold).withValues(alpha: .6)]),
                  borderRadius: BorderRadius.circular(height))),
            ),
          ),
        ]),
      );
}

