import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

const kMonthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Bottom sheet with month + year wheels. Returns the first day of the chosen month.
Future<DateTime?> pickMonthYear(BuildContext context,
    {DateTime? initial, int? firstYear, int? lastYear, String title = 'Select month & year', bool numericMonths = false}) {
  final now = DateTime.now();
  final fy = firstYear ?? now.year - 15, ly = lastYear ?? now.year + 25;
  final init = initial ?? DateTime(now.year, now.month);
  var m = init.month, y = init.year.clamp(fy, ly);
  return sheet<DateTime>(
    context,
    SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: T.h2),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Stack(children: [
              // selection band behind the wheels
              Center(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [C.gold.withValues(alpha: .18), C.violet.withValues(alpha: .14)]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.gold.withValues(alpha: .35)),
                  ),
                ),
              ),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: CupertinoPicker(
                    itemExtent: 44,
                    selectionOverlay: const SizedBox(),
                    scrollController: FixedExtentScrollController(initialItem: m - 1),
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      m = i + 1;
                    },
                    children: [
                      for (var i = 0; i < 12; i++)
                        Center(child: Text(numericMonths ? '${(i + 1).toString().padLeft(2, '0')} · ${kMonthNames[i].substring(0, 3)}' : kMonthNames[i], style: T.h3)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: CupertinoPicker(
                    itemExtent: 44,
                    selectionOverlay: const SizedBox(),
                    scrollController: FixedExtentScrollController(initialItem: y - fy),
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      y = fy + i;
                    },
                    children: [for (var v = fy; v <= ly; v++) Center(child: Text('$v', style: T.h3))],
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Builder(builder: (c) => GoldButton('Done', icon: Icons.check_rounded, onTap: () => Navigator.pop(c, DateTime(y, m)))),
        ]),
      ),
    ),
  );
}

/// Date picker sheet: a month grid with a tappable "Month Year" header that jumps
/// straight to any month and year, plus arrows for neighbouring months.
Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, String title = 'Select date', int? firstYear, int? lastYear}) {
  return sheet<DateTime>(context, _DateSheet(initial: initial, title: title, firstYear: firstYear, lastYear: lastYear));
}

class _DateSheet extends StatefulWidget {
  final DateTime? initial;
  final String title;
  final int? firstYear, lastYear;
  const _DateSheet({this.initial, required this.title, this.firstYear, this.lastYear});
  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime sel = widget.initial ?? DateTime.now();
  late DateTime month = DateTime(sel.year, sel.month);

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(widget.title, style: T.h2)),
            const SizedBox(height: 10),
            MonthHeader(
              month: month,
              onChanged: (m) => setState(() => month = m),
              firstYear: widget.firstYear,
              lastYear: widget.lastYear,
            ),
            const SizedBox(height: 8),
            MonthGrid(month: month, selected: sel, onSelect: (d) => setState(() => sel = d)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GoldButton('Today', outline: true, onTap: () {
                  final n = DateTime.now();
                  setState(() {
                    sel = n;
                    month = DateTime(n.year, n.month);
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(child: GoldButton('Select', icon: Icons.check_rounded, onTap: () => Navigator.pop(context, DateTime(sel.year, sel.month, sel.day)))),
            ]),
          ]),
        ),
      );
}

/// "‹  November 2026 ▾  ›" — tapping the label opens the month/year wheels.
class MonthHeader extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final int? firstYear, lastYear;
  const MonthHeader({super.key, required this.month, required this.onChanged, this.firstYear, this.lastYear});
  @override
  Widget build(BuildContext context) => Row(children: [
        IconPill(Icons.chevron_left_rounded, () => onChanged(DateTime(month.year, month.month - 1)), tooltip: 'Previous month'),
        Expanded(
          child: Center(
            child: Pressable(
              onTap: () async {
                final m = await pickMonthYear(context, initial: month, firstYear: firstYear, lastYear: lastYear);
                if (m != null) onChanged(m);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .03)]),
                  border: Border.all(color: C.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: 250.ms,
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a), child: c)),
                    child: Text(DateFormat('MMMM yyyy').format(month), key: ValueKey(month), style: T.h3),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more_rounded, size: 20, color: C.gold),
                ]),
              ),
            ),
          ),
        ),
        IconPill(Icons.chevron_right_rounded, () => onChanged(DateTime(month.year, month.month + 1)), tooltip: 'Next month'),
      ]);
}

/// A 7-column month grid (Sunday first). [dots] supplies up to three event colours per day.
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final List<Color> Function(DateTime day)? dots;
  const MonthGrid({super.key, required this.month, this.selected, required this.onSelect, this.dots});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    return Column(children: [
      Row(children: [for (final w in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Expanded(child: Center(child: Text(w, style: T.caption)))]),
      const SizedBox(height: 6),
      AnimatedSwitcher(
        duration: 280.ms,
        child: GridView.count(
          key: ValueKey(month),
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var dd = 1; dd <= days; dd++)
              Builder(builder: (_) {
                final date = DateTime(month.year, month.month, dd);
                final isSel = selected != null && sameDay(date, selected!);
                final isToday = sameDay(date, today);
                final ds = dots?.call(date) ?? const <Color>[];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(date);
                  },
                  child: AnimatedContainer(
                    duration: 220.ms,
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      gradient: isSel ? C.goldGradient : null,
                      color: isSel ? null : (ds.isNotEmpty ? Colors.white.withValues(alpha: .04) : null),
                      borderRadius: BorderRadius.circular(14),
                      border: isToday && !isSel ? Border.all(color: C.gold, width: 1.3) : null,
                      boxShadow: isSel ? [BoxShadow(color: C.gold.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4))] : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$dd', style: T.body.copyWith(color: isSel ? C.obsidian : C.text, fontWeight: isSel || isToday ? FontWeight.w800 : FontWeight.w500)),
                      if (ds.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (final c in ds.take(3))
                            Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(shape: BoxShape.circle, color: isSel ? C.obsidian : c)),
                        ]),
                      ],
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    ]);
  }
}

/// Form-style tile showing a month/year (e.g. card expiry). Opens the wheels on tap.
class MonthYearTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final int? firstYear, lastYear;
  const MonthYearTile(this.label, this.value, this.onChanged, {super.key, this.firstYear, this.lastYear});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          FocusScope.of(context).unfocus();
          final d = await pickMonthYear(context, initial: value, title: label, firstYear: firstYear, lastYear: lastYear, numericMonths: true);
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.event_rounded, size: 18, color: C.gold)),
          child: Text('${value.month.toString().padLeft(2, '0')} / ${value.year}   ·   ${DateFormat('MMMM yyyy').format(value)}', style: T.body),
        ),
      );
}
