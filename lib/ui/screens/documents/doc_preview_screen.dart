import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class DocPreviewScreen extends ConsumerStatefulWidget {
  final String id;
  const DocPreviewScreen(this.id, {super.key});
  @override
  ConsumerState<DocPreviewScreen> createState() => _DocPreviewScreenState();
}

class _DocPreviewScreenState extends ConsumerState<DocPreviewScreen> {
  Uint8List? bytes;
  PdfController? pdf;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = ref.read(dataProvider).docs.where((d) => d.id == widget.id).firstOrNull;
    if (doc == null) return;
    try {
      final b = await docService(ref).read(doc.id);
      if (doc.mime == 'application/pdf') pdf = PdfController(document: PdfDocument.openData(b));
      if (mounted) setState(() => bytes = b);
    } catch (_) {
      if (mounted) setState(() => error = 'This document could not be decrypted.');
    }
  }

  @override
  void dispose() {
    pdf?.dispose();
    bytes = null; // drop plaintext reference
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(dataProvider).docs.where((d) => d.id == widget.id).firstOrNull;
    if (doc == null) return const Scaffold(body: SizedBox());
    Widget body;
    if (error != null) {
      body = Center(child: Text(error!, style: T.muted));
    } else if (bytes == null) {
      body = const Padding(padding: EdgeInsets.all(20), child: Column(children: [Skeleton(height: 420, radius: 20), SizedBox(height: 14), Skeleton(height: 16), SizedBox(height: 10), Skeleton(height: 16, width: 180)]));
    } else if (pdf != null) {
      body = PdfView(controller: pdf!, backgroundDecoration: const BoxDecoration(color: C.obsidian));
    } else if (doc.mime.startsWith('image')) {
      body = InteractiveViewer(child: Center(child: Image.memory(bytes!)));
    } else {
      body = SingleChildScrollView(padding: const EdgeInsets.all(20), child: SelectableText(utf8.decode(bytes!, allowMalformed: true), style: T.body));
    }
    return Scaffold(
      appBar: AppBar(title: Text(doc.name, maxLines: 1), actions: [
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.bad), onPressed: () async {
          if (await confirm(context, 'Delete document?', 'The encrypted file is overwritten and removed from this device. This cannot be undone.', action: 'Delete securely', danger: true)) {
            await docService(ref).secureDelete(doc.id);
            await ref.read(dataProvider.notifier).deleteDoc(doc.id);
            if (context.mounted) Navigator.pop(context);
          }
        }),
      ]),
      body: AmbientBackground(child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: Row(children: [Tag(doc.type, color: C.gold), const SizedBox(width: 8), Tag(dShort(doc.added)), const SizedBox(width: 8), const Tag('Decrypted in memory only', color: C.good)])),
        Expanded(child: body),
      ]))),
    );
  }
}

