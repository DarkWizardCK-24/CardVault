import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

// ------------------------------------------------------------------ forms
sealed class Field {
  final String key, label;
  const Field(this.key, this.label);
}

class TextF extends Field {
  final bool number, multiline, required;
  final String? hint;
  const TextF(super.key, super.label, {this.number = false, this.multiline = false, this.required = false, this.hint});
}

class DateF extends Field {
  final bool required;
  const DateF(super.key, super.label, {this.required = false});
}

class DropF extends Field {
  final List<String> options;
  const DropF(super.key, super.label, this.options);
}

class SwitchF extends Field {
  const SwitchF(super.key, super.label);
}

class CardF extends Field {
  final bool required;
  const CardF(super.key, super.label, {this.required = false});
}

/// Generic, validated form in a bottom sheet. Returns the entered values or null.
Future<Map<String, dynamic>?> formSheet(BuildContext context, String title, List<Field> fields,
    {Map<String, dynamic> initial = const {}, String save = 'Save', VoidCallback? onDelete}) {
  return sheet<Map<String, dynamic>>(context, _FormSheet(title, fields, initial, save, onDelete));
}

class _FormSheet extends ConsumerStatefulWidget {
  final String title, save;
  final List<Field> fields;
  final Map<String, dynamic> initial;
  final VoidCallback? onDelete;
  const _FormSheet(this.title, this.fields, this.initial, this.save, this.onDelete);
  @override
  ConsumerState<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends ConsumerState<_FormSheet> {
  final _key = GlobalKey<FormState>();
  late final Map<String, dynamic> v = {...widget.initial};
  final _ctl = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      if (f is TextF) {
        final x = v[f.key];
        _ctl[f.key] = TextEditingController(text: x == null ? '' : (x is num && x == x.roundToDouble() ? x.toStringAsFixed(0) : '$x'));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(dataProvider).cards;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(widget.title, style: T.h1)),
            if (widget.onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.bad), onPressed: () {
                Navigator.pop(context);
                widget.onDelete!();
              }),
          ]),
          const SizedBox(height: 14),
          for (final f in widget.fields) ...[
            switch (f) {
              TextF() => TextFormField(
                  controller: _ctl[f.key],
                  keyboardType: f.number ? const TextInputType.numberWithOptions(decimal: true) : (f.multiline ? TextInputType.multiline : TextInputType.text),
                  maxLines: f.multiline ? 4 : 1, minLines: f.multiline ? 2 : 1,
                  textCapitalization: f.number ? TextCapitalization.none : TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: f.label, hintText: f.hint, prefixText: f.number ? '' : null),
                  validator: (s) => f.number ? Validate.amount(s, required: f.required) : (f.required ? Validate.required(s) : null),
                ),
              DateF() => FormField<DateTime>(
                  initialValue: v[f.key] as DateTime?,
                  validator: (d) => f.required && d == null ? 'Required' : null,
                  builder: (st) => GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context, initialDate: st.value ?? now,
                        firstDate: DateTime(now.year - 15), lastDate: DateTime(now.year + 30),
                        builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: C.gold, surface: C.charcoal)), child: w!),
                      );
                      if (d != null) {
                        v[f.key] = d;
                        st.didChange(d);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: f.label, errorText: st.errorText, suffixIcon: st.value != null
                          ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { v[f.key] = null; st.didChange(null); })
                          : const Icon(Icons.calendar_today_rounded, size: 18)),
                      child: Text(st.value == null ? 'Select date' : dShort(st.value!), style: st.value == null ? T.muted : T.body),
                    ),
                  ),
                ),
              DropF() => DropdownButtonFormField<String>(
                  initialValue: widget.initial[f.key] != null && f.options.contains(widget.initial[f.key]) ? widget.initial[f.key] as String : null,
                  dropdownColor: C.charcoal, borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(labelText: f.label),
                  items: [for (final o in f.options) DropdownMenuItem(value: o, child: Text(o))],
                  onChanged: (x) => v[f.key] = x,
                  validator: (x) => x == null && !widget.initial.containsKey(f.key) ? null : null,
                ),
              SwitchF() => StatefulBuilder(builder: (c, set) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6), title: Text(f.label, style: T.body),
                  value: v[f.key] == true, onChanged: (x) => set(() => v[f.key] = x))),
              CardF() => DropdownButtonFormField<String>(
                  initialValue: cards.any((c) => c.id == widget.initial[f.key]) ? widget.initial[f.key] as String : null,
                  dropdownColor: C.charcoal, borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(labelText: f.label),
                  items: [
                    if (!f.required) const DropdownMenuItem(value: '', child: Text('None')),
                    for (final c in cards) DropdownMenuItem(value: c.id, child: Text('${c.title} ••${c.last4}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (x) => v[f.key] = x ?? '',
                  validator: (x) => f.required && (x == null || x.isEmpty) ? 'Select a card' : null,
                ),
            },
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          GoldButton(widget.save, onTap: () {
            if (!_key.currentState!.validate()) {
              HapticFeedback.heavyImpact();
              return;
            }
            final out = {...v};
            _ctl.forEach((k, c) {
              final f = widget.fields.firstWhere((f) => f.key == k) as TextF;
              out[k] = f.number ? (double.tryParse(c.text.replaceAll(',', '')) ?? 0) : c.text.trim();
            });
            Navigator.pop(context, out);
          }),
        ]),
      ),
    );
  }
}

