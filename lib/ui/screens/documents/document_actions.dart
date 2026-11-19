import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

const kDocTypes = ['Statement', 'Welcome letter', 'Card agreement', 'Terms & conditions', 'Fee schedule', 'Benefit document', 'Purchase receipt', 'Other'];

DocumentService docService(WidgetRef ref) => DocumentService(ref.read(authProvider.notifier).rootKey!);

IconData docIcon(DocItem d) => d.mime.contains('pdf') ? Icons.picture_as_pdf_outlined : (d.mime.startsWith('image') ? Icons.image_outlined : Icons.description_outlined);

String _mime(String name) {
  final e = name.split('.').last.toLowerCase();
  return switch (e) { 'pdf' => 'application/pdf', 'png' => 'image/png', 'jpg' || 'jpeg' => 'image/jpeg', 'webp' => 'image/webp', 'txt' => 'text/plain', _ => 'application/octet-stream' };
}

Future<void> importDocument(BuildContext context, WidgetRef ref, {String? cardId}) async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt']);
  if (f == null) return;
  final Uint8List bytes;
  try {
    bytes = await f.readAsBytes();
  } catch (_) {
    if (context.mounted) toast(context, 'Could not read that file');
    return;
  }
  if (!context.mounted) return;
  final r = await formSheet(context, 'Import document', const [
    TextF('name', 'Document name', required: true),
    DropF('type', 'Type', kDocTypes),
    CardF('cardId', 'Assign to card'),
    TextF('text', 'Searchable text (optional)', multiline: true, hint: 'Paste key terms to make this findable'),
  ], initial: {'name': f.name.replaceAll(RegExp(r'\.[^.]+$'), ''), 'type': 'Other', 'cardId': cardId ?? ''}, save: 'Encrypt & save');
  if (r == null) return;
  final doc = DocItem(name: r['name'], type: r['type'] ?? 'Other', cardId: r['cardId'] ?? '', fileName: f.name, mime: _mime(f.name), size: bytes.length);
  doc.text = r['text'] ?? '';
  // Local text extraction for plain-text files (no network, no OCR service).
  if (doc.mime == 'text/plain') doc.text = '${doc.text} ${utf8.decode(bytes, allowMalformed: true)}'.trim();
  await docService(ref).save(doc.id, Uint8List.fromList(bytes));
  await ref.read(dataProvider.notifier).saveDoc(doc);
  await ref.read(dataProvider.notifier).log('Imported document ${doc.name}', 'doc');
  if (context.mounted) toast(context, 'Encrypted and stored in your vault');
}

