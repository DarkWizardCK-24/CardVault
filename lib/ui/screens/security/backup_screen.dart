import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Encrypted export / import — the way to move to a new device or keep a safe copy.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool busy = false;

  Future<void> export() async {
    final pw = await askBackupPassword(context, 'Encrypt backup',
        confirmIt: true, message: 'Choose a password for this backup file. You will need it to restore — it cannot be recovered.');
    if (pw == null || !mounted) return;
    setState(() => busy = true);
    try {
      final svc = docService(ref);
      final d = ref.read(dataProvider);
      final docs = <String, Uint8List>{};
      for (final doc in d.docs) {
        try {
          docs[doc.id] = await svc.read(doc.id);
        } catch (_) {}
      }
      final bytes = await BackupService.build(data: ref.read(dataProvider.notifier).exportAll(), docs: docs, password: pw);
      final path = await FilePicker.saveFile(dialogTitle: 'Save encrypted backup', fileName: BackupService.fileName(), bytes: bytes);
      if (path != null) {
        final st = ref.read(dataProvider).settings..lastBackup = DateTime.now().toIso8601String();
        await ref.read(dataProvider.notifier).saveSettings(st);
        if (mounted) toast(context, 'Encrypted backup saved');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> import() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final pw = await askBackupPassword(context, 'Backup password');
    if (pw == null || !mounted) return;
    setState(() => busy = true);
    try {
      final payload = await BackupService.open(bytes, pw);
      if (!mounted) return;
      final ok = await confirm(context, 'Replace current data?', 'This backup holds ${payload.summary}.\n\nRestoring overwrites everything currently in this vault.', action: 'Restore', danger: true);
      if (!ok) return;
      final svc = docService(ref);
      await ref.read(dataProvider.notifier).importAll(payload.data);
      for (final e in payload.docs.entries) {
        await svc.save(e.key, e.value);
      }
      NotificationService.instance.sync(ref.read(dataProvider));
      if (mounted) toast(context, 'Backup restored');
    } on AuthFailure catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final last = d.settings.lastBackup == null ? null : DateTime.tryParse(d.settings.lastBackup!);
    return Screen(title: 'Backup & restore', subtitle: 'Encrypted files only', children: [
      Glass(
        tint: [C.gold.withValues(alpha: .14), C.gold.withValues(alpha: .03)],
        child: Row(children: [
          const IconBadge(Icons.enhanced_encryption_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(last == null ? 'No backup yet' : 'Last backup ${relDays(last)}', style: T.h3),
              Text('AES-256 encrypted with a password you choose. CardVault never uploads anything — you decide where the file goes.', style: T.muted),
            ]),
          ),
        ]),
      ).rise(),
      const SectionHeader('In your backup'),
      StatGrid(minTile: 130, tileHeight: 124, children: [
        StatTile('Cards', '${d.cards.length}', Icons.credit_card_rounded),
        StatTile('Documents', '${d.docs.length}', Icons.folder_rounded),
        StatTile('Transactions', '${d.txns.length}', Icons.receipt_long_outlined),
        StatTile('Benefits', '${d.benefits.length}', Icons.card_giftcard_rounded),
      ]).rise(1),
      const SizedBox(height: 18),
      GoldButton('Export encrypted backup', icon: Icons.upload_rounded, busy: busy, onTap: export).rise(2),
      const SizedBox(height: 12),
      GoldButton('Restore from backup', icon: Icons.download_rounded, outline: true, onTap: busy ? null : import).rise(3),
      const SectionHeader('Moving to a new device?'),
      for (final (i, s) in [
        'Export an encrypted backup here and copy the file to the new device (cloud drive, USB, AirDrop — it is useless without the password).',
        'Install CardVault on the new device. On the first screen choose “Restore from a backup”.',
        'Enter the backup password, then set a new master password for the new device. Cards, documents and settings come back exactly as they were.',
      ].indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 26, height: 26, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold.withValues(alpha: .6))),
              child: Text('${i + 1}', style: T.caption.copyWith(color: C.gold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(s, style: T.body)),
          ]),
        ),
      const SizedBox(height: 8),
      Text('Includes cards, benefits, transactions, payments, subscriptions, loans, goals, contacts and documents. Your master password and recovery code are never part of a backup.', style: T.caption),
    ]);
  }
}
