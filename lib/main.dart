import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardvault/ui/app.dart';
import 'package:cardvault/core/services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF08090B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: CardVaultApp()));
}
