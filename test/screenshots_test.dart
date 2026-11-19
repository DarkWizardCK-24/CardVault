// Drives the real app (setup -> unlock -> every major screen) on phone, tablet and desktop
// viewports and renders PNGs into docs/screenshots/<device>-<screen>.png.
//
//   python tool/capture_screenshots.py          (runs this test, then builds the thumbnails)
//   flutter test test/screenshots_test.dart --update-goldens
import 'dart:io';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/app.dart';
import 'package:cardvault/ui/routes/app_routes.dart';
import 'package:cardvault/ui/screens/screens.dart';
import 'package:cardvault/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  for (final f in {'Inter': 'assets/fonts/Inter.ttf', 'Playfair': 'assets/fonts/Playfair.ttf'}.entries) {
    final l = FontLoader(f.key)..addFont(Future.value(ByteData.sublistView(File(f.value).readAsBytesSync())));
    await l.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await l.load();
  }
}

class Device {
  final String name;
  final Size logical;
  final double dpr;
  final Set<String> shots;
  const Device(this.name, this.logical, this.dpr, this.shots);
}

// Same device sizes as the other showcase projects: phone 390x844 @3x, tablet 820x1180 @2x, desktop 1440x900 @1.5x.
const devices = [
  Device('mobile', Size(390, 844), 3, {
    'welcome', 'home', 'card-deck', 'deck-expanded', 'card-details', 'card-back', 'add-card', 'collections', 'benefits',
    'benefit-details', 'calendar', 'spending', 'insights', 'payments', 'calculators', 'documents', 'security',
    'backup-restore', 'emergency', 'compare', 'locked',
  }),
  Device('tablet', Size(820, 1180), 2, {'home', 'card-vault', 'insights', 'calendar'}),
  Device('desktop', Size(1440, 900), 1.5, {'home', 'card-vault', 'calculators', 'benefits', 'spending', 'insights', 'backup-restore', 'security'}),
];

void main() {
  for (final dev in devices) {
    testWidgets('journey + screenshots (${dev.name})', (tester) async {
      await loadFonts();
      Crypt.kdfIterations = 1000;
      tester.view.physicalSize = Size(dev.logical.width * dev.dpr, dev.logical.height * dev.dpr);
      tester.view.devicePixelRatio = dev.dpr;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(overrides: [
        kvProvider.overrideWithValue(MemoryKv()),
        storeProvider.overrideWithValue(MemoryStore()),
      ]);
      addTearDown(container.dispose);

      Future<void> snap(String name, [int ms = 900]) async {
        if (!dev.shots.contains(name)) return;
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(Duration(milliseconds: ms));
        await tester.pump(const Duration(milliseconds: 700));
        await expectLater(find.byType(CardVaultApp), matchesGoldenFile('../docs/screenshots/${dev.name}-$name.png'));
      }

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const CardVaultApp()));
      // images decode on real I/O, so warm the cache outside fake-async
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(MaterialApp).first);
        for (final a in ['logo_256', 'hero_cards', 'empty_vault', 'shield']) {
          await precacheImage(AssetImage('assets/images/$a.png'), ctx);
        }
      });
      await tester.pump(const Duration(seconds: 4));
      expect(container.read(authProvider).status, AuthStatus.needsSetup);
      await snap('welcome');

      final auth = container.read(authProvider.notifier);
      await tester.runAsync(() async {
        await auth.setup('hunter2hunter');
        await auth.finishSetup();
      });
      await tester.pump(const Duration(milliseconds: 800));
      expect(container.read(authProvider).status, AuthStatus.unlocked);

      await tester.runAsync(() async => loadDemo(container.read(dataProvider.notifier), container.read(dataProvider)));
      await tester.pump(const Duration(milliseconds: 800));
      expect(container.read(dataProvider).cards.length, 6);
      await snap('home');

      // vertical swipe moves the deck selection
      final before = container.read(selectedCardProvider);
      await tester.drag(find.byType(CardDeck).first, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 900));
      expect(container.read(selectedCardProvider), isNot(before));

      Future<void> tab(int i, String name) async {
        container.read(tabProvider.notifier).set(i);
        await tester.pump(const Duration(milliseconds: 200));
        await snap(name);
      }

      await tab(1, dev.name == 'mobile' ? 'card-deck' : 'card-vault');
      await tab(2, 'calculators');
      await tab(3, 'benefits');
      await tab(4, 'documents');
      await tab(5, 'security');

      Future<void> push(Widget w, String name, {Future<void> Function()? during}) async {
        navKey.currentState!.push(MaterialPageRoute(builder: (_) => w));
        await tester.pump(const Duration(milliseconds: 300));
        await snap(name);
        if (during != null) await during();
        navKey.currentState!.pop();
        await tester.pump(const Duration(milliseconds: 400));
      }

      final d = container.read(dataProvider);
      await push(const Screen(title: 'Card Vault', subtitle: '6 cards secured', maxWidth: 1180, children: [DeckSection(initialExpanded: true)]), 'deck-expanded');
      await push(CardDetailScreen(d.cards.first.id), 'card-details', during: () async {
        if (!dev.shots.contains('card-back')) return;
        await tester.tap(find.byType(FlipCard).first);
        await tester.pump(const Duration(milliseconds: 900));
        await snap('card-back', 100);
      });
      await push(const CardFormScreen(null), 'add-card');
      await push(const CollectionsScreen(), 'collections');
      await push(const CalendarScreen(), 'calendar');
      await push(const SpendingScreen(), 'spending');
      await push(const InsightsScreen(), 'insights');
      await push(const PaymentPlannerScreen(), 'payments');
      await push(BenefitDetailScreen(d.benefits.first.id), 'benefit-details');
      await push(const BackupScreen(), 'backup-restore');
      await push(const DirectoryScreen(), 'emergency');
      await push(const CompareScreen(), 'compare');

      await tester.runAsync(() async => auth.lock());
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(authProvider).status, AuthStatus.locked);
      expect(container.read(dataProvider).cards, isEmpty, reason: 'data is purged from memory on lock');
      await snap('locked');
      await tester.runAsync(() async => auth.unlockWithPassword('hunter2hunter'));
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(authProvider).status, AuthStatus.unlocked);
      expect(container.read(dataProvider).cards.length, 6);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
