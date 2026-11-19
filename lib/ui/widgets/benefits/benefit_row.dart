import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class BenefitRow extends ConsumerWidget {
  final Benefit b;
  const BenefitRow(this.b, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(dataProvider).card(b.cardId);
    return ListRow(
      leading: IconBadge(benefitIcon(b.category), color: b.expired ? C.muted : C.gold),
      title: b.title,
      subtitle: [if (card != null) card.title, b.category, if (b.validUntil != null) (b.expired ? 'Expired ${dShort(b.validUntil!)}' : 'Until ${dShort(b.validUntil!)}')].join(' · '),
      trailing: b.usageLimit > 0 ? Tag('${b.remaining}/${b.usageLimit}', color: b.remaining == 0 ? C.bad : C.good) : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BenefitDetailScreen(b.id))),
    );
  }
}

