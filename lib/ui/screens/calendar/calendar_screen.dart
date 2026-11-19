import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<CalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime sel = DateTime.now();
  int filter = 0;
  static const _filters = ['All', 'Expiry', 'Due', 'Statement', 'Benefits', 'Renewals'];
  static const _types = {
    1: {'expiry'},
    2: {'due'},
    3: {'billing'},
    4: {'benefit'},
    5: {'sub', 'fee', 'renewal'},
  };

  bool _keep(CalEvent e) => filter == 0 || (_types[filter]?.contains(e.type) ?? true);

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    // Look far enough ahead to cover the month being viewed, so any picked month shows its events.
    final now = DateTime.now();
    final ahead = ((month.year - now.year) * 12 + month.month - now.month + 2).clamp(14, 240);
    final ev = buildEvents(d, monthsAhead: ahead).where(_keep).toList();
    final byDay = <DateTime, List<CalEvent>>{};
    for (final e in ev) {
      (byDay[DateTime(e.date.year, e.date.month, e.date.day)] ??= []).add(e);
    }
    final dayEvents = byDay[DateTime(sel.year, sel.month, sel.day)] ?? const <CalEvent>[];
    final today = DateTime(now.year, now.month, now.day);
    final next30 = ev.where((e) => !e.date.isBefore(today) && e.date.isBefore(today.add(const Duration(days: 30)))).take(10).toList();
    final expiries = d.liveCards.toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    final calendar = Glass(
      child: Column(children: [
        MonthHeader(month: month, onChanged: (m) => setState(() => month = m), firstYear: now.year - 10, lastYear: now.year + 20),
        const SizedBox(height: 12),
        MonthGrid(
          month: month,
          selected: sel,
          onSelect: (x) => setState(() => sel = x),
          dots: (day) => [for (final e in byDay[day] ?? const <CalEvent>[]) eventColor(e.type)],
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final t in const ['expiry', 'due', 'billing', 'benefit', 'sub'])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: eventColor(t), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(const {'expiry': 'Expiry', 'due': 'Due', 'billing': 'Statement', 'benefit': 'Benefit', 'sub': 'Renewal'}[t]!, style: T.caption),
            ]),
        ]),
      ]),
    ).rise();

    final details = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(DateFormat('EEEE, d MMMM yyyy').format(sel)),
      if (dayEvents.isEmpty)
        Text('Nothing scheduled on this day.', style: T.muted)
      else
        for (final (i, e) in dayEvents.indexed) _EventRow(e, onTap: _opener(d, e)).rise(i),
      const SectionHeader('Next 30 days'),
      if (next30.isEmpty) Text('Nothing in the next 30 days.', style: T.muted),
      for (final (i, e) in next30.indexed) _EventRow(e, showDate: true, onTap: _opener(d, e)).rise(i.clamp(0, 6)),
    ]);

    return Screen(
      title: 'Calendar',
      subtitle: 'Expiries, dues, statements and renewals',
      maxWidth: 1100,
      actions: [
        IconPill(Icons.today_rounded, () => setState(() {
              month = DateTime(now.year, now.month);
              sel = now;
            }), tooltip: 'Today'),
        const SizedBox(width: 8),
        IconPill(Icons.notifications_active_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())), tooltip: 'Reminder settings'),
      ],
      children: [
        ChipBar(items: _filters, index: filter, onChanged: (i) => setState(() => filter = i)),
        const SizedBox(height: 14),
        TwoPane(leftWidth: 440, breakpoint: 860, left: calendar, right: details),
        SectionHeader('Card expiries', trailing: Text('${expiries.length} cards', style: T.caption)),
        if (expiries.isEmpty)
          Text('Add cards to see their expiry dates mapped here.', style: T.muted)
        else
          _ExpiryMap(expiries, onPick: (c) => setState(() {
                month = DateTime(c.expYear, c.expMonth);
                sel = c.expiryDate;
                filter = 0;
              })),
      ],
    );
  }

  VoidCallback? _opener(VaultData d, CalEvent e) => e.cardId.isNotEmpty && d.card(e.cardId) != null ? () => openCard(context, e.cardId) : null;
}

class _EventRow extends StatelessWidget {
  final CalEvent e;
  final bool showDate;
  final VoidCallback? onTap;
  const _EventRow(this.e, {this.showDate = false, this.onTap});
  @override
  Widget build(BuildContext context) => ListRow(
        leading: IconBadge(eventIcon(e.type), color: eventColor(e.type)),
        title: e.title,
        subtitle: showDate ? '${e.subtitle} · ${dShort(e.date)}' : e.subtitle,
        trailing: showDate ? Text(relDays(e.date), style: T.caption.copyWith(color: eventColor(e.type))) : null,
        onTap: onTap,
      );
}

/// Every card's expiry on a timeline, coloured by urgency. Tapping one jumps the calendar to it.
class _ExpiryMap extends StatelessWidget {
  final List<CardItem> cards;
  final ValueChanged<CardItem> onPick;
  const _ExpiryMap(this.cards, {required this.onPick});
  @override
  Widget build(BuildContext context) => Glass(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(children: [
          for (final (i, c) in cards.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onPick(c),
              onLongPress: () => openCard(context, c.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  MiniCard(c, width: 58),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.title, style: T.h3.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      _Countdown(c),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${c.expMonth.toString().padLeft(2, '0')}/${c.expYear}', style: T.num(15)),
                    Text(c.isExpired ? 'Expired' : (c.expiringSoon ? '${c.daysToExpiry} days' : '${(c.daysToExpiry / 30).floor()} mo'), style: T.caption.copyWith(color: _col(c))),
                  ]),
                ]),
              ),
            ),
          ],
        ]),
      ).rise();
}

Color _col(CardItem c) => c.isExpired ? C.bad : (c.expiringSoon ? C.warn : C.teal);

/// Progress of the card's validity (assumes a 5-year card when no issue date is known).
class _Countdown extends StatelessWidget {
  final CardItem c;
  const _Countdown(this.c);
  @override
  Widget build(BuildContext context) {
    final start = c.issueDate ?? DateTime(c.expYear - 5, c.expMonth);
    final total = c.expiryDate.difference(start).inDays.clamp(1, 100000);
    final used = DateTime.now().difference(start).inDays.clamp(0, total);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(children: [
        Container(height: 6, color: Colors.white.withValues(alpha: .08)),
        FractionallySizedBox(
          widthFactor: used / total,
          child: Container(height: 6, decoration: BoxDecoration(gradient: LinearGradient(colors: [C.teal, _col(c)]))),
        ),
      ]),
    );
  }
}
