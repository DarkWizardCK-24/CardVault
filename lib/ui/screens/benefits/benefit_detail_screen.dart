import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class BenefitDetailScreen extends ConsumerWidget {
  final String id;
  const BenefitDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final b = d.benefits.where((x) => x.id == id).firstOrNull;
    if (b == null) return const Scaffold(body: SizedBox());
    final card = d.card(b.cardId);
    Widget kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: Text(k, style: T.muted)), Expanded(flex: 6, child: Text(v.isEmpty ? '—' : v, textAlign: TextAlign.end, style: T.body))]));
    return Screen(
      title: b.title, subtitle: b.category,
      actions: [IconPill(Icons.edit_outlined, () => addBenefit(context, ref, edit: b))],
      children: [
        if (b.usageLimit > 0)
          Glass(child: Column(children: [
            Text('${b.remaining}', style: T.display(54, c: C.gold)),
            Text('of ${b.usageLimit} uses remaining', style: T.muted),
            const SizedBox(height: 14),
            Progress(b.remaining / b.usageLimit),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GoldButton('Use one', icon: Icons.check_rounded, onTap: b.remaining > 0 ? () {
                HapticFeedback.mediumImpact();
                b.remaining--;
                ref.read(dataProvider.notifier).saveBenefit(b);
              } : null)),
              const SizedBox(width: 12),
              Expanded(child: GoldButton('Undo', icon: Icons.undo_rounded, outline: true, onTap: b.remaining < b.usageLimit ? () {
                b.remaining++;
                ref.read(dataProvider.notifier).saveBenefit(b);
              } : null)),
            ]),
          ])).rise(),
        const SectionHeader('Details'),
        Glass(child: Column(children: [
          kv('Card', card?.title ?? ''), kv('Valid until', b.validUntil == null ? '' : dShort(b.validUntil!)),
          kv('Reminder', b.reminder == null ? '' : dShort(b.reminder!)), kv('Description', b.description),
        ])).rise(1),
        if (b.terms.isNotEmpty) ...[const SectionHeader('Terms (your note)'), Glass(child: Text(b.terms, style: T.body))],
        if (b.notes.isNotEmpty) ...[const SectionHeader('Notes'), Glass(child: Text(b.notes, style: T.body))],
        const SizedBox(height: 20),
        GoldButton('Delete benefit', icon: Icons.delete_outline_rounded, outline: true, onTap: () async {
          if (await confirm(context, 'Delete benefit?', 'This cannot be undone.', action: 'Delete', danger: true)) {
            await ref.read(dataProvider.notifier).deleteBenefit(b.id);
            if (context.mounted) Navigator.pop(context);
          }
        }),
      ],
    );
  }
}

