import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final ev = buildEvents(d, monthsAhead: 24);
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7; // Sunday first
    final days = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final dayEvents = ev.where((e) => _same(e.date, sel)).toList();
    return Screen(
      title: 'Calendar', subtitle: 'Expiries, dues, renewals',
      actions: [IconPill(Icons.notifications_active_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())), tooltip: 'Reminder settings')],
      children: [
        Glass(child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Text(DateFormat('MMMM yyyy').format(month), key: ValueKey(month), textAlign: TextAlign.center, style: T.h2))),
            IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1))),
          ]),
          const SizedBox(height: 6),
          Row(children: [for (final w in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Expanded(child: Center(child: Text(w, style: T.caption)))]),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: .95,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox(),
              for (var dd = 1; dd <= days; dd++)
                Builder(builder: (_) {
                  final date = DateTime(month.year, month.month, dd);
                  final es = ev.where((e) => _same(e.date, date)).toList();
                  final isSel = _same(date, sel), isToday = _same(date, today);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => sel = date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220), margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: isSel ? C.goldGradient : null, borderRadius: BorderRadius.circular(14),
                        border: isToday && !isSel ? Border.all(color: C.gold) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$dd', style: T.body.copyWith(color: isSel ? C.obsidian : C.text, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        SizedBox(height: 6, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (final e in es.take(3)) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(shape: BoxShape.circle, color: isSel ? C.obsidian : eventColor(e.type))),
                        ])),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        ])).rise(),
        SectionHeader(DateFormat('EEEE, d MMMM').format(sel)),
        if (dayEvents.isEmpty) Text('Nothing scheduled.', style: T.muted),
        for (final e in dayEvents)
          ListRow(
            leading: IconBadge(eventIcon(e.type), color: eventColor(e.type)), title: e.title, subtitle: e.subtitle,
            onTap: e.cardId.isNotEmpty && ref.read(dataProvider).card(e.cardId) != null ? () => openCard(context, e.cardId) : null,
          ),
        const SectionHeader('Next 30 days'),
        for (final e in ev.where((e) => !e.date.isBefore(DateTime(today.year, today.month, today.day)) && e.date.isBefore(today.add(const Duration(days: 30)))).take(12))
          ListRow(leading: IconBadge(eventIcon(e.type), color: eventColor(e.type)), title: e.title, subtitle: '${e.subtitle} · ${dShort(e.date)}', trailing: Text(relDays(e.date), style: T.caption.copyWith(color: C.gold))),
      ],
    );
  }
}

