import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

const kBenefitCats = [
  'Airport lounge – domestic', 'Airport lounge – international', 'Cashback', 'Reward points', 'Fuel surcharge waiver',
  'Dining discount', 'Shopping offer', 'Travel benefit', 'OTT subscription', 'Forex markup', 'Annual fee waiver',
  'Joining benefit', 'Welcome benefit', 'Purchase protection', 'Extended warranty', 'Insurance', 'Other',
];

IconData benefitIcon(String c) {
  final s = c.toLowerCase();
  if (s.contains('lounge')) return Icons.flight_takeoff_rounded;
  if (s.contains('cashback')) return Icons.savings_outlined;
  if (s.contains('reward')) return Icons.stars_rounded;
  if (s.contains('fuel')) return Icons.local_gas_station_outlined;
  if (s.contains('dining')) return Icons.restaurant_outlined;
  if (s.contains('shopping')) return Icons.shopping_bag_outlined;
  if (s.contains('travel')) return Icons.luggage_outlined;
  if (s.contains('ott')) return Icons.movie_outlined;
  if (s.contains('forex')) return Icons.currency_exchange_rounded;
  if (s.contains('fee')) return Icons.money_off_csred_outlined;
  if (s.contains('protection') || s.contains('warranty') || s.contains('insurance')) return Icons.verified_user_outlined;
  return Icons.card_giftcard_rounded;
}

List<Field> _fields() => const [
      TextF('title', 'Benefit title', required: true),
      DropF('category', 'Category', kBenefitCats),
      TextF('description', 'Description', multiline: true),
      CardF('cardId', 'Associated card'),
      DateF('validUntil', 'Valid until'),
      TextF('usageLimit', 'Usage limit (0 = unlimited)', number: true),
      TextF('remaining', 'Remaining usage', number: true),
      TextF('terms', 'Terms & conditions (your note)', multiline: true),
      DateF('reminder', 'Reminder date'),
      TextF('notes', 'Notes', multiline: true),
    ];

Future<void> addBenefit(BuildContext context, WidgetRef ref, {String? cardId, Benefit? edit}) async {
  final b = edit;
  final r = await formSheet(context, edit == null ? 'Add benefit' : 'Edit benefit', _fields(),
      initial: b == null
          ? {'cardId': cardId ?? '', 'category': 'Other'}
          : {...b.toMap(), 'validUntil': b.validUntil, 'reminder': b.reminder},
      onDelete: b == null ? null : () async {
        if (await confirm(context, 'Delete benefit?', 'This removes “${b.title}”.', action: 'Delete', danger: true)) {
          await ref.read(dataProvider.notifier).deleteBenefit(b.id);
        }
      });
  if (r == null) return;
  final n = b ?? Benefit();
  n.title = r['title'];
  n.category = r['category'] ?? n.category;
  n.description = r['description'] ?? '';
  n.cardId = r['cardId'] ?? '';
  n.validUntil = r['validUntil'];
  n.usageLimit = (r['usageLimit'] as double).toInt();
  n.remaining = (r['remaining'] as double).toInt();
  n.terms = r['terms'] ?? '';
  n.reminder = r['reminder'];
  n.notes = r['notes'] ?? '';
  await ref.read(dataProvider.notifier).saveBenefit(n);
  NotificationService.instance.sync(ref.read(dataProvider));
}

