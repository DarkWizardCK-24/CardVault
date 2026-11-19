import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class DocRow extends ConsumerWidget {
  final DocItem doc;
  const DocRow(this.doc, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(dataProvider).card(doc.cardId);
    return ListRow(
      leading: IconBadge(docIcon(doc)), title: doc.name,
      subtitle: '${doc.type}${card != null ? ' · ${card.title}' : ''} · ${(doc.size / 1024).toStringAsFixed(0)} KB',
      trailing: const Icon(Icons.lock_outline_rounded, size: 16, color: C.muted),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocPreviewScreen(doc.id))),
    );
  }
}

