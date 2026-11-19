import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final st = d.settings;
    final n = ref.read(dataProvider.notifier);
    final svc = ref.read(vaultServiceProvider);
    const timeouts = {'Immediately': 1, '30 seconds': 30, '1 minute': 60, '5 minutes': 300, '15 minutes': 900, 'Never': 0};
    final tLabel = timeouts.entries.firstWhere((e) => e.value == st.autoLockSeconds, orElse: () => const MapEntry('1 minute', 60)).key;

    return Screen(title: 'Security', subtitle: 'Your vault, your keys', children: [
      Glass(
        tint: [C.good.withValues(alpha: .14), C.good.withValues(alpha: .03)],
        child: Row(children: [
          const Icon(Icons.verified_user_rounded, color: C.good, size: 34), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vault protected', style: T.h2),
            Text('AES-256 encrypted database · key held in the OS Keychain/Keystore · no network access', style: T.muted),
          ])),
        ]),
      ).rise(),
      const SectionHeader('Unlock'),
      Glass(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Column(children: [
        SwitchListTile(
          title: Text('Biometric unlock', style: T.body), subtitle: Text('Face ID / fingerprint', style: T.muted), value: st.biometrics,
          onChanged: (v) async {
            if (v) {
              if (!await svc.biometricsAvailable()) {
                if (context.mounted) toast(context, 'No biometrics enrolled on this device');
                return;
              }
              final ok = await svc.enableBiometrics(ref.read(authProvider.notifier).rootKey!);
              if (!ok) return;
            } else {
              await svc.disableBiometrics();
            }
            st.biometrics = v;
            await n.saveSettings(st);
          },
        ),
        ListTile(
          title: Text('Auto-lock', style: T.body), subtitle: Text('After $tLabel of inactivity', style: T.muted), trailing: const Icon(Icons.chevron_right_rounded, color: C.muted),
          onTap: () async {
            final v = await sheet<int>(context, SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final e in timeouts.entries) ListTile(title: Text(e.key), trailing: st.autoLockSeconds == e.value ? const Icon(Icons.check_rounded, color: C.gold) : null, onTap: () => Navigator.pop(context, e.value)),
            ])));
            if (v != null) {
              st.autoLockSeconds = v;
              await n.saveSettings(st);
            }
          },
        ),
        ListTile(title: Text('Change master password', style: T.body), trailing: const Icon(Icons.chevron_right_rounded, color: C.muted), onTap: () => _changePassword(context, ref)),
        ListTile(title: Text('New recovery code', style: T.body), subtitle: Text('Invalidates the old one', style: T.muted), trailing: const Icon(Icons.chevron_right_rounded, color: C.muted), onTap: () => _newRecovery(context, ref)),
      ])).rise(1),
      const SectionHeader('Privacy'),
      Glass(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Column(children: [
        SwitchListTile(title: Text('Hide expiry on card faces', style: T.body), value: st.hideExpiryOnDeck, onChanged: (v) async {
          st.hideExpiryOnDeck = v;
          for (final c in d.cards) {
            c.showExpiry = !v;
            await n.saveCard(c);
          }
          await n.saveSettings(st);
        }),
        const ListTile(leading: Icon(Icons.visibility_off_outlined, color: C.silver), title: Text('App-switcher preview hidden'), subtitle: Text('Content is covered when the app is backgrounded')),
        const ListTile(leading: Icon(Icons.content_paste_off_outlined, color: C.silver), title: Text('Clipboard clears after 30s'), subtitle: Text('Applies to every copied detail')),
        const ListTile(leading: Icon(Icons.fingerprint_rounded, color: C.silver), title: Text('Secrets need re-authentication'), subtitle: Text('Card number, CVV, PIN and secret notes are revealed only after Face ID / fingerprint or your master password')),
      ])).rise(2),
      const SizedBox(height: 14),
      Text('Encryption protects data at rest. It cannot protect a device that is already compromised (malware, jailbreak/root) — keep your OS updated and your device locked.', style: T.caption),
    ]);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final cur = TextEditingController(), nw = TextEditingController();
    String? err;
    await sheet(context, StatefulBuilder(builder: (ctx, set) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Change master password', style: T.h1), const SizedBox(height: 14),
        TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), const SizedBox(height: 12),
        TextField(controller: nw, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: T.muted.copyWith(color: C.bad))),
        const SizedBox(height: 16),
        GoldButton('Update password', onTap: () async {
          final svc = ref.read(vaultServiceProvider);
          try {
            await svc.unlockWithPassword(cur.text);
            await svc.changePassword(ref.read(authProvider.notifier).rootKey!, nw.text);
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) toast(context, 'Master password updated');
          } on AuthFailure catch (e) {
            set(() => err = e.message);
          }
        }),
      ]),
    )));
  }

  Future<void> _newRecovery(BuildContext context, WidgetRef ref) async {
    if (!await confirm(context, 'Generate new recovery code?', 'Your previous recovery code will stop working.', action: 'Generate')) return;
    final code = await ref.read(vaultServiceProvider).regenerateRecovery(ref.read(authProvider.notifier).rootKey!);
    if (!context.mounted) return;
    await showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: const Text('New recovery code'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Write it down now. It will not be shown again.', style: T.muted), const SizedBox(height: 14),
        SelectableText(code, textAlign: TextAlign.center, style: T.num(20, c: C.gold).copyWith(letterSpacing: 1.2, height: 1.6)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('I saved it', style: TextStyle(color: C.gold)))],
    ));
  }
}

