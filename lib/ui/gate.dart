import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';

/// Chooses splash / setup / lock / app.
class Gate extends ConsumerStatefulWidget {
  const Gate({super.key});
  @override
  ConsumerState<Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<Gate> {
  @override
  void initState() {
    super.initState();
    Future.wait([ref.read(authProvider.notifier).boot(), Future.delayed(const Duration(milliseconds: 1900))]);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(authProvider).status;
    final w = switch (s) {
      AuthStatus.booting => const SplashScreen(key: ValueKey('splash')),
      AuthStatus.needsSetup => const SetupScreen(key: ValueKey('setup')),
      AuthStatus.locked => const LockScreen(key: ValueKey('lock')),
      AuthStatus.unlocked => const ShellScreen(key: ValueKey('shell')),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .985, end: 1.0).animate(a), child: c)),
      child: w,
    );
  }
}

