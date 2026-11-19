import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ======================================================================= lock
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockState();
}

class _LockState extends ConsumerState<LockScreen> {
  final pw = TextEditingController();
  bool busy = false, hide = true;
  String? error;
  Timer? _t;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final left = await ref.read(vaultServiceProvider).lockRemaining();
      if (left != null) _countdown(left);
      if (ref.read(authProvider).bioReady && left == null) bioUnlock();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    pw.dispose();
    super.dispose();
  }

  void _countdown(Duration d) {
    _t?.cancel();
    setState(() => _left = d.inSeconds + 1);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        setState(() => error = null);
      }
    });
  }

  Future<void> bioUnlock() async {
    final ok = await ref.read(authProvider.notifier).unlockWithBiometrics();
    if (!ok && mounted) setState(() => error = null);
  }

  Future<void> submit() async {
    if (pw.text.isEmpty || _left > 0) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(authProvider.notifier).unlockWithPassword(pw.text);
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      pw.clear();
      setState(() => error = e.message);
      if (e.lockedFor != null) _countdown(e.lockedFor!);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bio = ref.watch(authProvider).bioReady;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(children: [
                  Image.asset('assets/images/shield.png', height: 130, filterQuality: FilterQuality.high).rise(0),
                  const SizedBox(height: 22),
                  Text('Vault locked', style: T.display(34)).rise(1),
                  const SizedBox(height: 6),
                  Text('Enter your master password to continue', style: T.muted).rise(2),
                  const SizedBox(height: 28),
                  TextField(
                    controller: pw, obscureText: hide, autocorrect: false, enableSuggestions: false, enabled: _left <= 0,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Master password', prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => hide = !hide)),
                    ),
                  ).rise(3),
                  if (_left > 0)
                    Padding(padding: const EdgeInsets.only(top: 12), child: Text('Too many attempts · retry in ${_left}s', style: T.muted.copyWith(color: C.warn)))
                  else if (error != null)
                    Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: T.muted.copyWith(color: C.bad)).animate().shakeX(amount: 6, duration: 400.ms)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: GoldButton('Unlock', busy: busy, onTap: _left > 0 ? null : submit)),
                    if (bio) ...[
                      const SizedBox(width: 12),
                      Pressable(
                        onTap: bioUnlock,
                        child: Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: C.gold.withValues(alpha: .6))),
                          child: const Icon(Icons.fingerprint_rounded, color: C.gold, size: 28),
                        ),
                      ),
                    ],
                  ]).rise(4),
                  const SizedBox(height: 14),
                  TextButton(onPressed: () => sheet(context, const RecoverSheet()), child: Text('Use recovery code', style: T.muted.copyWith(color: C.silver))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

