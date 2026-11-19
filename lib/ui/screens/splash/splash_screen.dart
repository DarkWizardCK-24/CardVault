import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: AmbientBackground(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CvLogo(size: 110)
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .scale(begin: const Offset(.6, .6), duration: 900.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1200.ms, color: C.gold.withValues(alpha: .6)),
              const SizedBox(height: 26),
              Text('CardVault', style: T.display(38)).animate(delay: 350.ms).fadeIn(duration: 700.ms).slideY(begin: .3, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text('PRIVATE · OFFLINE · SECURE', style: T.caption.copyWith(letterSpacing: 3, color: C.gold))
                  .animate(delay: 700.ms).fadeIn(duration: 800.ms),
            ]),
          ),
        ),
      );
}

