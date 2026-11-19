import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ===================================================================== setup
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupState();
}

class _SetupState extends ConsumerState<SetupScreen> {
  int step = 0;
  final pw = TextEditingController(), pw2 = TextEditingController();
  bool bio = true, busy = false, saved = false, hide = true;
  String? error, recovery;
  BackupPayload? restore; // set when the user is restoring a backup onto this device

  double get strength {
    final p = pw.text;
    var s = 0.0;
    if (p.length >= 8) s += .3;
    if (p.length >= 12) s += .2;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s += .15;
    if (RegExp(r'[0-9]').hasMatch(p)) s += .15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s += .2;
    return s.clamp(0, 1);
  }

  Future<void> pickBackup() async {
    final f = await FilePicker.pickFile();
    if (f == null || !mounted) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final pwd = await askBackupPassword(context, 'Backup password', message: 'Enter the password you chose when you exported this backup.');
    if (pwd == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final payload = await BackupService.open(bytes, pwd);
      setState(() {
        restore = payload;
        step = 1;
      });
    } on AuthFailure catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    final e = VaultService.validatePassword(pw.text);
    if (e != null) return setState(() => error = e);
    if (pw.text != pw2.text) return setState(() => error = 'Passwords do not match');
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final code = await ref.read(authProvider.notifier).setup(pw.text, biometrics: bio);
      setState(() {
        recovery = code;
        step = 2;
      });
    } on AuthFailure catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_welcome(), _password(), _recovery()];
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [for (var i = 0; i < 3; i++) Expanded(child: AnimatedContainer(
                    duration: 400.ms, height: 3, margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: i <= step ? C.gold : Colors.white12, borderRadius: BorderRadius.circular(3))))]),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: 450.ms, switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(a), child: c)),
                      child: KeyedSubtree(key: ValueKey(step), child: pages[step]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() => Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Center(child: Image.asset('assets/images/hero_cards.png', height: 200, fit: BoxFit.contain)).rise(0),
        const SizedBox(height: 14),
        Text('Your cards,\nprivately held.', style: T.display(40)).rise(1),
        const SizedBox(height: 14),
        Text('CardVault keeps everything on this device, in an encrypted vault. No accounts, no cloud, no internet.', style: T.muted.copyWith(fontSize: 15)).rise(2),
        const SizedBox(height: 22),
        for (final (i, t) in [
          (Icons.lock_outline_rounded, 'AES-256 encrypted database (SQLCipher)'),
          (Icons.visibility_off_outlined, 'CVV, PIN & OTP are never stored'),
          (Icons.wifi_off_rounded, 'Works fully offline, zero telemetry'),
        ].indexed)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(t.$1, color: C.gold, size: 20), const SizedBox(width: 12), Expanded(child: Text(t.$2, style: T.body))]).rise(3 + i)),
        const SizedBox(height: 28),
        GoldButton('Create my vault', icon: Icons.arrow_forward_rounded, onTap: () => setState(() => step = 1)).rise(6),
        const SizedBox(height: 12),
        GoldButton('Restore from a backup', icon: Icons.settings_backup_restore_rounded, outline: true, busy: busy, onTap: pickBackup).rise(7),
        const SizedBox(height: 12),
      ])));

  Widget _password() => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          if (restore != null) ...[
            Glass(
              tint: [C.good.withValues(alpha: .14), C.good.withValues(alpha: .03)],
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded, color: C.good),
                const SizedBox(width: 12),
                Expanded(child: Text('Backup unlocked: ${restore!.summary}. Choose a master password for this device.', style: T.body)),
              ]),
            ),
            const SizedBox(height: 18),
          ],
          Text('Master password', style: T.display(32)),
          const SizedBox(height: 8),
          Text('It protects the key to your vault. It is never stored or sent anywhere — if you forget it, only your recovery code can restore access.', style: T.muted),
          const SizedBox(height: 24),
          TextField(controller: pw, obscureText: hide, onChanged: (_) => setState(() {}), autocorrect: false, enableSuggestions: false,
              decoration: InputDecoration(labelText: 'Master password', suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => hide = !hide)))),
          const SizedBox(height: 10),
          Progress(strength, color: strength < .5 ? C.bad : (strength < .8 ? C.warn : C.good), height: 5),
          const SizedBox(height: 14),
          TextField(controller: pw2, obscureText: hide, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Confirm password')),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero, value: bio, onChanged: (v) => setState(() => bio = v),
            title: Text('Enable Face ID / fingerprint', style: T.body), subtitle: Text('Key is released by the OS Keychain / Keystore after biometrics.', style: T.muted),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error!, style: T.muted.copyWith(color: C.bad))),
          const SizedBox(height: 18),
          GoldButton('Continue', busy: busy, onTap: create),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: () => setState(() => step = 0), child: Text('Back', style: T.muted))),
        ]),
      );

  Widget _recovery() => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),
          const Icon(Icons.key_rounded, color: C.gold, size: 34).rise(0),
          const SizedBox(height: 14),
          Text('Your recovery code', style: T.display(32)).rise(1),
          const SizedBox(height: 8),
          Text('Write this down and keep it somewhere safe and offline. It is shown only once. Without it, a forgotten master password means the data cannot be recovered — by design.', style: T.muted).rise(2),
          const SizedBox(height: 22),
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              SelectableText(recovery ?? '', textAlign: TextAlign.center, style: T.num(22, c: C.gold).copyWith(letterSpacing: 1.5, height: 1.6)),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Copy (clears in 30s)'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recovery!));
                  Timer(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
                  toast(context, 'Copied — clipboard clears in 30 seconds');
                },
              ),
            ]),
          ).rise(3),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, activeColor: C.gold, checkColor: C.obsidian,
            value: saved, onChanged: (v) => setState(() => saved = v ?? false),
            title: Text('I have saved my recovery code', style: T.body),
          ),
          const SizedBox(height: 14),
          GoldButton('Open my vault', icon: Icons.lock_open_rounded, onTap: saved ? () => ref.read(authProvider.notifier).finishSetup(restore: restore) : null),
        ]),
      );
}

