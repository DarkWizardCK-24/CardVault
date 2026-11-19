import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Global search across cards, benefits and documents (all local).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<SearchScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final s = q.toLowerCase().trim();
    final cards = s.isEmpty ? [] : d.cards.where((c) => '${c.title} ${c.bank} ${c.network} ${c.last4} ${c.holder} ${c.product}'.toLowerCase().contains(s)).toList();
    final bens = s.isEmpty ? [] : d.benefits.where((b) => '${b.title} ${b.category} ${b.description}'.toLowerCase().contains(s)).toList();
    final docs = s.isEmpty ? [] : d.docs.where((x) => '${x.name} ${x.text} ${x.type}'.toLowerCase().contains(s)).toList();
    return Screen(title: 'Search', children: [
      TextField(autofocus: true, onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(hintText: 'Cards, benefits, documents…', prefixIcon: Icon(Icons.search_rounded, size: 20))),
      const SizedBox(height: 10),
      if (s.isNotEmpty && cards.isEmpty && bens.isEmpty && docs.isEmpty) const EmptyState(icon: Icons.search_off_rounded, title: 'No results', message: 'Nothing in your vault matches that.'),
      if (cards.isNotEmpty) const SectionHeader('Cards'),
      for (final c in cards) ListRow(leading: MiniCard(c, width: 56), title: c.title, subtitle: '${cardSubtitle(c)} · ••${c.last4}', onTap: () => openCard(context, c.id)),
      if (bens.isNotEmpty) const SectionHeader('Benefits'),
      for (final b in bens) BenefitRow(b),
      if (docs.isNotEmpty) const SectionHeader('Documents'),
      for (final x in docs) DocRow(x),
    ]);
  }
}

