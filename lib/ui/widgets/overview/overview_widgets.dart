import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// Logo, greeting and the search / lock / settings controls.
class OverviewHeader extends ConsumerWidget {
  const OverviewHeader({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(children: [
        const CvLogo(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting(), style: T.muted),
            Text('Your vault', style: T.h1),
          ]),
        ),
        IconPill(Icons.search_rounded, () => openSearch(context), tooltip: 'Search'),
        const SizedBox(width: 8),
        IconPill(Icons.lock_outline_rounded, () {
          HapticFeedback.mediumImpact();
          ref.read(authProvider.notifier).lock();
        }, tooltip: 'Lock vault'),
        const SizedBox(width: 8),
        IconPill(Icons.settings_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), tooltip: 'Settings'),
      ]);
}

/// Horizontally scrolling row of shortcut buttons.
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.add_card_rounded, 'Add card', () => openCardForm(context)),
      (Icons.credit_card_rounded, 'All cards', () => ref.read(tabProvider.notifier).set(1)),
      (Icons.add_chart_rounded, 'Transaction', () => txnForm(context, ref)),
      (Icons.card_giftcard_rounded, 'Benefits', () => ref.read(tabProvider.notifier).set(3)),
      (Icons.payments_outlined, 'Payments', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentPlannerScreen()))),
      (Icons.emergency_outlined, 'Emergency', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectoryScreen()))),
    ];
    Widget item(int i) => Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            items[i].$3();
          },
          child: SizedBox(
            width: 74,
            child: Column(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06), border: Border.all(color: C.border)),
                child: Icon(items[i].$1, color: C.gold, size: 24),
              ),
              const SizedBox(height: 8),
              Text(items[i].$2, style: T.caption.copyWith(color: C.text), maxLines: 1),
            ]),
          ).rise(i),
        );
    return LayoutBuilder(builder: (context, box) {
      final fits = box.maxWidth >= items.length * 74 + (items.length - 1) * 12;
      return SizedBox(
        height: 92,
        child: fits
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (var i = 0; i < items.length; i++) item(i)])
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => item(i)),
      );
    });
  }
}

/// The eight manually-maintained financial figures.
class FinancialGrid extends StatelessWidget {
  final VaultData data;
  const FinancialGrid(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = data;
    final upcomingTotal = d.creditCards.where((c) => c.dueDay > 0).fold(0.0, (a, c) => a + c.outstanding);
    final tiles = <Widget>[
      StatTile('Active credit cards', '${d.activeCredit}', Icons.credit_card_rounded),
      StatTile('Active debit cards', '${d.activeDebit}', Icons.account_balance_rounded),
      StatTile('Total credit limit', compactMoney(d.totalLimit), Icons.speed_rounded),
      StatTile('Outstanding', compactMoney(d.totalOutstanding), Icons.account_balance_wallet_outlined, color: C.warn, foot: '${d.utilization.toStringAsFixed(0)}% utilised'),
      StatTile('Available credit', compactMoney(d.totalAvailable), Icons.savings_outlined, color: C.good),
      StatTile('Upcoming payments', compactMoney(upcomingTotal), Icons.event_available_outlined, color: C.warn),
      StatTile('Annual card fees', compactMoney(d.annualFees), Icons.receipt_long_outlined),
      StatTile('Reward points', d.rewardPoints.toStringAsFixed(0), Icons.stars_rounded),
    ];
    return StatGrid(children: [for (final (i, t) in tiles.indexed) t.rise(i)]);
  }
}

/// Next few dated events (billing, dues, expiries, renewals).
class UpcomingSection extends StatelessWidget {
  final VaultData data;
  const UpcomingSection(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    final events = buildEvents(data, monthsAhead: 3).where((e) => !e.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))).take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader('Upcoming', trailing: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())), child: const Text('Calendar'))),
      if (events.isEmpty) Text('No upcoming dates. Add billing days, due days or benefit expiries to see them here.', style: T.muted),
      for (final e in events)
        ListRow(
          leading: IconBadge(eventIcon(e.type), color: eventColor(e.type)),
          title: e.title,
          subtitle: '${e.subtitle} · ${dShort(e.date)}',
          trailing: Text(relDays(e.date), style: T.caption.copyWith(color: C.gold)),
          onTap: e.cardId.isNotEmpty && data.card(e.cardId) != null ? () => openCard(context, e.cardId) : null,
        ),
    ]);
  }
}

/// Locally recorded changes and transactions.
class RecentActivity extends StatelessWidget {
  final VaultData data;
  const RecentActivity(this.data, {super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHeader('Recent activity'),
        if (data.activity.isEmpty) Text('Changes and transactions you record will appear here.', style: T.muted),
        for (final a in data.activity.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle)),
              const SizedBox(width: 14),
              Expanded(child: Text(a.text, style: T.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(relDays(a.at), style: T.caption),
            ]),
          ),
      ]);
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Glass(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
        tint: [C.gold.withValues(alpha: .16), C.gold.withValues(alpha: .04)],
        child: Row(children: [
          const IconBadge(Icons.backup_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(last == null ? 'Back up your vault' : 'Backup is ${DateTime.now().difference(last).inDays} days old', style: T.h3),
              Text('Export an encrypted file so you can restore on a new device.', style: T.muted),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.gold),
        ]),
      ),
    ).rise();
  }
}
