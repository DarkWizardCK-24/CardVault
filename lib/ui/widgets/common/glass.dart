import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardvault/core/core.dart';

/// Frosted glass surface.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final List<Color>? tint;
  const Glass(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 22,
      this.onTap,
      this.tint});
  @override
  Widget build(BuildContext context) {
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: C.border),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: tint ??
                    [Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .025)]),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, child: box);
  }
}

/// Spring-scale press feedback.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = .97});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false, _hover = false;
  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : (_hover && interactive ? 1.012 : 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _hover && interactive && !_down ? .94 : 1,
            duration: const Duration(milliseconds: 140),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// App-wide ambient background: deep obsidian with soft gold, violet and teal blooms.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0C12), C.obsidian, Color(0xFF07080B)]),
            ),
          ),
        ),
        Positioned(top: -160, right: -120, child: _glow(C.gold.withValues(alpha: .16), 420)),
        Positioned(top: 220, left: -200, child: _glow(C.violet.withValues(alpha: .13), 420)),
        Positioned(bottom: -200, right: -140, child: _glow(C.teal.withValues(alpha: .10), 460)),
        Positioned.fill(child: child),
      ]);
  Widget _glow(Color c, double s) => IgnorePointer(
        child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [c, Colors.transparent]))),
      );
}
