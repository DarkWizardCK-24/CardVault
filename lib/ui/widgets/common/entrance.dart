import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade + rise entrance used across screens. [i] staggers siblings.
extension Entrance on Widget {
  Widget rise([int i = 0]) => animate(delay: (60 * i).ms)
      .fadeIn(duration: 420.ms, curve: Curves.easeOut)
      .slideY(begin: .08, end: 0, duration: 520.ms, curve: Curves.easeOutCubic);
}

