import 'dart:convert';
import 'package:flutter/material.dart';

class LookPreset {
  const LookPreset(
      this.id, this.primary, this.secondary, this.accent, this.dark, this.light);
  final String id;
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> dark;
  final List<Color> light;
}

const kPresets = <LookPreset>[
  LookPreset(
    'aurora',
    Color(0xFF7C4DFF),
    Color(0xFF00B0FF),
    Color(0xFFFF4D8D),
    [Color(0xFF0B1020), Color(0xFF1A1440), Color(0xFF0A1D30)],
    [Color(0xFFEEF1FF), Color(0xFFF7EEFF), Color(0xFFE6F5FF)],
  ),
  LookPreset(
    'ocean',
    Color(0xFF0091EA),
    Color(0xFF00BFA5),
    Color(0xFF3D5AFE),
    [Color(0xFF06141F), Color(0xFF0A2540), Color(0xFF05303A)],
    [Color(0xFFE6F6FF), Color(0xFFE3F3F6), Color(0xFFEAF1FF)],
  ),
  LookPreset(
    'sunset',
    Color(0xFFFF6B35),
    Color(0xFFFF3D81),
    Color(0xFFFFC107),
    [Color(0xFF1A0F14), Color(0xFF3A1220), Color(0xFF2B1A0E)],
    [Color(0xFFFFF1E8), Color(0xFFFFE9F0), Color(0xFFFFF6DD)],
  ),
  LookPreset(
    'forest',
    Color(0xFF2E9E5B),
    Color(0xFF00A58E),
    Color(0xFF9CCC00),
    [Color(0xFF08150F), Color(0xFF0F2A1C), Color(0xFF0A2024)],
    [Color(0xFFEAF8EF), Color(0xFFE6F6EE), Color(0xFFF1F8E6)],
  ),
  LookPreset(
    'rose',
    Color(0xFFE91E63),
    Color(0xFFAB47BC),
    Color(0xFFFF80AB),
    [Color(0xFF1A0A14), Color(0xFF2E1030), Color(0xFF220A1C)],
    [Color(0xFFFFEAF2), Color(0xFFF7E9FB), Color(0xFFFFEEF5)],
  ),
  LookPreset(
    'gold',
    Color(0xFFB8860B),
    Color(0xFFE0A800),
    Color(0xFF8D6E63),
    [Color(0xFF0C0B0A), Color(0xFF1A1610), Color(0xFF14110C)],
    [Color(0xFFFAF5E8), Color(0xFFFFF9EA), Color(0xFFF4EEDD)],
  ),
  LookPreset(
    'mono',
    Color(0xFF37474F),
    Color(0xFF78909C),
    Color(0xFF546E7A),
    [Color(0xFF0D0F10), Color(0xFF1A1D1F), Color(0xFF121516)],
    [Color(0xFFF0F2F3), Color(0xFFE9ECEE), Color(0xFFF5F6F7)],
  ),
  LookPreset(
    'neon',
    Color(0xFFD500F9),
    Color(0xFF00B8D4),
    Color(0xFF64DD17),
    [Color(0xFF07040F), Color(0xFF180A2E), Color(0xFF03161F)],
    [Color(0xFFF6EBFF), Color(0xFFEAF9FF), Color(0xFFF2FFE6)],
  ),
];

LookPreset presetById(String id) =>
    kPresets.firstWhere((p) => p.id == id, orElse: () => kPresets.first);

const kBgModes = <String>[
  'blobs',
  'gradient',
  'waves',
  'dots',
  'stripes',
  'solid',
  'image',
];

/// فونت پیش‌فرض برنامه؛ داخل خود برنامه بسته‌بندی شده (assets/fonts)
const kDefaultFont = 'Vazirmatn';

/// نام خانواده‌ی فونت‌ها ('' یعنی فونت سیستم).
/// Vazirmatn از داخل برنامه خوانده می‌شود و بقیه از Google Fonts.
const kFontFamilies = <String>[
  'Vazirmatn',
  'Noto Sans Arabic',
  'Noto Naskh Arabic',
  'Cairo',
  'Tajawal',
  'Almarai',
  'Amiri',
  'Changa',
  'El Messiri',
  'Reem Kufi',
  'Lalezar',
  'Inter',
  'Poppins',
  'Playfair Display',
];

/// نسخه‌ی «حل‌شده» برای حالت تیره یا روشن؛ از طریق ThemeData در همه‌جا در دسترس است
class LookExt extends ThemeExtension<LookExt> {
  const LookExt({
    required this.dark,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.danger,
    required this.bg,
    required this.card,
    required this.text,
    required this.glassBlur,
    required this.glassOpacity,
    required this.radius,
    required this.bgMode,
    required this.bgImage,
    required this.bgBlur,
    required this.bgDim,
  });

  final bool dark;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color danger;
  final List<Color> bg;
  final Color? card;
  final Color? text;
  final double glassBlur;
  final double glassOpacity;
  final double radius;
  final String bgMode;
  final String bgImage;
  final double bgBlur;
  final double bgDim;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary],
      );

  LinearGradient get dangerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [danger, Color.lerp(danger, const Color(0xFFFF4D8D), 0.6)!],
      );

  /// رنگ متنِ روی دکمه‌های گرادیانی
  Color get onPrimary =>
      (primary.computeLuminance() + secondary.computeLuminance()) / 2 > 0.6
          ? Colors.black87
          : Colors.white;

  Color get cardBase =>
      card ??
      (dark
          ? Colors.white.withOpacity(0.07)
          : Colors.white.withOpacity(0.62));

  Color get cardFill => cardBase
      .withOpacity((cardBase.opacity * glassOpacity).clamp(0.0, 1.0));

  Color get cardBorder =>
      dark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.9);

  static LookExt fallback(bool dark) =>
      const AppLook().resolve(dark ? Brightness.dark : Brightness.light);

  @override
  LookExt copyWith() => this;

  @override
  LookExt lerp(ThemeExtension<LookExt>? other, double t) {
    if (other is! LookExt) return this;
    return t < 0.5 ? this : other;
  }
}

/// تنظیمات ظاهر که کاربر انتخاب کرده (در حافظه‌ی گوشی به‌صورت JSON ذخیره می‌شود)
class AppLook {
  const AppLook({
    this.preset = 'aurora',
    this.colors = const {},
    this.bgMode = 'blobs',
    this.bgImage = '',
    this.bgBlur = 0,
    this.bgDim = 0.25,
    this.font = kDefaultFont,
    this.fontScale = 1.0,
    this.glassBlur = 18,
    this.glassOpacity = 1.0,
    this.radius = 22,
  });

  final String preset;

  /// رنگ‌های دستی. کلیدها: primary, secondary, accent, danger و
  /// bg1/bg2/bg3/card/text با پسوند _d (تیره) یا _l (روشن)
  final Map<String, int> colors;
  final String bgMode;
  final String bgImage;
  final double bgBlur;
  final double bgDim;

  /// '' = فونت سیستم، وگرنه یکی از kFontFamilies
  final String font;
  final double fontScale;
  final double glassBlur;
  final double glassOpacity;
  final double radius;

  bool get hasImage => bgImage.isNotEmpty;

  bool get isCustom =>
      jsonEncode(toJson()) != jsonEncode(const AppLook().toJson());

  AppLook copyWith({
    String? preset,
    Map<String, int>? colors,
    String? bgMode,
    String? bgImage,
    double? bgBlur,
    double? bgDim,
    String? font,
    double? fontScale,
    double? glassBlur,
    double? glassOpacity,
    double? radius,
  }) {
    return AppLook(
      preset: preset ?? this.preset,
      colors: colors ?? this.colors,
      bgMode: bgMode ?? this.bgMode,
      bgImage: bgImage ?? this.bgImage,
      bgBlur: bgBlur ?? this.bgBlur,
      bgDim: bgDim ?? this.bgDim,
      font: font ?? this.font,
      fontScale: fontScale ?? this.fontScale,
      glassBlur: glassBlur ?? this.glassBlur,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      radius: radius ?? this.radius,
    );
  }

  AppLook withColor(String key, Color? c) {
    final m = Map<String, int>.from(colors);
    if (c == null) {
      m.remove(key);
    } else {
      m[key] = c.value;
    }
    return copyWith(colors: m);
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'preset': preset,
        'colors': colors,
        'bgMode': bgMode,
        'bgImage': bgImage,
        'bgBlur': bgBlur,
        'bgDim': bgDim,
        'font': font,
        'fontScale': fontScale,
        'glassBlur': glassBlur,
        'glassOpacity': glassOpacity,
        'radius': radius,
      };

  factory AppLook.fromJsonString(String? s) {
    if (s == null || s.isEmpty) return const AppLook();
    try {
      final j = jsonDecode(s);
      if (j is! Map) return const AppLook();
      final cm = <String, int>{};
      final raw = j['colors'];
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is num) cm['$k'] = v.toInt();
        });
      }
      double d(String k, double def, double lo, double hi) {
        final v = j[k];
        return v is num ? v.toDouble().clamp(lo, hi).toDouble() : def;
      }

      final presetId = '${j['preset'] ?? 'aurora'}';
      final mode = '${j['bgMode'] ?? 'blobs'}';
      final ver = j['v'] is num ? (j['v'] as num).toInt() : 1;
      var font = '${j['font'] ?? kDefaultFont}';
      // نسخه‌های قدیمی '' را برای «پیش‌فرض» ذخیره می‌کردند
      if (ver < 2 && font.isEmpty) font = kDefaultFont;
      return AppLook(
        preset: kPresets.any((p) => p.id == presetId) ? presetId : 'aurora',
        colors: cm,
        bgMode: kBgModes.contains(mode) ? mode : 'blobs',
        bgImage: '${j['bgImage'] ?? ''}',
        bgBlur: d('bgBlur', 0, 0, 20),
        bgDim: d('bgDim', 0.25, 0, 0.8),
        font: (font.isEmpty || kFontFamilies.contains(font))
            ? font
            : kDefaultFont,
        fontScale: d('fontScale', 1.0, 0.8, 1.4),
        glassBlur: d('glassBlur', 18, 0, 30),
        glassOpacity: d('glassOpacity', 1.0, 0.3, 1.6),
        radius: d('radius', 22, 8, 34),
      );
    } catch (_) {
      return const AppLook();
    }
  }

  LookExt resolve(Brightness b) {
    final dark = b == Brightness.dark;
    final p = presetById(preset);
    final sfx = dark ? '_d' : '_l';
    Color pick(String k, Color d) {
      final v = colors[k];
      return v == null ? d : Color(v);
    }

    Color? opt(String k) {
      final v = colors[k];
      return v == null ? null : Color(v);
    }

    final bgs = dark ? p.dark : p.light;
    return LookExt(
      dark: dark,
      primary: pick('primary', p.primary),
      secondary: pick('secondary', p.secondary),
      accent: pick('accent', p.accent),
      danger: pick('danger', const Color(0xFFFF5252)),
      bg: [
        pick('bg1$sfx', bgs[0]),
        pick('bg2$sfx', bgs[1]),
        pick('bg3$sfx', bgs[2]),
      ],
      card: opt('card$sfx'),
      text: opt('text$sfx'),
      glassBlur: glassBlur,
      glassOpacity: glassOpacity,
      radius: radius,
      bgMode: bgMode,
      bgImage: bgImage,
      bgBlur: bgBlur,
      bgDim: bgDim,
    );
  }
}
