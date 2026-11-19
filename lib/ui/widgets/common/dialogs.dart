import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardvault/core/core.dart';

// ------------------------------------------------------------------ dialogs
Future<bool> confirm(BuildContext context, String title, String message, {String action = 'Confirm', bool danger = false}) async {
  HapticFeedback.mediumImpact();
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message, style: T.muted),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(action, style: TextStyle(color: danger ? C.bad : C.gold, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

Future<R?> sheet<R>(BuildContext context, Widget child, {bool full = false}) => showModalBottomSheet<R>(
      context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true,
      backgroundColor: C.graphite, constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: child),
    );

