import 'dart:io';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'brand.dart';
import 'look.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// روی گوشی (اندروید/iOS) بلورِ زیر کارت‌ها خاموش است تا برنامه روان بماند
final bool kMobileGpu = Platform.isAndroid || Platform.isIOS;

/// رنگ‌ها و تنظیمات ظاهریِ فعلی (طرح، پس‌زمینه، شیشه و ...)
LookExt lk(BuildContext c) =>
    Theme.of(c).extension<LookExt>() ?? LookExt.fallback(isDark(c));

Color muted(BuildContext c) =>
    Theme.of(c).colorScheme.onSurface.withOpacity(0.62);

IconData chevron(BuildContext c) =>
    Directionality.of(c) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

void toast(BuildContext c, String m) {
  final ms = ScaffoldMessenger.of(c);
  ms.hideCurrentSnackBar();
  ms.showSnackBar(SnackBar(content: Text(m)));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String okLabel,
  required String cancelLabel,
  bool danger = false,
}) async {
  final dangerColor = lk(context).danger;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(okLabel,
              style: TextStyle(color: danger ? dangerColor : null)),
        ),
      ],
    ),
  );
  return r == true;
}

/// پس‌زمینه: حباب متحرک، گرادیان، موج، نقطه‌ای، راه‌راه، ساده یا عکس کاربر.
/// کل لایه‌ی پس‌زمینه داخل RepaintBoundary است و حباب‌ها فقط جابه‌جا می‌شوند
/// (بدون رسم دوباره)، پس روی اندروید هم روان است.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: kMobileGpu ? 32 : 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (lk(context).bgMode == 'blobs') {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// یک حباب نرم؛ فقط یک بار رسم می‌شود (داخل RepaintBoundary)
  Widget _blobShape(double size, Color color, bool dark) {
    final a = dark ? 0.52 : 0.40;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(a),
                color.withOpacity(a * 0.45),
                color.withOpacity(a * 0.12),
                color.withOpacity(0),
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moving({
    required double size,
    required Color color,
    required bool dark,
    required double left,
    required double top,
    required double dx,
    required double dy,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _c,
        child: _blobShape(size, color, dark),
        builder: (context, child) {
          final t = Curves.easeInOutSine.transform(_c.value);
          return Transform.translate(
            offset: Offset(dx * t, dy * t),
            child: child,
          );
        },
      ),
    );
  }

  Widget _gradientBox(LookExt l) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: l.bg,
          ),
        ),
      );

  /// سایه‌روشن ظریف بالا و پایین؛ ثابت و ارزان
  Widget _vignette(bool dark) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (dark ? Colors.white : Colors.white).withOpacity(dark ? 0.03 : 0.18),
                Colors.transparent,
                (dark ? Colors.black : Colors.black).withOpacity(dark ? 0.28 : 0.05),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      );

  Widget _imageLayer(LookExt l) {
    Widget img = Image.file(
      File(l.bgImage),
      fit: BoxFit.cover,
      cacheWidth: 1600,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _gradientBox(l),
    );
    if (l.bgBlur > 0.5) {
      img = ImageFiltered(
        imageFilter: ImageFilter.blur(
            sigmaX: l.bgBlur, sigmaY: l.bgBlur, tileMode: TileMode.clamp),
        child: img,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        img,
        ColoredBox(
          color: (l.dark ? Colors.black : Colors.white).withOpacity(l.bgDim),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final dark = l.dark;
    final layers = <Widget>[];

    switch (l.bgMode) {
      case 'solid':
        layers.add(ColoredBox(color: l.bg[0]));
        break;
      case 'image':
        layers.add(l.bgImage.isEmpty ? _gradientBox(l) : _imageLayer(l));
        break;
      default:
        layers.add(_gradientBox(l));
    }

    if (l.bgMode == 'blobs') {
      layers.add(LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
        final h = box.maxHeight.isFinite ? box.maxHeight : 800.0;
        final base = max(w, h) * 0.75;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            _moving(
                size: base,
                color: l.primary,
                dark: dark,
                left: -0.25 * w,
                top: -0.15 * h,
                dx: 0.15 * w,
                dy: 0.10 * h),
            _moving(
                size: base * 0.9,
                color: l.secondary,
                dark: dark,
                left: 0.45 * w,
                top: 0.55 * h,
                dx: -0.12 * w,
                dy: -0.10 * h),
            _moving(
                size: base * 0.6,
                color: l.accent,
                dark: dark,
                left: 0.55 * w,
                top: -0.10 * h,
                dx: -0.20 * w,
                dy: 0.20 * h),
          ],
        );
      }));
      layers.add(_vignette(dark));
    } else if (l.bgMode == 'gradient') {
      layers.add(_vignette(dark));
    } else if (l.bgMode == 'waves') {
      layers.add(CustomPaint(
        size: Size.infinite,
        painter: _WavesPainter(l.primary, l.secondary, dark),
      ));
    } else if (l.bgMode == 'dots') {
      layers.add(CustomPaint(
        size: Size.infinite,
        painter: _DotsPainter(l.primary, dark),
      ));
    } else if (l.bgMode == 'stripes') {
      layers.add(CustomPaint(
        size: Size.infinite,
        painter: _StripesPainter(l.primary, l.secondary, dark),
      ));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(fit: StackFit.expand, children: layers),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.a, this.b, this.dark);
  final Color a;
  final Color b;
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < 4; i++) {
      final path = Path();
      final baseY = s.height * (0.52 + 0.13 * i);
      final amp = s.height * (0.03 + 0.006 * i);
      path.moveTo(0, s.height);
      path.lineTo(0, baseY);
      for (double x = 0; x <= s.width; x += 6) {
        final y = baseY +
            sin((x / s.width) * 2 * pi * (1.0 + 0.4 * i) + i * 1.3) * amp;
        path.lineTo(x, y);
      }
      path.lineTo(s.width, s.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = (i.isEven ? a : b).withOpacity(dark ? 0.16 : 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(_WavesPainter o) =>
      o.a != a || o.b != b || o.dark != dark;
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.c, this.dark);
  final Color c;
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = c.withOpacity(dark ? 0.18 : 0.16);
    for (double y = 14; y < s.height; y += 28) {
      for (double x = 14; x < s.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 1.6, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter o) => o.c != c || o.dark != dark;
}

class _StripesPainter extends CustomPainter {
  _StripesPainter(this.a, this.b, this.dark);
  final Color a;
  final Color b;
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.rotate(0.62);
    final d = s.longestSide * 1.5;
    final colors = [a, Colors.white, b];
    final p = Paint();
    var i = 0;
    for (double x = -d; x < d; x += 34) {
      p.color = colors[i % 3].withOpacity(dark ? 0.08 : 0.10);
      canvas.drawRect(Rect.fromLTWH(x, -d, 34, 2 * d), p);
      i++;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripesPainter o) =>
      o.a != a || o.b != b || o.dark != dark;
}

/// اسکافولد استاندارد برنامه: پس‌زمینه + حداکثر عرض برای ویندوز
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.maxWidth = 560,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final hasBar = title != null || actions != null || leading != null;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: hasBar
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: leading,
                actions: actions,
                title: title == null
                    ? null
                    : Text(title!,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
              )
            : null,
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// کارت شیشه‌ای.
/// ویندوز: بلور واقعی. گوشی: بدون بلور (روان) و با رنگ کمی غلیظ‌تر.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.onTap,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final wantBlur = l.glassBlur > 0.5;
    final useBlur = wantBlur && !kMobileGpu;

    var fill = tint ?? l.cardFill;
    if (wantBlur && kMobileGpu) {
      // جبران نبودن بلور: کارت کمی پررنگ‌تر
      fill = fill.withOpacity((fill.opacity * 1.35 + 0.04).clamp(0.0, 1.0));
    }

    final br = BorderRadius.circular(radius ?? l.radius);
    final inner = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: br,
        border: Border.all(color: l.cardBorder),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(l.dark ? 0.20 : 0.06),
            blurRadius: kMobileGpu ? 14 : 24,
            offset: Offset(0, kMobileGpu ? 6 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: l.glassBlur, sigmaY: l.glassBlur),
                child: inner,
              )
            : inner,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.danger = false,
    this.outlined = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;
  final bool outlined;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final enabled = onPressed != null && !loading;
    final br = BorderRadius.circular((l.radius * 0.75).clamp(8.0, 28.0));
    final fg = outlined
        ? Theme.of(context).colorScheme.onSurface
        : (danger ? Colors.white : l.onPrimary);
    final grad = danger ? l.dangerGradient : l.gradient;

    Widget content;
    if (loading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: Ink(
          decoration: BoxDecoration(
            gradient: outlined ? null : grad,
            borderRadius: br,
            border: outlined
                ? Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.25),
                    width: 1.4)
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: (danger ? l.danger : l.primary).withOpacity(0.32),
                      blurRadius: kMobileGpu ? 12 : 18,
                      offset: Offset(0, kMobileGpu ? 5 : 8),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: br,
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: compact ? 42 : 54,
              width: double.infinity,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscure = false,
    this.keyboard,
    this.ltr = false,
    this.suffix,
    this.onSubmitted,
    this.textInputAction,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final bool ltr;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final dark = l.dark;
    final fill = dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    final primary = Theme.of(context).colorScheme.primary;
    final rr = (l.radius * 0.73).clamp(8.0, 26.0);
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(rr),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textDirection: ltr ? TextDirection.ltr : null,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: fill,
        prefixIcon: icon == null ? null : Icon(icon, size: 22),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: ob(Colors.transparent),
        enabledBorder: ob(dark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.06)),
        focusedBorder: ob(primary, 1.6),
      ),
    );
  }
}

/// لوگوی ESMAIRO (همان آیکن برنامه) با سایه‌ی نرم
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: kBrandViolet.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: EsmairoMark(size: size),
    );
  }
}

class GradientIcon extends StatelessWidget {
  const GradientIcon(this.icon, {super.key, this.size = 50, this.gradient});
  final IconData icon;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? l.gradient,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon,
          color: gradient == null ? l.onPrimary : Colors.white,
          size: size * 0.52),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, top: 18, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: muted(context),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class SegmentPicker<T> extends StatelessWidget {
  const SegmentPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<MapEntry<T, String>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final dark = l.dark;
    return Row(
      children: [
        for (final o in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onChanged(o.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: o.key == value ? l.gradient : null,
                    color: o.key == value
                        ? null
                        : (dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(
                        (l.radius * 0.64).clamp(8.0, 22.0)),
                  ),
                  child: Text(
                    o.value,
                    style: TextStyle(
                      color: o.key == value ? l.onPrimary : null,
                      fontWeight:
                          o.key == value ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
