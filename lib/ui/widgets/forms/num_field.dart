import 'package:flutter/material.dart';

Widget numField(String label, TextEditingController c, ValueChanged<String> on, {String? suffix}) => TextField(
      controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: on,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );

double numVal(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '')) ?? 0;

