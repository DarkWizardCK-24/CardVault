import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  final String? foot;
  const StatTile(this.label, this.value, this.icon, {super.key, this.color, this.foot});
  @override
  Widget build(BuildContext context) => Glass(
        padding: const EdgeInsets.all(14), radius: 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: (color ?? C.gold).withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color ?? C.gold),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: T.num(21))),
            const SizedBox(height: 2),
            Text(label, style: T.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (foot != null) Text(foot!, style: T.caption.copyWith(color: color ?? C.gold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ]),
      );
}

