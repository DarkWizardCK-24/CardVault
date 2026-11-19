import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';

class DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const DateTile(this.label, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final d = await showDatePicker(
            context: context, initialDate: value ?? now, firstDate: DateTime(now.year - 15), lastDate: DateTime(now.year + 20),
            builder: (c, w) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: C.gold, surface: C.charcoal)), child: w!),
          );
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: value == null ? const Icon(Icons.calendar_today_rounded, size: 18) : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onChanged(null))),
          child: Text(value == null ? 'Not set' : dShort(value!), style: value == null ? T.muted : T.body),
        ),
      );
}

