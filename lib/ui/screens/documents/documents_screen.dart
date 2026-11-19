import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String q = '';
  int f = 0;
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final types = ['All', ...kDocTypes.take(7)];
    final list = d.docs.where((x) => (f == 0 || x.type == types[f]) && (q.isEmpty || '${x.name} ${x.text} ${x.type} ${x.fileName}'.toLowerCase().contains(q.toLowerCase()))).toList()
      ..sort((a, b) => b.added.compareTo(a.added));
    return Screen(
      title: 'Documents', subtitle: 'Encrypted on this device',
      actions: [IconPill(Icons.emergency_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectoryScreen())), tooltip: 'Bank directory & emergency')],
      children: [
        Glass(child: Row(children: [
          const IconBadge(Icons.enhanced_encryption_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text('Files are AES-256 encrypted and kept in app-private storage — never in your gallery or Downloads.', style: T.muted)),
        ])).rise(),
        const SizedBox(height: 14),
        TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(hintText: 'Search names & text…', prefixIcon: Icon(Icons.search_rounded, size: 20))),
        const SizedBox(height: 12),
        ChipBar(items: types, index: f, onChanged: (i) => setState(() => f = i)),
        const SizedBox(height: 14),
        if (list.isEmpty)
          EmptyState(icon: Icons.folder_open_rounded, title: 'No documents', message: 'Import statements, agreements and receipts as PDFs or images.', action: 'Import', onAction: () => importDocument(context, ref))
        else
          for (final (i, x) in list.indexed) DocRow(x).rise(i.clamp(0, 6)),
      ],
    );
  }
}

