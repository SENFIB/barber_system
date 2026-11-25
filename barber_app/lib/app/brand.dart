import 'package:flutter/material.dart';

/// نام نمایشی برنامه
const String kAppName = 'ESMAIRO';
const Color kBrandViolet = Color(0xFF7C3AED);
const Color kBrandPink = Color(0xFFEC4899);
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBrandViolet, kBrandPink],
);

/// اسم برنامه به سه زبان
String appNameFor(String lang) {
  switch (lang) {
    case 'fa':
      return 'اِسمایرو';
    case 'ar':
      return 'إسمايرو';
    default:
      return kAppName;
  }
}

/// خط «توسعه‌دهنده» به سه زبان
String developerLine(String lang) {
  switch (lang) {
    case 'en':
      return 'Developer: Esmaeil';
    case 'ar':
      return 'المطوّر: إسماعيل';
    default:
      return 'توسعه‌دهنده: اسماعیل';
  }
}

/// لوگوی خودت (barber_app/assets/logo.png)
class EsmairoMark extends StatelessWidget {
  final double size;
  final bool tile;
  const EsmairoMark({super.key, this.size = 64, this.tile = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.content_cut_rounded, size: size * 0.6),
      ),
    );
  }
}

/// لوگو + اسم برنامه
class EsmairoLogo extends StatelessWidget {
  final double size;
  final bool showName;
  const EsmairoLogo({super.key, this.size = 88, this.showName = true});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final latin = lang != 'fa' && lang != 'ar';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EsmairoMark(size: size),
        if (showName) ...[
          SizedBox(height: size * 0.16),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => kBrandGradient.createShader(b),
            child: Text(
              appNameFor(lang),
              textDirection: latin ? TextDirection.ltr : null,
              style: TextStyle(
                fontSize: size * 0.30,
                fontWeight: FontWeight.w700,
                letterSpacing: latin ? size * 0.06 : 0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
