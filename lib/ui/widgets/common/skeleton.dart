import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';

class Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 12});
  @override
  Widget build(BuildContext context) => Container(
        height: height, width: width,
        decoration: BoxDecoration(color: C.charcoal, borderRadius: BorderRadius.circular(radius)),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: .08));
}

