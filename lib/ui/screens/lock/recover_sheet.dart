import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class RecoverSheet extends ConsumerStatefulWidget {
  const RecoverSheet({super.key});
  @override
  ConsumerState<RecoverSheet> createState() => _RecoverState();
}

class _RecoverState extends ConsumerState<RecoverSheet> {
  final code = TextEditingController(), pw = TextEditingController();
  String? error;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Recover access', style: T.h1),
          const SizedBox(height: 6),
          Text('Your data stays encrypted. The recovery code unlocks it and you will set a new master password.', style: T.muted),
          const SizedBox(height: 16),
          TextField(controller: code, textCapitalization: TextCapitalization.characters, autocorrect: false, decoration: const InputDecoration(labelText: 'Recovery code')),
          const SizedBox(height: 12),
          TextField(controller: pw, obscureText: true, autocorrect: false, decoration: const InputDecoration(labelText: 'New master password')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: T.muted.copyWith(color: C.bad))),
          const SizedBox(height: 18),
          GoldButton('Recover vault', busy: busy, onTap: () async {
            setState(() {
              busy = true;
              error = null;
            });
            try {
              await ref.read(authProvider.notifier).recover(code.text, pw.text);
              if (mounted) Navigator.pop(context);
            } on AuthFailure catch (e) {
              setState(() => error = e.message);
            } finally {
              if (mounted) setState(() => busy = false);
            }
          }),
        ]),
      );
}

