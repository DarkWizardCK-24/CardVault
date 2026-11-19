import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';

Color eventColor(String t) => switch (t) {
      'expiry' => C.bad, 'due' => C.warn, 'billing' => const Color(0xFF7DA7E8), 'fee' => const Color(0xFFE48B6B),
      'benefit' => C.good, 'sub' => const Color(0xFFB59AE8), 'emi' => C.silver, _ => C.gold,
    };

IconData eventIcon(String t) => switch (t) {
      'expiry' => Icons.credit_card_off_outlined, 'due' => Icons.payments_outlined, 'billing' => Icons.receipt_outlined, 'fee' => Icons.money_off_csred_outlined,
      'benefit' => Icons.card_giftcard_rounded, 'sub' => Icons.autorenew_rounded, 'emi' => Icons.event_repeat_rounded, _ => Icons.notifications_none_rounded,
    };

