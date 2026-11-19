import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';

/// Asks for the backup password. When [confirmIt] is true the user must type it twice and
/// it must be at least 8 characters.
Future<String?> askBackupPassword(BuildContext context, String title, {bool confirmIt = false, String? message}) {
  final a = TextEditingController(), b = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (message != null) ...[Text(message, style: T.muted), const SizedBox(height: 14)],
          TextField(controller: a, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Backup password')),
          if (confirmIt) ...[
            const SizedBox(height: 10),
            TextField(controller: b, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Confirm password')),
          ],
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: T.muted.copyWith(color: C.bad))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: C.muted))),
          TextButton(
            onPressed: () {
              if (confirmIt && a.text.length < 8) return set(() => error = 'Use at least 8 characters');
              if (confirmIt && a.text != b.text) return set(() => error = 'Passwords do not match');
              if (a.text.isEmpty) return set(() => error = 'Enter the password');
              Navigator.pop(c, a.text);
            },
            child: const Text('Continue', style: TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
