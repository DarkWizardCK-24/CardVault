import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Wraps the whole app: inactivity auto-lock, lifecycle locking, and the
/// privacy cover that hides content in the app switcher.
class AppGuard extends ConsumerStatefulWidget {
  final Widget child;
  const AppGuard({super.key, required this.child});
  @override
  ConsumerState<AppGuard> createState() => _AppGuardState();
}

class _AppGuardState extends ConsumerState<AppGuard> with WidgetsBindingObserver {
  static const _secure = MethodChannel('cardvault/secure');
  Timer? _idle;
  bool _covered = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setSecure(true);
  }

  Future<void> _setSecure(bool on) async {
    try {
      await _secure.invokeMethod('setSecure', on); // Android FLAG_SECURE: blocks screenshots/recents preview
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idle?.cancel();
    super.dispose();
  }

  int get _timeout => ref.read(dataProvider).settings.autoLockSeconds;

  void _bump() {
    _idle?.cancel();
    if (ref.read(authProvider).status != AuthStatus.unlocked || _timeout <= 0) return;
    _idle = Timer(Duration(seconds: _timeout), _lock);
  }

  void _lock() {
    ref.read(authProvider.notifier).lock();
    navKey.currentState?.popUntil((r) => r.isFirst);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.inactive || s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      // iOS app switcher snapshot is taken at `inactive` – cover immediately.
      setState(() => _covered = true);
      _pausedAt ??= DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      setState(() => _covered = false);
      final p = _pausedAt;
      _pausedAt = null;
      if (p != null && ref.read(authProvider).status == AuthStatus.unlocked) {
        final away = DateTime.now().difference(p).inSeconds;
        if (_timeout > 0 && away >= _timeout) _lock();
      }
      _bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, _) => _bump());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _bump(),
      child: Stack(children: [
        widget.child,
        IgnorePointer(
          ignoring: !_covered,
          child: AnimatedOpacity(
            opacity: _covered ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: C.obsidian,
                alignment: Alignment.center,
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_rounded, color: C.gold, size: 42),
                  SizedBox(height: 12),
                  Text('CardVault', style: TextStyle(color: C.text, fontSize: 20, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

