import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class SelectedCardInfo extends StatelessWidget {
  final CardItem c;
  const SelectedCardInfo(this.c, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Glass(
          onTap: () => openCard(context, c.id),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(key: ValueKey(c.id), crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(c.title, style: T.h2, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Tag(c.status.name.toUpperCase(), color: switch (c.status) { CardStatus.active => C.good, CardStatus.blocked => C.bad, _ => C.warn }),
              ]),
              const SizedBox(height: 4),
              Text(cardSubtitle(c), style: T.muted),
              const SizedBox(height: 14),
              if (c.kind == CardKind.credit && c.creditLimit > 0) ...[
                Row(children: [
                  _kv('Outstanding', money(c.outstanding)),
                  _kv('Available', money(c.available)),
                  _kv('Limit', compactMoney(c.creditLimit)),
                ]),
                const SizedBox(height: 12),
                Progress(c.utilization / 100, color: c.utilization > 70 ? C.bad : (c.utilization > 40 ? C.warn : C.good)),
                const SizedBox(height: 6),
                Text('${c.utilization.toStringAsFixed(0)}% of your entered limit used', style: T.caption),
              ] else
                Row(children: [_kv('Network', c.network), _kv('Expires', '${c.expMonth.toString().padLeft(2, '0')}/${c.expYear % 100}'), _kv('Bank', c.bank.split(' ').first)]),
            ]),
          ),
        ),
      );
  Widget _kv(String k, String v) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: T.num(15)), Text(k, style: T.caption)]));
}

