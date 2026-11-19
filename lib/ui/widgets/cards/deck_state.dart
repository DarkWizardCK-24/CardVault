import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';

// ----------------------------------------------------------------- state
class DeckFilter extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

class SelectedCard extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? v) => state = v;
}

final deckFilterProvider = NotifierProvider<DeckFilter, int>(DeckFilter.new);

final selectedCardProvider = NotifierProvider<SelectedCard, String?>(SelectedCard.new);

const kStacks = ['All', 'Debit', 'Credit', 'Favourites', 'Travel', 'Daily use'];

/// Cards for stack index. Index >= kStacks.length maps to a collection.
List<CardItem> stackCards(VaultData d, int idx) {
  final live = d.liveCards.where((c) => c.status != CardStatus.replaced || idx == 0).toList();
  if (idx < kStacks.length) {
    return switch (idx) {
      1 => live.where((c) => c.kind == CardKind.debit).toList(),
      2 => live.where((c) => c.kind == CardKind.credit).toList(),
      3 => live.where((c) => c.favourite).toList(),
      4 => live.where((c) => c.travel).toList(),
      5 => live.where((c) => c.daily).toList(),
      _ => live,
    };
  }
  final ci = idx - kStacks.length;
  if (ci >= d.collections.length) return live;
  final col = d.collections[ci];
  return [for (final id in col.cardIds) if (d.card(id) != null && d.card(id)!.status != CardStatus.archived) d.card(id)!];
}

List<String> stackNames(VaultData d) => [...kStacks, ...d.collections.map((c) => c.name)];

