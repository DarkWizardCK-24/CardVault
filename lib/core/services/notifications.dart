import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:cardvault/core/data/repo.dart';

/// Local-only reminders. No push, no network. Notification text deliberately avoids
/// card numbers: only the card nickname and the kind of event.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {}
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
            requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    final and = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await and?.requestNotificationsPermission() ?? false;
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Re-plans every reminder from current data. iOS caps pending notifications at 64,
  /// so we schedule the soonest ones first.
  Future<void> sync(VaultData d) async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
    if (!d.settings.notificationsOn) return;
    final now = tz.TZDateTime.now(tz.local);
    final plans = <(tz.TZDateTime, String, String)>[];
    for (final e in buildEvents(d, monthsAhead: 4)) {
      for (final days in d.settings.remindDays) {
        final steps = d.settings.frequency == 'daily' && days > 0 ? List.generate(days + 1, (i) => i) : [days];
        for (final s in steps) {
          final when = tz.TZDateTime(tz.local, e.date.year, e.date.month, e.date.day, d.settings.remindHour)
              .subtract(Duration(days: s));
          if (when.isAfter(now)) {
            plans.add((when, e.title, s == 0 ? 'Today · ${e.subtitle}' : 'In $s day${s == 1 ? '' : 's'} · ${e.subtitle}'));
          }
        }
      }
    }
    plans.sort((a, b) => a.$1.compareTo(b.$1));
    var id = 1;
    for (final p in plans.take(60)) {
      try {
        await _plugin.zonedSchedule(
          id: id++,
          title: p.$2,
          body: p.$3,
          scheduledDate: p.$1,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails('reminders', 'Card reminders',
                channelDescription: 'Billing, payment, expiry and benefit reminders',
                importance: Importance.high, priority: Priority.high, visibility: NotificationVisibility.private),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {/* never log event content */}
    }
  }
}
