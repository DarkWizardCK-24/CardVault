import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CardDetailScreen(this.id, {super.key});
  @override
  ConsumerState<CardDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<CardDetailScreen> {
  bool revealed = false;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  Future<void> _toggleReveal() async {
    if (revealed) {
      _hide?.cancel();
      return setState(() => revealed = false);
    }
    if (await stepUpAuth(context, ref)) {
      if (!mounted) return;
      setState(() => revealed = true);
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => revealed = false);
      });
    }
  }

  Future<void> _copy(String v, String label) async {
    if (v.isEmpty) return;
    if (revealed || await stepUpAuth(context, ref)) {
      if (mounted) copySensitive(context, v, label: label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final c = d.card(widget.id);
    if (c == null) return const Scaffold(body: SizedBox());
    final benefits = d.benefits.where((b) => b.cardId == c.id).toList();
    final docs = d.docs.where((x) => x.cardId == c.id).toList();
    final txns = d.txns.where((t) => t.cardId == c.id).take(6).toList();
    final pays = d.payments.where((p) => p.cardId == c.id).take(4).toList();
    final n = ref.read(dataProvider.notifier);

    Widget kv(String k, String v, {VoidCallback? copy}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(flex: 4, child: Text(k, style: T.muted)),
            Expanded(flex: 6, child: Text(v.isEmpty ? '—' : v, textAlign: TextAlign.end, style: T.body)),
            if (copy != null) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.copy_rounded, size: 16, color: C.silver), onPressed: copy),
          ]),
        );

    return Screen(
      title: c.title, subtitle: cardSubtitle(c),
      actions: [
        IconPill(c.favourite ? Icons.star_rounded : Icons.star_outline_rounded, () {
          c.favourite = !c.favourite;
          n.saveCard(c);
        }, active: c.favourite),
        const SizedBox(width: 8),
        IconPill(Icons.more_horiz_rounded, () => cardActions(context, ref, c)),
      ],
      children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: FlipCard(card: c, selected: true))).rise(),
        const SizedBox(height: 8),
        Center(child: Text('Tap the card to flip', style: T.caption)),
        const SizedBox(height: 14),
        Center(child: _ExpiryChip(c)).rise(1),
        const SectionHeader('Secure details'),
        Glass(
          tint: [C.violet.withValues(alpha: .10), C.teal.withValues(alpha: .04)],
          child: Column(children: [
            _SecretRow(
              label: 'Card number',
              value: c.number.isEmpty ? '' : groupNumber(c.number),
              masked: c.number.isEmpty ? '•••• •••• •••• ${c.last4}' : maskNumber(c.number, c.last4),
              revealed: revealed,
              big: true,
              onCopy: () => _copy(c.number, 'Card number copied'),
            ),
            _SecretRow(label: 'CVV', value: c.cvv, masked: c.cvv.isEmpty ? '' : '•' * c.cvv.length, revealed: revealed, onCopy: () => _copy(c.cvv, 'CVV copied')),
            _SecretRow(label: 'Card PIN', value: c.pin, masked: c.pin.isEmpty ? '' : '•' * c.pin.length, revealed: revealed, onCopy: () => _copy(c.pin, 'PIN copied')),
            const SizedBox(height: 12),
            GoldButton(revealed ? 'Hide details' : 'Reveal details', icon: revealed ? Icons.visibility_off_outlined : Icons.fingerprint_rounded, outline: revealed, onTap: _toggleReveal),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.shield_outlined, size: 14, color: C.teal),
              const SizedBox(width: 6),
              Expanded(child: Text('Encrypted on this device · re-hides after 20s · clipboard clears after 30s', style: T.caption)),
            ]),
          ]),
        ).rise(2),
        if (c.extras.isNotEmpty) ...[
          const SectionHeader('Extra details'),
          Glass(child: Column(children: [
            for (final x in c.extras)
              _SecretRow(
                label: x.label,
                value: x.value,
                masked: x.secret ? '•' * x.value.length.clamp(4, 12) : x.value,
                revealed: revealed || !x.secret,
                onCopy: () => x.secret ? _copy(x.value, '${x.label} copied') : copySensitive(context, x.value, label: '${x.label} copied'),
              ),
          ])).rise(3),
        ],
        const SectionHeader('Card information'),
        Glass(child: Column(children: [
          kv('Bank', c.bank), kv('Cardholder', c.holder), kv('Network', c.network), kv('Type', c.kind == CardKind.credit ? 'Credit' : 'Debit'),
          kv('Product', c.product), kv('Valid thru', '${c.expMonth.toString().padLeft(2, '0')}/${c.expYear}'),
          kv('Issued', c.issueDate == null ? '' : dShort(c.issueDate!)), kv('Status', c.status.name),
        ])).rise(2),
        if (c.kind == CardKind.credit) ...[
          const SectionHeader('Limits & payment'),
          Glass(child: Column(children: [
            kv('Credit limit', money(c.creditLimit)), kv('Outstanding', money(c.outstanding)), kv('Available', money(c.available)),
            kv('Utilization', '${c.utilization.toStringAsFixed(1)}%  (from your figures)'),
            kv('Billing day', c.billingDay == 0 ? '' : '${c.billingDay} of month'), kv('Payment due', c.dueDay == 0 ? '' : '${c.dueDay} of month'),
            const SizedBox(height: 6),
            GoldButton('Record a payment', icon: Icons.payments_outlined, outline: true, onTap: () => addPayment(context, ref, c.id)),
          ])).rise(3),
        ],
        const SectionHeader('Fees & rewards'),
        Glass(child: Column(children: [
          kv('Annual fee', money(c.annualFee)), kv('Joining fee', money(c.joiningFee)),
          kv('Annual fee date', c.annualFeeDate == null ? '' : dShort(c.annualFeeDate!)),
          kv('Forex markup', c.forexMarkup == 0 ? '' : '${c.forexMarkup}%'), kv('Reward points', c.rewardPoints.toStringAsFixed(0)),
        ])),
        SectionHeader('Benefits', trailing: TextButton(onPressed: () => addBenefit(context, ref, cardId: c.id), child: const Text('+ Add'))),
        if (benefits.isEmpty) Text('No benefits recorded for this card yet.', style: T.muted) else for (final b in benefits) BenefitRow(b),
        SectionHeader('Documents', trailing: TextButton(onPressed: () => importDocument(context, ref, cardId: c.id), child: const Text('+ Import'))),
        if (docs.isEmpty) Text('No documents attached.', style: T.muted) else for (final x in docs) DocRow(x),
        const SectionHeader('Activity'),
        if (txns.isEmpty && pays.isEmpty) Text('No transactions or payments recorded.', style: T.muted),
        for (final t in txns) ListRow(leading: const IconBadge(Icons.receipt_long_outlined), title: t.merchant, subtitle: '${t.category} · ${dShort(t.date)}', trailing: Text(money(t.amount), style: T.num(15, c: t.isRefund ? C.good : C.text))),
        for (final p in pays) ListRow(leading: const IconBadge(Icons.check_circle_outline, color: C.good), title: 'Payment', subtitle: dShort(p.date), trailing: Text(money(p.amount), style: T.num(15, c: C.good))),
        if (c.support.isNotEmpty || c.notes.isNotEmpty) ...[
          const SectionHeader('Notes'),
          Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (c.support.isNotEmpty) Text('Customer care: ${c.support}', style: T.body),
            if (c.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(c.notes, style: T.muted)),
          ])),
        ],
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: GoldButton('Edit', icon: Icons.edit_outlined, outline: true, onTap: () => openCardForm(context, c))),
          const SizedBox(width: 12),
          Expanded(child: GoldButton(c.status == CardStatus.blocked ? 'Unblock' : 'Mark blocked', icon: Icons.block_rounded, outline: true, onTap: () {
            c.status = c.status == CardStatus.blocked ? CardStatus.active : CardStatus.blocked;
            n.saveCard(c);
          })),
        ]),
        const SizedBox(height: 12),
        GoldButton('Delete card', icon: Icons.delete_outline_rounded, outline: true, onTap: () async {
          if (await confirm(context, 'Delete card?', 'This permanently removes ${c.title} and its benefits from this device. This cannot be undone.', action: 'Delete', danger: true)) {
            await n.deleteCard(c.id);
            if (context.mounted) Navigator.pop(context);
          }
        }),
      ],
    );
  }
}


class _SecretRow extends StatelessWidget {
  final String label, value, masked;
  final bool revealed, big;
  final VoidCallback onCopy;
  const _SecretRow({required this.label, required this.value, required this.masked, required this.revealed, required this.onCopy, this.big = false});
  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty && masked.isEmpty;
    final shown = empty ? 'Not added' : (revealed ? value : masked);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: T.caption),
            const SizedBox(height: 3),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
              child: Text(shown, key: ValueKey('$label$revealed'), style: empty ? T.muted : T.num(big ? 20 : 17).copyWith(letterSpacing: 1.6)),
            ),
          ]),
        ),
        if (!empty) IconButton(tooltip: 'Copy', icon: const Icon(Icons.copy_rounded, size: 18, color: C.silver), onPressed: onCopy),
      ]),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final CardItem c;
  const _ExpiryChip(this.c);
  @override
  Widget build(BuildContext context) {
    final days = c.daysToExpiry;
    final (txt, col) = c.isExpired
        ? ('Expired ${dMonth(c.expiryDate)}', C.bad)
        : days <= 90
            ? ('Expires in $days days · ${dMonth(c.expiryDate)}', C.warn)
            : ('Valid till ${dMonth(c.expiryDate)} · ${(days / 30).floor()} months left', C.good);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: col.withValues(alpha: .12), border: Border.all(color: col.withValues(alpha: .45))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c.isExpired ? Icons.error_outline_rounded : Icons.event_available_rounded, size: 16, color: col),
        const SizedBox(width: 8),
        Text(txt, style: T.caption.copyWith(color: col, letterSpacing: .2, fontSize: 12.5)),
      ]),
    );
  }
}
