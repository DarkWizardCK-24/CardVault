import 'dart:ui' show PointerDeviceKind;
import 'package:cardvault/ui/app_guard.dart';
import 'package:cardvault/ui/gate.dart';
import 'package:flutter/material.dart';
import 'package:cardvault/core/core.dart';
import 'package:cardvault/ui/routes/app_routes.dart';

class CardVaultApp extends StatelessWidget {
  const CardVaultApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CardVault',
        debugShowCheckedModeBanner: false,
        navigatorKey: navKey,
        theme: buildTheme(),
        darkTheme: buildTheme(),
        themeMode: ThemeMode.dark,
        scrollBehavior: const _AppScrollBehavior(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: .9,
          maxScaleFactor: 1.25, // keeps layouts intact for very large system fonts
          // Tapping any empty area closes the keyboard.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: AppGuard(child: child!),
          ),
        ),
        home: const Gate(),
      );
}


/// Lets mouse and trackpad drag-scroll lists on desktop and web, like touch on phones.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}
