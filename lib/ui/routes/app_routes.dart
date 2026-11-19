import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';

final navKey = GlobalKey<NavigatorState>();

void openCard(BuildContext context, String id) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(id)));

void openCardForm(BuildContext context, [CardItem? edit]) =>
    Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => CardFormScreen(edit)));

// ----------------------------------------------------------------- search
void openSearch(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));

