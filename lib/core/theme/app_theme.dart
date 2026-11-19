import 'package:flutter/material.dart';

/// CardVault design tokens — Premium Dark Luxury.
class C {
  static const obsidian = Color(0xFF08090B);
  static const graphite = Color(0xFF111318);
  static const charcoal = Color(0xFF191C22);
  static const raised = Color(0xFF20242C);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF969BA5);
  static const gold = Color(0xFFD6B779);
  static const goldDeep = Color(0xFF9C7F44);
  static const silver = Color(0xFFB8BEC8);
  static const border = Color(0x1FFFFFFF);
  static const good = Color(0xFF6FCF97);
  static const warn = Color(0xFFE9B949);
  static const bad = Color(0xFFEB6B6B);
  // accents
  static const violet = Color(0xFF9B7BFF);
  static const teal = Color(0xFF3DD9C1);
  static const rose = Color(0xFFFF7A9C);
  static const sky = Color(0xFF6EB6FF);
  static const amber = Color(0xFFFFB45C);

  static const auroraGradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF2B1B5A), Color(0xFF173A63), Color(0xFF0E4B4B)]);
  static const sunsetGradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFFF7A9C), Color(0xFFB45CFF)]);
  static const oceanGradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF3DD9C1), Color(0xFF6EB6FF)]);
  static const emberGradient = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFFFB45C), Color(0xFFFF6B6B)]);
  static const goldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBD3A0), gold, goldDeep]);
}

class T {
  static TextStyle _b(double s, double w, Color c, {double? h, double? ls}) => TextStyle(
      fontFamily: 'Inter',
      fontSize: s,
      color: c,
      height: h,
      letterSpacing: ls,
      fontWeight: FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', w)]);
  static TextStyle display(double s, {Color c = C.text}) => TextStyle(
      fontFamily: 'Playfair',
      fontSize: s,
      color: c,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
      height: 1.15);
  static TextStyle h1 = _b(26, 700, C.text, ls: -.4);
  static TextStyle h2 = _b(19, 650, C.text, ls: -.2);
  static TextStyle h3 = _b(15.5, 600, C.text);
  static TextStyle body = _b(14, 450, C.text, h: 1.4);
  static TextStyle muted = _b(13, 450, C.muted, h: 1.35);
  static TextStyle caption = _b(11.5, 550, C.muted, ls: .6);
  static TextStyle label = _b(12, 650, C.gold, ls: 1.2);
  static TextStyle num(double s, {Color c = C.text}) => _b(s, 650, c, ls: -.3);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  const cs = ColorScheme.dark(
      primary: C.gold,
      onPrimary: C.obsidian,
      secondary: C.silver,
      surface: C.graphite,
      onSurface: C.text,
      error: C.bad,
      surfaceContainerHighest: C.charcoal);
  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: C.obsidian,
    canvasColor: C.graphite,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: C.text, displayColor: C.text),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: LuxTransitions(),
      TargetPlatform.iOS: LuxTransitions(),
      TargetPlatform.windows: LuxTransitions(),
      TargetPlatform.macOS: LuxTransitions(),
    }),
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: T.h2,
        foregroundColor: C.text),
    dividerColor: C.border,
    dialogTheme: DialogThemeData(
        backgroundColor: C.charcoal,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), side: const BorderSide(color: C.border)),
        titleTextStyle: T.h2),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: C.graphite,
        modalBackgroundColor: C.graphite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.charcoal,
      labelStyle: T.muted,
      hintStyle: T.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: ob(C.border),
      enabledBorder: ob(C.border),
      focusedBorder: ob(C.gold, 1.2),
      errorBorder: ob(C.bad),
      focusedErrorBorder: ob(C.bad),
    ),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: C.raised,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: T.body,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.obsidian : C.muted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.gold : C.raised),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.gold),
    iconTheme: const IconThemeData(color: C.text),
    dividerTheme: const DividerThemeData(color: C.border, space: 1, thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: C.gold, selectionColor: C.gold.withValues(alpha: .30), selectionHandleColor: C.gold),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: C.gold,
      inactiveTrackColor: Colors.white.withValues(alpha: .14),
      thumbColor: const Color(0xFFEBD3A0),
      overlayColor: C.gold.withValues(alpha: .16),
      valueIndicatorColor: C.raised,
      valueIndicatorTextStyle: T.caption.copyWith(color: C.text),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3, pressedElevation: 6),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.gold : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(C.obsidian),
      side: const BorderSide(color: C.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: .05),
      selectedColor: C.gold.withValues(alpha: .22),
      checkmarkColor: C.gold,
      side: const BorderSide(color: C.border),
      labelStyle: T.body.copyWith(fontSize: 13),
      shape: const StadiumBorder(),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: C.charcoal,
      surfaceTintColor: Colors.transparent,
      textStyle: T.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.border)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(C.charcoal),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.border))),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: C.charcoal,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: C.raised,
      headerForegroundColor: C.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: C.border)),
      todayForegroundColor: const WidgetStatePropertyAll(C.gold),
      todayBorder: const BorderSide(color: C.gold),
      dayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.obsidian : C.text),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      textStyle: T.caption.copyWith(color: C.text, letterSpacing: .2),
      decoration: BoxDecoration(color: C.raised, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: .22)),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(5),
    ),
    listTileTheme: const ListTileThemeData(iconColor: C.silver, textColor: C.text),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: C.gold, textStyle: T.h3.copyWith(fontSize: 13.5))),
    focusColor: C.gold.withValues(alpha: .14),
    hoverColor: Colors.white.withValues(alpha: .04),
  );
}

/// Fade + slide + subtle scale page transition used on every platform.
class LuxTransitions extends PageTransitionsBuilder {
  const LuxTransitions();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondary, Widget child) {
    final curved = CurvedAnimation(
        parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final sec = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
        child: ScaleTransition(scale: Tween(begin: 1.0, end: 0.97).animate(sec), child: child),
      ),
    );
  }
}

