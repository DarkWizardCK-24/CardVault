import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Formats digits as "1234 5678 9012 3456" and caps input at 16 digits.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final b = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(capped[i]);
    }
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class CardFormScreen extends ConsumerStatefulWidget {
  final CardItem? edit;
  const CardFormScreen(this.edit, {super.key});
  @override
  ConsumerState<CardFormScreen> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<CardFormScreen> {
  final _form = GlobalKey<FormState>();
  // Work on a copy so cancelling never mutates the stored card.
  late final CardItem c = widget.edit == null ? CardItem(expYear: DateTime.now().year + 4) : CardItem.fromMap(widget.edit!.toMap());
  final _t = <String, TextEditingController>{};
  late final List<(TextEditingController, TextEditingController, bool)> _extras = [
    for (final e in c.extras) (TextEditingController(text: e.label), TextEditingController(text: e.value), e.secret),
  ];
  bool customBank = false, customTheme = false, showCvv = false, showPin = false;

  TextEditingController t(String k, [String init = '']) => _t.putIfAbsent(k, () => TextEditingController(text: init));
  String _n(double v) => v == 0 ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  @override
  void initState() {
    super.initState();
    customBank = widget.edit != null && c.bank.isNotEmpty && !kBanks.contains(c.bank);
    customTheme = c.themeId == 'custom' && widget.edit != null;
    t('bank', c.bank);
    t('holder', c.holder);
    t('nick', c.nickname);
    t('product', c.product);
    t('num', CardNumberFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: c.number)).text);
    t('last4', c.last4);
    t('cvv', c.cvv);
    t('pin', c.pin);
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
  }

  @override
  void dispose() {
    for (final x in _t.values) {
      x.dispose();
    }
    for (final e in _extras) {
      e.$1.dispose();
      e.$2.dispose();
    }
    super.dispose();
  }

  String get _digits => t('num').text.replaceAll(RegExp(r'\D'), '');

  void pickTheme(CardStyle th) {
    setState(() {
      c.themeId = th.id;
      customTheme = false;
    });
    HapticFeedback.selectionClick();
  }

  void addExtra([String label = '']) {
    setState(() => _extras.add((TextEditingController(text: label), TextEditingController(), false)));
    HapticFeedback.selectionClick();
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      toast(context, 'Please fix the highlighted fields');
      return;
    }
    c.bank = t('bank').text.trim();
    c.holder = t('holder').text.trim();
    c.nickname = t('nick').text.trim();
    c.product = t('product').text.trim();
    c.number = _digits;
    c.last4 = _digits.length >= 4 ? _digits.substring(_digits.length - 4) : t('last4').text.trim();
    c.cvv = t('cvv').text.trim();
    c.pin = t('pin').text.trim();
    c.extras = [
      for (final e in _extras)
        if (e.$1.text.trim().isNotEmpty || e.$2.text.trim().isNotEmpty) CardExtra(label: e.$1.text.trim().isEmpty ? 'Detail' : e.$1.text.trim(), value: e.$2.text.trim(), secret: e.$3),
    ];
    double d(String k) => double.tryParse(t(k).text.replaceAll(',', '')) ?? 0;
    c.creditLimit = c.kind == CardKind.credit ? d('limit') : 0;
    c.outstanding = c.kind == CardKind.credit ? d('out') : 0;
    c.annualFee = d('af');
    c.joiningFee = d('jf');
    c.rewardPoints = d('pts');
    c.forexMarkup = d('fx');
    c.billingDay = int.tryParse(t('bill').text) ?? 0;
    c.dueDay = int.tryParse(t('due').text) ?? 0;
    c.support = t('support').text.trim();
    c.notes = t('notes').text.trim();
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
    final bankName = t('bank').text;
    final themes = themesForBank(bankName);
    final preview = CardItem.fromMap(c.toMap())
      ..bank = bankName
      ..holder = t('holder').text
      ..product = t('product').text
      ..last4 = _digits.length >= 4 ? _digits.substring(_digits.length - 4) : t('last4').text;

    Widget gap([double h = 12]) => SizedBox(height: h);
    Widget num(String k, String label, {String? Function(String?)? v, bool integer = false, IconData? icon}) => TextFormField(
        controller: t(k),
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(integer ? r'\d' : r'[\d.,]'))],
        decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon, size: 18)),
        validator: v ?? (s) => Validate.amount(s));
    Widget secret(String k, String label, int max, bool shown, VoidCallback toggle, String? Function(String?) v, IconData icon) => TextFormField(
          controller: t(k),
          obscureText: !shown,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(max)],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: IconButton(icon: Icon(shown ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: toggle),
          ),
          validator: v,
        );

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final previewCard = Column(children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AnimatedSwitcher(
          duration: 350.ms,
          transitionBuilder: (w, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: w)),
          child: FlipCard(key: ValueKey('${c.themeId}${c.customColorA}${c.kind}'), card: preview),
        ),
      ),
      const SizedBox(height: 8),
      Text('Live preview · tap to flip', style: T.caption),
    ]);

    final fields = <Widget>[
      FormSection(step: 1, title: 'Bank', icon: Icons.account_balance_rounded, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in kBanks)
            ChoiceTile(b, bankName == b && !customBank, () => setState(() {
                  customBank = false;
                  t('bank').text = b;
                  pickTheme(themesForBank(b).first);
                })),
          ChoiceTile('Other bank…', customBank, () => setState(() {
                customBank = true;
                t('bank').text = '';
              })),
        ]),
        if (customBank) ...[
          gap(),
          TextFormField(controller: t('bank'), textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Bank name'), validator: Validate.required, onChanged: (_) => setState(() {})),
        ],
      ]),
      FormSection(step: 2, title: 'Network & type', icon: Icons.hub_rounded, children: [
        SegmentedPick(const ['Credit', 'Debit'], c.kind == CardKind.credit ? 0 : 1, (i) => setState(() => c.kind = i == 0 ? CardKind.credit : CardKind.debit)),
        gap(),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final n in kNetworks) ChoiceTile(n, c.network == n, () => setState(() => c.network = n))]),
      ]),
      FormSection(step: 3, title: 'Card design', icon: Icons.palette_rounded, children: [
        Text('Your bank’s styles first, then signature gradients. Colour styles only — not official bank artwork.', style: T.muted),
        gap(),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: themes.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              if (i == themes.length) {
                return ThemeTile(
                    selected: customTheme,
                    label: 'Custom',
                    onTap: () => setState(() {
                          customTheme = true;
                          c.themeId = 'custom';
                          c.customColorA ??= kCustomPalettes.first[0];
                          c.customColorB ??= kCustomPalettes.first[1];
                        }),
                    child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const SweepGradient(colors: [C.gold, C.rose, C.violet, C.sky, C.teal, C.gold])),
                        child: const Icon(Icons.palette_outlined, color: Colors.white)));
              }
              final th = themes[i];
              return ThemeTile(
                  selected: c.themeId == th.id,
                  label: th.product,
                  onTap: () => pickTheme(th),
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
                child: AnimatedContainer(
                    duration: 200.ms,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(p[0]), Color(p[1])]),
                        border: Border.all(color: c.customColorA == p[0] && c.customColorB == p[1] ? C.gold : Colors.white24, width: c.customColorA == p[0] && c.customColorB == p[1] ? 3 : 1))),
              ),
          ]),
        ],
        gap(),
        TextFormField(
            controller: t('product'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Product / variant name', hintText: 'e.g. Regalia, Platinum'),
            onChanged: (_) => setState(() {})),
        gap(8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in kVariants)
            ActionChip(
              label: Text(v, style: T.caption.copyWith(color: C.text)),
              onPressed: () => setState(() => t('product').text = v),
              visualDensity: VisualDensity.compact,
            ),
        ]),
      ]),
      FormSection(step: 4, title: 'Card details', icon: Icons.credit_card_rounded, children: [
        TextFormField(
            controller: t('holder'),
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Cardholder name', prefixIcon: Icon(Icons.person_outline_rounded, size: 18)),
            validator: Validate.required,
            onChanged: (_) => setState(() {})),
        gap(),
        TextFormField(
            controller: t('nick'),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nickname (optional)', prefixIcon: Icon(Icons.label_outline_rounded, size: 18))),
        gap(),
        TextFormField(
          controller: t('num'),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
          inputFormatters: [CardNumberFormatter()],
          decoration: InputDecoration(
            labelText: 'Card number (16 digits)',
            hintText: '1234 5678 9012 3456',
            counterText: '${_digits.length}/16',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
          ),
          validator: Validate.cardNumber,
        ),
        if (_digits.length < 4) ...[
          gap(),
          TextFormField(
              controller: t('last4'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Last 4 digits (if you skip the full number)'),
              validator: Validate.last4),
        ],
        gap(),
        MonthYearTile('Expiry (valid thru)', DateTime(c.expYear, c.expMonth), (d) => setState(() {
              c.expMonth = d.month;
              c.expYear = d.year;
            }), firstYear: DateTime.now().year - 10, lastYear: DateTime.now().year + 20),
        gap(),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: secret('cvv', 'CVV', 4, showCvv, () => setState(() => showCvv = !showCvv), Validate.cvv, Icons.pin_outlined)),
          const SizedBox(width: 12),
          Expanded(child: secret('pin', 'Card PIN', 6, showPin, () => setState(() => showPin = !showPin), Validate.pin, Icons.password_rounded)),
        ]),
        gap(8),
        const _SecureNote('Number, CVV and PIN are encrypted on this device and only revealed after Face ID / fingerprint or your master password.'),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Show expiry on card face', style: T.body),
            value: c.showExpiry,
            onChanged: (v) => setState(() => c.showExpiry = v)),
      ]),
      FormSection(step: 5, title: 'Extra details', icon: Icons.note_add_outlined, children: [
        Text('CRN, customer ID, account number — anything you want kept with this card.', style: T.muted),
        gap(),
        for (var i = 0; i < _extras.length; i++)
          Padding(
            key: ObjectKey(_extras[i].$1),
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withValues(alpha: .03), border: Border.all(color: C.border)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      flex: 4,
                      child: TextFormField(
                          controller: _extras[i].$1,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Label', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 6,
                      child: TextFormField(
                          controller: _extras[i].$2,
                          obscureText: _extras[i].$3,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(labelText: 'Value', isDense: true))),
                  IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: C.bad, size: 20),
                      onPressed: () => setState(() {
                            final r = _extras.removeAt(i);
                            r.$1.dispose();
                            r.$2.dispose();
                          })),
                ]),
                Row(children: [
                  Text('Treat as secret', style: T.caption),
                  const Spacer(),
                  Switch(value: _extras[i].$3, onChanged: (v) => setState(() => _extras[i] = (_extras[i].$1, _extras[i].$2, v))),
                ]),
              ]),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: .1, end: 0),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in kExtraLabels.where((l) => !_extras.any((e) => e.$1.text == l)).take(5))
            ActionChip(avatar: const Icon(Icons.add_rounded, size: 16, color: C.gold), label: Text(l), onPressed: () => addExtra(l)),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 16, color: C.gold), label: const Text('Custom'), onPressed: addExtra),
        ]),
      ]),
      FormSection(step: 6, title: c.kind == CardKind.credit ? 'Limits & billing' : 'Fees & rewards', icon: Icons.speed_rounded, children: [
        if (c.kind == CardKind.credit) ...[
          Row(children: [Expanded(child: num('limit', 'Credit limit (₹)')), const SizedBox(width: 12), Expanded(child: num('out', 'Outstanding (₹)'))]),
          gap(),
          Row(children: [
            Expanded(child: num('bill', 'Statement day', v: Validate.day, integer: true)),
            const SizedBox(width: 12),
            Expanded(child: num('due', 'Payment due day', v: Validate.day, integer: true)),
          ]),
          gap(),
        ],
        Row(children: [Expanded(child: num('af', 'Annual fee (₹)')), const SizedBox(width: 12), Expanded(child: num('jf', 'Joining fee (₹)'))]),
        gap(),
        Row(children: [Expanded(child: num('pts', 'Reward points')), const SizedBox(width: 12), Expanded(child: num('fx', 'Forex markup %'))]),
        gap(),
        DateTile('Issue date', c.issueDate, (d) => setState(() => c.issueDate = d)),
        gap(),
        DateTile('Annual fee date', c.annualFeeDate, (d) => setState(() => c.annualFeeDate = d)),
      ]),
      FormSection(step: 7, title: 'Organise', icon: Icons.tune_rounded, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilterChip(label: const Text('Favourite'), selected: c.favourite, onSelected: (v) => setState(() => c.favourite = v)),
          FilterChip(label: const Text('Travel'), selected: c.travel, onSelected: (v) => setState(() => c.travel = v)),
          FilterChip(label: const Text('Daily use'), selected: c.daily, onSelected: (v) => setState(() => c.daily = v)),
        ]),
        gap(),
        DropdownButtonFormField<CardStatus>(
          initialValue: c.status,
          dropdownColor: C.charcoal,
          borderRadius: BorderRadius.circular(16),
          decoration: const InputDecoration(labelText: 'Status'),
          items: [for (final s in CardStatus.values) DropdownMenuItem(value: s, child: Text(s.name[0].toUpperCase() + s.name.substring(1)))],
          onChanged: (v) => setState(() => c.status = v ?? c.status),
        ),
        gap(),
        TextFormField(
            controller: t('support'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Customer care number', prefixIcon: Icon(Icons.support_agent_rounded, size: 18))),
        gap(),
        TextFormField(controller: t('notes'), maxLines: 4, minLines: 2, decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true)),
      ]),
      const SizedBox(height: 22),
      GoldButton(e == null ? 'Add to vault' : 'Save changes', icon: Icons.check_rounded, onTap: save),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(e == null ? 'Add card' : 'Edit card'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: save, child: const Text('Save')), const SizedBox(width: 8)],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Form(
            key: _form,
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 420, child: Padding(padding: const EdgeInsets.fromLTRB(28, 20, 12, 0), child: previewCard)),
                    Expanded(
                      child: ListView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 0, 28, 40),
                        children: fields,
                      ),
                    ),
                  ])
                : ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    children: [Center(child: previewCard), ...fields],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Numbered glass panel that groups a section of the card form.
class FormSection extends StatelessWidget {
  final int step;
  final String title;
  final IconData icon;
  final List<Widget> children;
  const FormSection({super.key, required this.step, required this.title, required this.icon, required this.children});
  static const _grads = [C.goldGradient, C.oceanGradient, C.sunsetGradient, C.emberGradient];
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Glass(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: _grads[(step - 1) % _grads.length]),
                child: Text('$step', style: T.h3.copyWith(color: C.obsidian, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: T.h2.copyWith(fontSize: 17))),
              Icon(icon, size: 18, color: C.muted),
            ]),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      ).rise(step.clamp(0, 4));
}

class _SecureNote extends StatelessWidget {
  final String text;
  const _SecureNote(this.text);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.shield_outlined, size: 14, color: C.teal),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: T.caption.copyWith(color: C.teal.withValues(alpha: .9), letterSpacing: .1))),
      ]);
}
