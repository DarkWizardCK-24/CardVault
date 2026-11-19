import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';

/// One home for everything that is not a daily destination, so each feature has
/// exactly one entry point.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final last = d.settings.lastBackup == null ? null : DateTime.tryParse(d.settings.lastBackup!);

    final wallet = [
      HubItem(Icons.card_giftcard_rounded, 'Benefits', '${d.benefits.length} tracked', C.sunsetGradient, () => go(const BenefitsScreen())),
      HubItem(Icons.folder_rounded, 'Documents', '${d.docs.length} encrypted files', C.oceanGradient, () => go(const DocumentsScreen())),
      HubItem(Icons.collections_bookmark_rounded, 'Collections', '${d.collections.length} groups', C.goldGradient, () => go(const CollectionsScreen())),
      HubItem(Icons.support_agent_rounded, 'Bank directory', 'Helplines & lost card', C.emberGradient, () => go(const DirectoryScreen())),
    ];
    final safety = [
      HubItem(Icons.verified_user_rounded, 'Security', 'Unlock, auto-lock, password', C.oceanGradient, () => go(const SecurityScreen())),
      HubItem(Icons.cloud_upload_rounded, 'Backup & restore', last == null ? 'Never backed up' : 'Last ${relDays(last).toLowerCase()}', C.sunsetGradient, () => go(const BackupScreen())),
      HubItem(Icons.notifications_active_rounded, 'Reminders', d.settings.notificationsOn ? 'On' : 'Off', C.emberGradient, () => go(const RemindersScreen())),
      HubItem(Icons.info_outline_rounded, 'About & data', 'Version, erase vault', C.goldGradient, () => go(const SettingsScreen())),
    ];

    return Screen(
      title: 'More',
      subtitle: 'Everything else in your vault',
      children: [
        _VaultBanner(cards: d.liveCards.length, onLock: () {
          HapticFeedback.mediumImpact();
          ref.read(authProvider.notifier).lock();
        }).rise(),
        const SectionHeader('Wallet'),
        HubGrid(items: wallet),
        const SectionHeader('Security & data'),
        HubGrid(items: safety, offset: wallet.length),
      ],
    );
  }
}

class HubItem {
  final IconData icon;
  final String title, subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  const HubItem(this.icon, this.title, this.subtitle, this.gradient, this.onTap);
}

/// Responsive grid of gradient-icon tiles.
class HubGrid extends StatelessWidget {
  final List<HubItem> items;
  final int offset;
  const HubGrid({super.key, required this.items, this.offset = 0});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 640 ? 4 : 2;
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 128 + (scale - 1) * 60),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            return Glass(
              onTap: it.onTap,
              padding: const EdgeInsets.all(14),
              radius: 22,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: it.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: it.gradient.colors.first.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: Icon(it.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(it.title, style: T.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(it.subtitle, style: T.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ).rise(offset + i);
          },
        );
      });
}

class _VaultBanner extends StatelessWidget {
  final int cards;
  final VoidCallback onLock;
  const _VaultBanner({required this.cards, required this.onLock});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: C.auroraGradient,
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          boxShadow: [BoxShadow(color: C.violet.withValues(alpha: .14), blurRadius: 28, spreadRadius: -6, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          const CvLogo(size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vault secured', style: T.h2),
              const SizedBox(height: 2),
              Text('$cards card${cards == 1 ? '' : 's'} · offline · encrypted', style: T.muted.copyWith(color: C.text.withValues(alpha: .75))),
            ]),
          ),
          Pressable(
            onTap: onLock,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(gradient: C.goldGradient, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_rounded, size: 16, color: C.obsidian),
                const SizedBox(width: 6),
                Text('Lock', style: T.h3.copyWith(color: C.obsidian, fontSize: 13.5)),
              ]),
            ),
          ),
        ]),
      );
}
