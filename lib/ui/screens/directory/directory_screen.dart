import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final banks = d.contacts.where((c) => !c.personalNote).toList();
    final notes = d.contacts.where((c) => c.personalNote).toList();
    final mine = d.cards.map((c) => c.bank).where((b) => b.isNotEmpty).toSet().where((b) => !banks.any((c) => c.bank == b));
    return Screen(
      title: 'Emergency Center', subtitle: 'Bank directory & card blocking',
      actions: [IconPill(Icons.add_rounded, () => contactForm(context, ref))],
      children: [
        Glass(
          tint: [C.bad.withValues(alpha: .16), C.bad.withValues(alpha: .04)],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.warning_amber_rounded, color: C.bad), const SizedBox(width: 10), Text('Lost or stolen card?', style: T.h2)]),
            const SizedBox(height: 10),
            for (final (i, s) in ['Block the card immediately via your bank’s app, net-banking or helpline.', 'Note the time and the reference number the bank gives you.', 'Review recent transactions and report anything unfamiliar.', 'Request a replacement, then mark the card “Blocked” here.'].indexed)
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${i + 1}.  ', style: T.body.copyWith(color: C.gold)), Expanded(child: Text(s, style: T.body))])),
            const SizedBox(height: 4),
            Text('Never share OTP, PIN or CVV with anyone — including callers claiming to be from the bank.', style: T.muted.copyWith(color: C.warn)),
          ]),
        ).rise(),
        const SizedBox(height: 10),
        Row(children: [const Icon(Icons.info_outline_rounded, size: 14, color: C.muted), const SizedBox(width: 6), Expanded(child: Text('Contacts below are entered by you and are not verified. Confirm numbers on your card or the bank’s official website.', style: T.caption))]),
        SectionHeader('Bank contacts', trailing: TextButton(onPressed: () => contactForm(context, ref), child: const Text('+ Add'))),
        if (banks.isEmpty) Text('No contacts saved yet.', style: T.muted),
        for (final b in mine.take(4))
          ListRow(leading: const IconBadge(Icons.add_call, color: C.silver), title: b, subtitle: 'Tap to add contact details for this bank', onTap: () => contactForm(context, ref, edit: Contact(bank: b))),
        for (final c in banks)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(
            onTap: () => contactForm(context, ref, edit: c),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(c.bank, style: T.h3)), const Tag('User-entered', color: C.warn)]),
              const SizedBox(height: 8),
              if (c.phone.isNotEmpty) _line(context, Icons.support_agent_rounded, 'Customer care', c.phone),
              if (c.lostCardPhone.isNotEmpty) _line(context, Icons.report_gmailerrorred_rounded, 'Lost card', c.lostCardPhone, color: C.bad),
              if (c.website.isNotEmpty) _line(context, Icons.language_rounded, 'Website', c.website),
              if (c.instructions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(c.instructions, style: T.muted)),
            ]),
          )),
        SectionHeader('Personal emergency notes', trailing: TextButton(onPressed: () => contactForm(context, ref, note: true), child: const Text('+ Add'))),
        if (notes.isEmpty) Text('Add notes like insurance helplines or who to call.', style: T.muted),
        for (final n in notes) ListRow(leading: const IconBadge(Icons.sticky_note_2_outlined), title: n.bank, subtitle: n.instructions, onTap: () => contactForm(context, ref, edit: n)),
        const SizedBox(height: 4),
        Text('Supported bank names: ${kBanks.take(5).join(', ')}… or any custom bank.', style: T.caption),
      ],
    );
  }

  Widget _line(BuildContext context, IconData i, String k, String v, {Color color = C.silver}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(i, size: 18, color: color), const SizedBox(width: 10), Text('$k  ', style: T.muted), Expanded(child: Text(v, style: T.body, textAlign: TextAlign.end)),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.copy_rounded, size: 16, color: C.silver), onPressed: () => copySensitive(context, v, label: 'Copied')),
        ]),
      );
}

