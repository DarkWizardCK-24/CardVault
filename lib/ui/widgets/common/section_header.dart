import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionHeader(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: T.label)),
          ?trailing,
        ]),
      );
}

