import 'package:flutter/material.dart';

class AppColors {
  static const violet = Color(0xFF7C4DFF);
  static const blue = Color(0xFF00B0FF);
  static const pink = Color(0xFFFF4D8D);
  static const green = Color(0xFF2ECC71);
  static const amber = Color(0xFFFFB84D);
  static const red = Color(0xFFFF5252);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, blue],
  );
  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5252), Color(0xFFFF4D8D)],
  );
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.violet, brightness: b);
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0B1020) : const Color(0xFFEEF1FF),
    fontFamilyFallback: const ['Segoe UI', 'Tahoma'],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2A2F4A) : const Color(0xFF23263A),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
