import 'package:flutter/material.dart';

class DeenColors {
  static const background = Color(0xFFFFFFFF);
  static const text = Color(0xFF17251F);
  static const textSecondary = Color(0xFF777F79);
  static const accent = Color(0xFF176B50);
  static const sage = Color(0xFFEAF2ED);
  static const line = Color(0xFFD9E5DE);
  static const warn = Color(0xFF9A5B13);
}

String fontForLang(String lang) {
  switch (lang) {
    case 'ar':
      return 'Amiri';
    case 'en':
      return 'Inter';
    default:
      return 'NotoSansBengali';
  }
}

ThemeData buildTheme(String lang) {
  final family = fontForLang(lang);
  final scheme = ColorScheme.fromSeed(
    seedColor: DeenColors.accent,
    primary: DeenColors.accent,
    onPrimary: Colors.white,
    secondary: DeenColors.accent,
    surface: DeenColors.background,
    onSurface: DeenColors.text,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: family);
  return base.copyWith(
    scaffoldBackgroundColor: DeenColors.background,
    textTheme: base.textTheme.apply(bodyColor: DeenColors.text, displayColor: DeenColors.text),
    appBarTheme: AppBarTheme(
      backgroundColor: DeenColors.background,
      foregroundColor: DeenColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: family, fontSize: 20, fontWeight: FontWeight.w600, color: DeenColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DeenColors.sage,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DeenColors.accent, width: 1.4)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DeenColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DeenColors.background,
      indicatorColor: DeenColors.sage,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? DeenColors.accent : DeenColors.textSecondary)),
    ),
    dividerColor: DeenColors.line,
  );
}
