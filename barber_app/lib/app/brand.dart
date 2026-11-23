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

class _MarkPainter extends CustomPainter {
  final bool tile;
  const _MarkPainter(this.tile);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s);

    if (tile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)),
        Paint()
          ..isAntiAlias = true
          ..shader = kBrandGradient.createShader(rect),
      );
    }

    final p = Paint()..isAntiAlias = true;
    if (tile) {
      p.color = Colors.white;
    } else {
      p.shader = kBrandGradient.createShader(rect);
    }

    RRect r(double l, double t, double rt, double b, double rad) =>
        RRect.fromLTRBR(l * s, t * s, rt * s, b * s, Radius.circular(rad * s));

    canvas.drawRRect(r(0.26, 0.24, 0.36, 0.76, 0.05), p); // ستون E
    canvas.drawRRect(r(0.34, 0.24, 0.70, 0.33, 0.045), p); // دندانه‌ی بالا
    canvas.drawRRect(r(0.34, 0.67, 0.70, 0.76, 0.045), p); // دندانه‌ی پایین

    final blade = Path()
      ..moveTo(0.34 * s, 0.455 * s)
      ..lineTo(0.78 * s, 0.50 * s)
      ..lineTo(0.34 * s, 0.545 * s)
      ..close(); // تیغه‌ی قیچی
    canvas.drawPath(blade, p);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.tile != tile;
}

/// فقط نشانه‌ی E.
/// tile=true: داخل مربع گرادیان (مثل آیکن). tile=false: خود E با رنگ گرادیان.
class EsmairoMark extends StatelessWidget {
  final double size;
  final bool tile;
  const EsmairoMark({super.key, this.size = 64, this.tile = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(tile)),
    );
  }
}

/// نشانه + نوشته‌ی ESMAIRO
class EsmairoLogo extends StatelessWidget {
  final double size;
  final bool showName;
  const EsmairoLogo({super.key, this.size = 88, this.showName = true});

  @override
  Widget build(BuildContext context) {
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
              kAppName,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: size * 0.30,
                fontWeight: FontWeight.w700,
                letterSpacing: size * 0.06,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
