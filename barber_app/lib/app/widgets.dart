import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

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
              style: TextStyle(color: danger ? AppColors.red : null)),
        ),
      ],
    ),
  );
  return r == true;
}

/// پس‌زمینه‌ی گرادیانی با حباب‌های رنگیِ آرام‌متحرک
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
    duration: const Duration(seconds: 20),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, Color color, double left, double top, bool dark) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(dark ? 0.50 : 0.38),
              color.withOpacity(0),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final colors = dark
        ? const [Color(0xFF0B1020), Color(0xFF1A1440), Color(0xFF0A1D30)]
        : const [Color(0xFFEEF1FF), Color(0xFFF7EEFF), Color(0xFFE6F5FF)];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final base = max(w, h) * 0.75;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_c.value);
              return Stack(children: [
                _blob(base, AppColors.violet, -0.25 * w + 0.15 * w * t,
                    -0.15 * h + 0.10 * h * t, dark),
                _blob(base * 0.9, AppColors.blue, 0.45 * w - 0.12 * w * t,
                    0.55 * h - 0.10 * h * t, dark),
                _blob(base * 0.6, AppColors.pink, 0.55 * w - 0.2 * w * t,
                    -0.10 * h + 0.2 * h * t, dark),
              ]);
            },
          );
        }),
        widget.child,
      ],
    );
  }
}

/// اسکافولد استاندارد برنامه: پس‌زمینه‌ی شیشه‌ای + حداکثر عرض برای ویندوز
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

/// کارت شیشه‌ای
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final fill = tint ??
        (dark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.62));
    final border =
        dark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.9);
    final br = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.22 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: br,
              border: Border.all(color: border),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: br,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
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
    final enabled = onPressed != null && !loading;
    final br = BorderRadius.circular(16);
    final fg = outlined
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    final grad = danger ? AppColors.dangerGradient : AppColors.gradient;

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
                      color: (danger ? AppColors.red : AppColors.violet)
                          .withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
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
    final dark = isDark(context);
    final fill = dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    final primary = Theme.of(context).colorScheme.primary;
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(Icons.content_cut_rounded, color: Colors.white, size: size * 0.5),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.gradient,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
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
    final dark = isDark(context);
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
                    gradient: o.key == value ? AppColors.gradient : null,
                    color: o.key == value
                        ? null
                        : (dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    o.value,
                    style: TextStyle(
                      color: o.key == value ? Colors.white : null,
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
