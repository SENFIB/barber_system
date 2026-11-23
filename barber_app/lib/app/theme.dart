import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'look.dart';

/// رنگ‌های پیش‌فرض (ثابت). رنگ‌های قابل‌تغییر از LookExt می‌آیند.
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

ThemeData buildTheme(Brightness b, [AppLook? look]) {
  final lookV = look ?? const AppLook();
  final lk = lookV.resolve(b);
  final dark = lk.dark;

  var scheme = ColorScheme.fromSeed(seedColor: lk.primary, brightness: b);
  final onP = ThemeData.estimateBrightnessForColor(lk.primary) ==
          Brightness.dark
      ? Colors.white
      : Colors.black;
  scheme = scheme.copyWith(
    primary: lk.primary,
    onPrimary: onP,
    secondary: lk.secondary,
    tertiary: lk.accent,
    error: lk.danger,
    onSurface: lk.text ?? scheme.onSurface,
    onSurfaceVariant: lk.text?.withOpacity(0.75) ?? scheme.onSurfaceVariant,
  );

  final tmp = ThemeData(useMaterial3: true, brightness: b, colorScheme: scheme);
  var tt = tmp.textTheme;

  final f = lookV.font;
  String? family;
  // اگر فونتِ انتخابی حروف فارسی نداشته باشد، وزیرمتن جایگزین می‌شود
  final fallback = f.isEmpty
      ? const ['Segoe UI', 'Tahoma']
      : const [kDefaultFont, 'Segoe UI', 'Tahoma'];

  if (f == kDefaultFont) {
    family = kDefaultFont;
    tt = tt.apply(fontFamily: kDefaultFont);
  } else if (f.isNotEmpty) {
    try {
      tt = GoogleFonts.getTextTheme(f, tt);
    } catch (_) {
      family = kDefaultFont;
      tt = tt.apply(fontFamily: kDefaultFont);
    }
  }
  tt = tt.apply(fontFamilyFallback: fallback);

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    textTheme: tt,
    fontFamily: family,
    fontFamilyFallback: fallback,
    scaffoldBackgroundColor: lk.bg[0],
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
    extensions: <ThemeExtension<dynamic>>[lk],
  );
}
