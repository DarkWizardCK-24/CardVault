import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cardvault/core/core.dart';

/// Precise text input with a slider underneath. The two stay in sync: dragging the slider
/// rewrites the text, typing moves the slider (clamped to its range, the text can go beyond it).
class SliderField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double min, max, step;
  final String? suffix;
  final ValueChanged<String> onChanged;

  /// Optional human-friendly hint shown under the label, e.g. "3 years".
  final String? hint;
  const SliderField({
    super.key,
    required this.label,
    required this.controller,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
    this.hint,
  });

  double get _value => (double.tryParse(controller.text.replaceAll(',', '')) ?? min).clamp(min, max).toDouble();

  String _fmt(double v) => step >= 1 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label, suffixText: suffix, helperText: hint),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 4),
          child: Slider(
            value: _value,
            min: min,
            max: max,
            divisions: ((max - min) / step).round().clamp(1, 4000),
            semanticFormatterCallback: (v) => '$label ${_fmt(v)}${suffix == null ? '' : ' $suffix'}',
            onChanged: (v) {
              final snapped = (v / step).round() * step;
              controller.text = _fmt(snapped.clamp(min, max).toDouble());
              onChanged(controller.text);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(children: [
            Text(_fmt(min), style: T.caption),
            const Spacer(),
            Text(_fmt(max), style: T.caption),
          ]),
        ),
      ]);
}
