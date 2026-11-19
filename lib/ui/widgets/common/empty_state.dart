import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
        child: Column(children: [
          if (action != null)
            // "create your first …" states get the illustrated card art
            Image.asset('assets/images/empty_vault.png', height: 150, fit: BoxFit.contain, filterQuality: FilterQuality.high)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -3, end: 3, duration: 2600.ms, curve: Curves.easeInOut)
          else
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [C.gold.withValues(alpha: .22), Colors.transparent])),
              child: Icon(icon, color: C.gold, size: 38),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(.94, .94), end: const Offset(1.05, 1.05), duration: 2200.ms, curve: Curves.easeInOut),
          const SizedBox(height: 16),
          Text(title, style: T.h2, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: T.muted, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), SizedBox(width: 220, child: GoldButton(action!, icon: Icons.add_rounded, onTap: onAction))],
        ]),
      ).rise();
}

