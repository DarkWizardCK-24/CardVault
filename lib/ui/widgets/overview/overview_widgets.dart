import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Logo, greeting and the search / lock controls.
class OverviewHeader extends ConsumerWidget {
  const OverviewHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(children: [
        const CvLogo(size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting(), style: T.muted),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [C.text, Color(0xFFEBD3A0)]).createShader(r),
              child: Text('Your vault', style: T.h1.copyWith(color: Colors.white)),
            ),
          ]),
        ),
        IconPill(Icons.search_rounded, () => openSearch(context), tooltip: 'Search'),
        const SizedBox(width: 8),
        IconPill(Icons.lock_outline_rounded, () {
          HapticFeedback.mediumImpact();
          ref.read(authProvider.notifier).lock();
        }, tooltip: 'Lock vault'),
      ]);
}

/// Gradient summary of everything the user entered: balance, available credit and utilisation.
class HeroSummary extends StatelessWidget {
  final VaultData data;
  const HeroSummary(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = data;
    final u = d.utilization.clamp(0, 100) / 100;
    final uColor = u > .7 ? C.bad : (u > .4 ? C.warn : C.teal);
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: C.auroraGradient,
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [BoxShadow(color: C.violet.withValues(alpha: .14), blurRadius: 28, spreadRadius: -6, offset: const Offset(0, 10))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -40,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [C.gold.withValues(alpha: .28), Colors.transparent])),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('TOTAL OUTSTANDING', style: T.caption.copyWith(color: C.text.withValues(alpha: .7))),
            const Spacer(),
            _Pill('${d.activeCredit} credit · ${d.activeDebit} debit'),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(d.totalOutstanding), style: T.num(34)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(children: [
              Container(height: 8, color: Colors.white.withValues(alpha: .12)),
              FractionallySizedBox(
                widthFactor: u.toDouble(),
                child: Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [C.teal, uColor]))),
              ).animate().scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 900.ms, curve: Curves.easeOutCubic),
            ]),
          ),
          const SizedBox(height: 8),
          Text('${d.utilization.toStringAsFixed(0)}% of your credit limit used', style: T.caption.copyWith(color: C.text.withValues(alpha: .7))),
          const SizedBox(height: 16),
          Row(children: [
            _Figure('Available', compactMoney(d.totalAvailable), C.teal),
            _Figure('Total limit', compactMoney(d.totalLimit), C.sky),
            _Figure('Rewards', compactNum(d.rewardPoints), C.gold),
          ]),
        ]),
      ]),
    );
  }
}

String compactNum(double v) => v >= 100000 ? '${(v / 100000).toStringAsFixed(1)}L' : (v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0));

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: .10)),
        child: Text(text, style: T.caption.copyWith(color: C.text, letterSpacing: .2)),
      );
}

class _Figure extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Figure(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: T.caption.copyWith(color: C.text.withValues(alpha: .7)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: T.num(17))),
        ]),
      );
}

/// Four create-something shortcuts. Navigation lives in the tab bar, so nothing here repeats it.
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.add_card_rounded, 'Add card', C.goldGradient, () => openCardForm(context)),
      (Icons.receipt_long_rounded, 'Spend', C.oceanGradient, () => txnForm(context, ref)),
      (Icons.payments_rounded, 'Payment', C.emberGradient, () => addPayment(context, ref)),
      (Icons.card_giftcard_rounded, 'Benefit', C.sunsetGradient, () => addBenefit(context, ref)),
    ];
    return Row(children: [
      for (var i = 0; i < items.length; i++)
        Expanded(
          child: Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              items[i].$4();
            },
            child: Column(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: items[i].$3,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: items[i].$3.colors.first.withValues(alpha: .32), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Icon(items[i].$1, color: Colors.white, size: 25),
              ),
              const SizedBox(height: 8),
              Text(items[i].$2, style: T.caption.copyWith(color: C.text), maxLines: 1),
            ]),
          ).rise(i),
        ),
    ]);
  }
}

/// Small stat row under the hero (only the figures the hero does not show).
class FinancialGrid extends StatelessWidget {
  final VaultData data;
  const FinancialGrid(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = data;
    final due = d.creditCards.where((c) => c.dueDay > 0).fold(0.0, (a, c) => a + c.outstanding);
    final expiring = d.liveCards.where((c) => c.expiringSoon).length;
    final tiles = <Widget>[
      StatTile('Payments due', compactMoney(due), Icons.event_available_rounded, color: C.amber),
      StatTile('Annual fees', compactMoney(d.annualFees), Icons.receipt_long_rounded, color: C.rose),
      StatTile('Monthly subscriptions', compactMoney(d.monthlySubs), Icons.autorenew_rounded, color: C.violet),
      StatTile('Expiring in 90 days', '$expiring', Icons.hourglass_bottom_rounded, color: expiring > 0 ? C.warn : C.teal),
    ];
    return StatGrid(minTile: 150, tileHeight: 118, children: [for (final (i, t) in tiles.indexed) t.rise(i)]);
  }
}

/// Cards that expire within 90 days (or already have), so renewals are never missed.
class ExpiringCards extends StatelessWidget {
  final VaultData data;
  const ExpiringCards(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final list = data.liveCards.where((c) => c.expiringSoon || (c.isExpired && c.status == CardStatus.active)).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Expiring soon'),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = list[i];
            final col = c.isExpired ? C.bad : C.warn;
            return Glass(
              onTap: () => openCard(context, c.id),
              padding: const EdgeInsets.all(12),
              radius: 20,
              tint: [col.withValues(alpha: .14), col.withValues(alpha: .03)],
              child: Row(children: [
                MiniCard(c, width: 70),
                const SizedBox(width: 12),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.title, style: T.h3, maxLines: 1),
                  const SizedBox(height: 2),
                  Text(c.isExpired ? 'Expired ${dMonth(c.expiryDate)}' : 'In ${c.daysToExpiry} days · ${c.expMonth.toString().padLeft(2, '0')}/${c.expYear % 100}',
                      style: T.caption.copyWith(color: col)),
                ]),
              ]),
            ).rise(i);
          },
        ),
      ),
    ]);
  }
}

/// Next few dated events (billing, dues, expiries, renewals).
class UpcomingSection extends ConsumerWidget {
  final VaultData data;
  const UpcomingSection(this.data, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = buildEvents(data, monthsAhead: 3).where((e) => !e.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))).take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader('Upcoming', trailing: TextButton(onPressed: () => ref.read(tabProvider.notifier).set(2), child: const Text('Calendar'))),
      if (events.isEmpty)
        const _SoftEmpty(Icons.event_note_rounded, 'No upcoming dates', 'Statement days, due dates, expiries and renewals will show up here.')
      else
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (final (i, e) in events.indexed) ...[
              if (i > 0) const Divider(height: 1),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: e.cardId.isNotEmpty && data.card(e.cardId) != null ? () => openCard(context, e.cardId) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    _DateBadge(e.date, eventColor(e.type)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: T.h3.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(e.subtitle, style: T.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Text(relDays(e.date), style: T.caption.copyWith(color: eventColor(e.type))),
                  ]),
                ),
              ),
            ],
          ]),
        ).rise(),
    ]);
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime d;
  final Color color;
  const _DateBadge(this.d, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .30), color.withValues(alpha: .10)]),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${d.day}', style: T.num(16)),
          Text(kMonthNames[d.month - 1].substring(0, 3).toUpperCase(), style: T.caption.copyWith(fontSize: 9.5, color: color)),
        ]),
      );
}

class _SoftEmpty extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const _SoftEmpty(this.icon, this.title, this.message);
  @override
  Widget build(BuildContext context) => Glass(
        child: Row(children: [
          IconBadge(icon, color: C.violet),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: T.h3), Text(message, style: T.muted)])),
        ]),
      );
}

// ----------------------------------------------------------------- activity
(IconData, Color) activityStyle(String icon) => switch (icon) {
      'card' => (Icons.credit_card_rounded, C.gold),
      'trash' => (Icons.delete_outline_rounded, C.bad),
      'folder' => (Icons.collections_bookmark_rounded, C.violet),
      'receipt' => (Icons.receipt_long_rounded, C.sky),
      'pay' => (Icons.check_circle_rounded, C.good),
      'backup' => (Icons.cloud_done_rounded, C.teal),
      _ => (Icons.bolt_rounded, C.amber),
    };

String _bucket(DateTime d) {
  final r = relDays(d);
  if (r == 'Today' || r == 'Yesterday') return r;
  final days = DateTime.now().difference(d).inDays;
  return days < 7 ? 'This week' : 'Earlier';
}

String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Timeline of recent changes, grouped by day. Shows the latest few with a link to the full log.
class RecentActivity extends StatelessWidget {
  final VaultData data;
  const RecentActivity(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final items = data.activity.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader('Recent activity',
          trailing: data.activity.length > items.length
              ? TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())), child: const Text('View all'))
              : null),
      if (items.isEmpty)
        const _SoftEmpty(Icons.history_rounded, 'Nothing yet', 'Cards, payments and transactions you record will appear here.')
      else
        Glass(padding: const EdgeInsets.fromLTRB(14, 8, 14, 8), child: ActivityTimeline(items)).rise(),
    ]);
  }
}

class ActivityTimeline extends StatelessWidget {
  final List<Activity> items;
  const ActivityTimeline(this.items, {super.key});
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    String? last;
    for (var i = 0; i < items.length; i++) {
      final a = items[i];
      final b = _bucket(a.at);
      if (b != last) {
        rows.add(Padding(padding: EdgeInsets.only(top: last == null ? 6 : 14, bottom: 6), child: Text(b.toUpperCase(), style: T.caption.copyWith(color: C.gold))));
        last = b;
      }
      final (icon, color) = activityStyle(a.icon);
      final isLastInGroup = i == items.length - 1 || _bucket(items[i + 1].at) != b;
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 34,
            child: Column(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .16), border: Border.all(color: color.withValues(alpha: .45))),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLastInGroup) Expanded(child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 3), color: C.border)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 7, bottom: isLastInGroup ? 4 : 14),
              child: Text(a.text, style: T.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 9, left: 8), child: Text(_time(a.at), style: T.caption)),
        ]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// Gentle nudge to export an encrypted backup (device-change insurance).
class BackupReminderBanner extends StatelessWidget {
  final VaultData data;
  const BackupReminderBanner(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    if (data.cards.isEmpty) return const SizedBox.shrink();
    final last = data.settings.lastBackup == null ? null : DateTime.tryParse(data.settings.lastBackup!);
    final stale = last == null || DateTime.now().difference(last).inDays > 30;
    if (!stale) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Glass(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
        tint: [C.rose.withValues(alpha: .16), C.violet.withValues(alpha: .06)],
        child: Row(children: [
          const IconBadge(Icons.cloud_upload_rounded, color: C.rose),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(last == null ? 'Back up your vault' : 'Backup is ${DateTime.now().difference(last).inDays} days old', style: T.h3),
              Text('Export an encrypted file so you can restore on a new device.', style: T.muted),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.rose),
        ]),
      ),
    ).rise();
  }
}
