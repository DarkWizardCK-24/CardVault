import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const DateTile(this.label, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          FocusScope.of(context).unfocus();
          final d = await pickDate(context, initial: value, title: label);
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: value == null ? const Icon(Icons.calendar_today_rounded, size: 18, color: C.gold) : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onChanged(null))),
          child: Text(value == null ? 'Not set' : dShort(value!), style: value == null ? T.muted : T.body),
        ),
      );
}
