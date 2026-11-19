import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ----------------------------------------------------------------- shared helpers
/// Step-up authentication before showing sensitive details.
Future<bool> stepUpAuth(BuildContext context, WidgetRef ref) async {
  final svc = ref.read(vaultServiceProvider);
  if (await svc.hasBiometricKey() && await svc.reauthenticate()) return true;
  if (!context.mounted) return false;
  final ctl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Confirm it’s you'),
      content: TextField(controller: ctl, obscureText: true, autofocus: true, autocorrect: false, decoration: const InputDecoration(labelText: 'Master password')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: C.muted))),
        TextButton(
          onPressed: () async {
            final good = await svc.reauthenticate(password: ctl.text);
            if (c.mounted) Navigator.pop(c, good);
          },
          child: const Text('Reveal', style: TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  ctl.dispose();
  return ok ?? false;
}

/// Copies text and clears the clipboard after 30 seconds.
void copySensitive(BuildContext context, String text, {String label = 'Copied'}) {
  Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.selectionClick();
  Timer(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
  toast(context, '$label · clipboard clears in 30s');
}

