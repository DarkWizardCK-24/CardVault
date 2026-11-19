import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ----------------------------------------------------------------- form
class CardFormScreen extends ConsumerStatefulWidget {
  final CardItem? edit;
  const CardFormScreen(this.edit, {super.key});
  @override
  ConsumerState<CardFormScreen> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<CardFormScreen> {
  final _form = GlobalKey<FormState>();
  late CardItem c = widget.edit ?? CardItem(holder: '', expYear: DateTime.now().year + 4);
  final _t = <String, TextEditingController>{};
  bool customBank = false, customTheme = false;

  TextEditingController t(String k, String init) => _t.putIfAbsent(k, () => TextEditingController(text: init));
  String _n(double v) => v == 0 ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  @override
  void initState() {
    super.initState();
    customBank = widget.edit != null && !kBanksSet.contains(c.bank);
    customTheme = c.themeId == 'custom' && widget.edit != null;
  }

  @override
  void dispose() {
    for (final x in _t.values) {
      x.dispose();
    }
    super.dispose();
  }

  void pickTheme(CardStyle th) {
    setState(() {
      c.themeId = th.id;
      c.product = th.product == 'Custom design' ? c.product : th.product;
      customTheme = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    c.bank = t('bank', c.bank).text.trim();
    c.holder = t('holder', c.holder).text.trim();
    c.nickname = t('nick', c.nickname).text.trim();
    c.product = t('product', c.product).text.trim();
    final num = t('num', c.number).text.replaceAll(RegExp(r'\s|-'), '');
    c.number = num;
    c.last4 = num.length >= 4 ? num.substring(num.length - 4) : t('last4', c.last4).text.trim();
    double d(String k) => double.tryParse(t(k, '').text.replaceAll(',', '')) ?? 0;
    c.creditLimit = c.kind == CardKind.credit ? d('limit') : 0;
    c.outstanding = c.kind == CardKind.credit ? d('out') : 0;
    c.annualFee = d('af');
    c.joiningFee = d('jf');
    c.rewardPoints = d('pts');
    c.forexMarkup = d('fx');
    c.billingDay = int.tryParse(t('bill', '').text) ?? 0;
    c.dueDay = int.tryParse(t('due', '').text) ?? 0;
    c.support = t('support', c.support).text.trim();
    c.notes = t('notes', c.notes).text.trim();
    final isNew = widget.edit == null;
    await ref.read(dataProvider.notifier).saveCard(c, isNew: isNew);
    if (!mounted) return;
    ref.read(selectedCardProvider.notifier).set(c.id);
    Navigator.pop(context);
    toast(context, isNew ? 'Card added to your vault' : 'Card updated');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.edit;
    // seed controllers once
    t('bank', c.bank);
    t('holder', c.holder);
    t('nick', c.nickname);
    t('product', c.product);
    t('num', c.number);
    t('last4', c.last4);
    t('limit', _n(c.creditLimit));
    t('out', _n(c.outstanding));
    t('af', _n(c.annualFee));
    t('jf', _n(c.joiningFee));
    t('pts', _n(c.rewardPoints));
    t('fx', _n(c.forexMarkup));
    t('bill', c.billingDay == 0 ? '' : '${c.billingDay}');
    t('due', c.dueDay == 0 ? '' : '${c.dueDay}');
    t('support', c.support);
    t('notes', c.notes);
    final bankName = t('bank', c.bank).text;
    final themes = themesForBank(bankName);
    final preview = CardItem.fromMap(c.toMap())
      ..bank = bankName
      ..holder = t('holder', '').text
      ..last4 = t('num', '').text.length >= 4 ? t('num', '').text.replaceAll(RegExp(r'\D'), '').padLeft(4).substring(t('num', '').text.replaceAll(RegExp(r'\D'), '').length - 4) : (t('last4', '').text.isEmpty ? '0000' : t('last4', '').text);

    Widget gap([double h = 12]) => SizedBox(height: h);
    Widget num(String k, String label, {String? Function(String?)? v, bool int = false}) => TextFormField(
        controller: t(k, ''), keyboardType: TextInputType.numberWithOptions(decimal: !int), decoration: InputDecoration(labelText: label),
        validator: v ?? (s) => Validate.amount(s));

    return Scaffold(
      appBar: AppBar(title: Text(e == null ? 'Add card' : 'Edit card'), leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))),
      body: AmbientBackground(
        child: SafeArea(
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: AnimatedSwitcher(duration: 300.ms, child: CardFront(key: ValueKey('${c.themeId}${c.customColorA}${c.kind}'), card: preview)))),
              const SectionHeader('1 · Bank'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final b in kBanks)
                  ChoiceTile(b, bankName == b && !customBank, () => setState(() {
                        customBank = false;
                        t('bank', '').text = b;
                        final th = themesForBank(b);
                        pickTheme(th.first);
                      })),
                ChoiceTile('Other bank…', customBank, () => setState(() {
                      customBank = true;
                      t('bank', '').text = '';
                    })),
              ]),
              if (customBank) ...[gap(), TextFormField(controller: t('bank', ''), decoration: const InputDecoration(labelText: 'Bank name'), validator: Validate.required, onChanged: (_) => setState(() {}))],
              const SectionHeader('2 · Network & type'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final n in kNetworks) ChoiceTile(n, c.network == n, () => setState(() => c.network = n))]),
              gap(),
              Row(children: [
                Expanded(child: SegmentedPick(['Credit', 'Debit'], c.kind == CardKind.credit ? 0 : 1, (i) => setState(() => c.kind = i == 0 ? CardKind.credit : CardKind.debit))),
              ]),
              const SectionHeader('3 · Product & theme'),
              Text('Pick a style that resembles your card product. These are colour styles — not official bank artwork.', style: T.muted),
              gap(),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, clipBehavior: Clip.none,
                  itemCount: themes.length + 1, separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    if (i == themes.length) {
                      return ThemeTile(selected: customTheme, label: 'Custom', onTap: () => setState(() {
                            customTheme = true;
                            c.themeId = 'custom';
                            c.customColorA ??= kCustomPalettesFirst[0];
                            c.customColorB ??= kCustomPalettesFirst[1];
                          }), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [C.gold, C.silver, Colors.purple])), child: const Icon(Icons.palette_outlined, color: Colors.white)));
                    }
                    final th = themes[i];
                    return ThemeTile(selected: c.themeId == th.id, label: th.product, onTap: () => pickTheme(th),
                        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: th.colors))));
                  },
                ),
              ),
              if (customTheme) ...[
                gap(),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final p in kCustomPalettes)
                    GestureDetector(
                      onTap: () => setState(() {
                        c.customColorA = p[0];
                        c.customColorB = p[1];
                      }),
                      child: AnimatedContainer(duration: 200.ms, width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(p[0]), Color(p[1])]), border: Border.all(color: c.customColorA == p[0] ? C.gold : Colors.white24, width: c.customColorA == p[0] ? 3 : 1))),
                    ),
                ]),
              ],
              gap(),
              TextFormField(controller: t('product', ''), decoration: const InputDecoration(labelText: 'Product / variant name', hintText: 'e.g. Regalia, Platinum'), onChanged: (_) => setState(() {})),
              gap(),
              DropdownButtonFormField<String>(
                initialValue: kVariants.contains(c.product) ? c.product : null, dropdownColor: C.charcoal,
                decoration: const InputDecoration(labelText: 'Variant tier (optional)'),
                items: [for (final v in kVariants) DropdownMenuItem(value: v, child: Text(v))],
                onChanged: (v) => setState(() {
                  if (v != null && t('product', '').text.isEmpty) t('product', '').text = v;
                }),
              ),
              const SectionHeader('4 · Card details'),
              TextFormField(controller: t('holder', ''), textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Cardholder name'), validator: Validate.required, onChanged: (_) => setState(() {})),
              gap(),
              TextFormField(controller: t('nick', ''), decoration: const InputDecoration(labelText: 'Nickname (optional)')),
              gap(),
              TextFormField(
                controller: t('num', ''), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(23)],
                decoration: const InputDecoration(labelText: 'Full card number (optional)', helperText: 'Stored encrypted · masked everywhere · CVV / PIN are never stored', helperMaxLines: 2, prefixIcon: Icon(Icons.lock_outline_rounded, size: 18)),
                validator: Validate.cardNumber,
              ),
              gap(),
              if (t('num', '').text.replaceAll(' ', '').length < 4)
                TextFormField(controller: t('last4', ''), keyboardType: TextInputType.number, maxLength: 4, onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Last 4 digits', counterText: ''), validator: Validate.last4),
              Row(children: [
                Expanded(child: DropdownButtonFormField<int>(
                  initialValue: c.expMonth, dropdownColor: C.charcoal, decoration: const InputDecoration(labelText: 'Expiry month'),
                  items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))],
                  onChanged: (v) => setState(() => c.expMonth = v ?? 1))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<int>(
                  initialValue: c.expYear, dropdownColor: C.charcoal, decoration: const InputDecoration(labelText: 'Expiry year'),
                  items: [for (var y = DateTime.now().year - 5; y <= DateTime.now().year + 15; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                  onChanged: (v) => setState(() => c.expYear = v ?? c.expYear))),
              ]),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Show expiry on card', style: T.body), value: c.showExpiry, onChanged: (v) => setState(() => c.showExpiry = v)),
              const SectionHeader('5 · Limits & billing'),
              if (c.kind == CardKind.credit) ...[
                Row(children: [Expanded(child: num('limit', 'Credit limit (₹)')), const SizedBox(width: 12), Expanded(child: num('out', 'Outstanding (₹)'))]),
                gap(),
                Row(children: [Expanded(child: num('bill', 'Billing day', v: Validate.day, int: true)), const SizedBox(width: 12), Expanded(child: num('due', 'Payment due day', v: Validate.day, int: true))]),
                gap(),
              ],
              Row(children: [Expanded(child: num('af', 'Annual fee (₹)')), const SizedBox(width: 12), Expanded(child: num('jf', 'Joining fee (₹)'))]),
              gap(),
              Row(children: [Expanded(child: num('pts', 'Reward points')), const SizedBox(width: 12), Expanded(child: num('fx', 'Forex markup %'))]),
              gap(),
              DateTile('Issue date', c.issueDate, (d) => setState(() => c.issueDate = d)),
              gap(),
              DateTile('Annual fee date', c.annualFeeDate, (d) => setState(() => c.annualFeeDate = d)),
              const SectionHeader('6 · Organise'),
              Wrap(spacing: 8, children: [
                FilterChip(label: const Text('Favourite'), selected: c.favourite, onSelected: (v) => setState(() => c.favourite = v), selectedColor: C.gold.withValues(alpha: .25), checkmarkColor: C.gold),
                FilterChip(label: const Text('Travel'), selected: c.travel, onSelected: (v) => setState(() => c.travel = v), selectedColor: C.gold.withValues(alpha: .25), checkmarkColor: C.gold),
                FilterChip(label: const Text('Daily use'), selected: c.daily, onSelected: (v) => setState(() => c.daily = v), selectedColor: C.gold.withValues(alpha: .25), checkmarkColor: C.gold),
              ]),
              gap(),
              DropdownButtonFormField<CardStatus>(
                initialValue: c.status, dropdownColor: C.charcoal, decoration: const InputDecoration(labelText: 'Status'),
                items: [for (final s in CardStatus.values) DropdownMenuItem(value: s, child: Text(s.name[0].toUpperCase() + s.name.substring(1)))],
                onChanged: (v) => setState(() => c.status = v ?? c.status),
              ),
              gap(),
              TextFormField(controller: t('support', ''), decoration: const InputDecoration(labelText: 'Customer support (your own note)')),
              gap(),
              TextFormField(controller: t('notes', ''), maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 24),
              GoldButton(e == null ? 'Add to vault' : 'Save changes', icon: Icons.check_rounded, onTap: save),
            ]),
          ),
        ),
      ),
    );
  }
}

final kBanksSet = kBanks.toSet();

final kCustomPalettesFirst = kCustomPalettes.first;

