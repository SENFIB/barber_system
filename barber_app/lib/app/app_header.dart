import 'package:flutter/material.dart';

import 'brand.dart';
import 'settings.dart';
import 'strings.dart';
import 'widgets.dart';

/// کلید ناوبری برنامه: هدر بالای Navigator است و برای باز کردن پنجره‌ها
/// از context خودِ Navigator استفاده می‌کند.
final GlobalKey<NavigatorState> kNavKey = GlobalKey<NavigatorState>();

String _tr(String lang, String fa, String en, String ar) =>
    lang == 'fa' ? fa : (lang == 'ar' ? ar : en);

/// هدر ثابت برنامه: نام، زبان، ساعت (مغازه/گوشی) و تقویم
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final l = lk(context);
    final mq = MediaQuery.of(context);
    final compact = mq.size.width < 420;
    final lang = st.lang;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final base = Color.alphaBlend(
        l.primary.withOpacity(l.dark ? 0.12 : 0.08), l.bg[0]);

    final langCode = lang == 'fa' ? 'فا' : (lang == 'ar' ? 'ع' : 'EN');

    final calName = () {
      switch (st.calendar) {
        case 'jalali':
          return _tr(lang, 'شمسی', 'Jalali', 'شمسي');
        case 'hijri':
          return _tr(lang, 'قمری', 'Hijri', 'هجري');
        default:
          return _tr(lang, 'میلادی', 'Gregorian', 'ميلادي');
      }
    }();

    return Material(
      color: base,
      child: Container(
        padding: EdgeInsets.only(top: mq.padding.top),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: l.cardBorder)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: EsmairoMark(size: 30),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S(lang).t('app_name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    _HBtn(
                      semantic: _tr(lang, 'زبان', 'Language', 'اللغة'),
                      icon: Icons.language_rounded,
                      label: langCode,
                      onTap: () => _langSheet(st),
                    ),
                    const SizedBox(width: 6),
                    _HBtn(
                      semantic: _tr(lang, 'ساعت', 'Time', 'الوقت'),
                      icon: st.usePhoneTime
                          ? Icons.phone_android_rounded
                          : Icons.storefront_rounded,
                      label: compact
                          ? null
                          : (st.usePhoneTime
                              ? _tr(lang, 'گوشی', 'Phone', 'الهاتف')
                              : _tr(lang, 'مغازه', 'Shop', 'المحل')),
                      active: st.usePhoneTime,
                      onTap: () => _timeSheet(st),
                    ),
                    const SizedBox(width: 6),
                    _HBtn(
                      semantic: _tr(lang, 'تقویم', 'Calendar', 'التقويم'),
                      icon: Icons.calendar_month_rounded,
                      label: compact ? null : calName,
                      onTap: () => _calSheet(st),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HBtn extends StatelessWidget {
  const _HBtn({
    required this.icon,
    required this.onTap,
    required this.semantic,
    this.label,
    this.active = false,
  });
  final IconData icon;
  final String? label;
  final String semantic;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = active
        ? l.primary.withOpacity(0.22)
        : onSurface.withOpacity(l.dark ? 0.10 : 0.07);
    return Semantics(
      button: true,
      label: semantic,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 36,
            constraints: const BoxConstraints(minWidth: 38),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: active ? l.primary : onSurface),
                if (label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: active ? l.primary : onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// پنجره‌های انتخاب
// ---------------------------------------------------------------------------

class _Opt {
  const _Opt(this.value, this.title, [this.subtitle]);
  final String value;
  final String title;
  final String? subtitle;
}

Future<void> _pick({
  required String title,
  required List<_Opt> options,
  required String current,
  required Future<void> Function(String v) onPick,
}) async {
  final ctx = kNavKey.currentContext;
  if (ctx == null) return;
  await showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) {
      final theme = Theme.of(c);
      final l = lk(c);
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: l.cardBorder),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    for (final o in options)
                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        selected: o.value == current,
                        selectedTileColor: l.primary.withOpacity(0.12),
                        title: Text(o.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: o.subtitle == null ? null : Text(o.subtitle!),
                        trailing: o.value == current
                            ? Icon(Icons.check_circle_rounded, color: l.primary)
                            : null,
                        onTap: () async {
                          Navigator.of(c).pop();
                          await onPick(o.value);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _langSheet(AppSettings st) {
  final lang = st.lang;
  return _pick(
    title: _tr(lang, 'زبان برنامه', 'App language', 'لغة التطبيق'),
    current: lang,
    options: const [
      _Opt('fa', 'فارسی'),
      _Opt('en', 'English'),
      _Opt('ar', 'العربية'),
    ],
    onPick: st.setLanguage,
  );
}

Future<void> _timeSheet(AppSettings st) {
  final lang = st.lang;
  return _pick(
    title: _tr(lang, 'ساعت و تاریخ', 'Time and date', 'الوقت والتاريخ'),
    current: st.timeMode,
    options: [
      _Opt(
        'shop',
        _tr(lang, 'ساعت مغازه', 'Shop time', 'وقت المحل'),
        _tr(lang, 'ساعت و تاریخ بر اساس منطقه‌ی زمانی آرایشگاه',
            'Based on the barber shop time zone', 'حسب المنطقة الزمنية للمحل'),
      ),
      _Opt(
        'phone',
        _tr(lang, 'ساعت گوشی', 'Phone time', 'وقت الهاتف'),
        _tr(lang, 'ساعت و تاریخ بر اساس ساعت همین دستگاه',
            'Based on this device clock', 'حسب ساعة هذا الجهاز'),
      ),
    ],
    onPick: st.setTimeMode,
  );
}

Future<void> _calSheet(AppSettings st) {
  final lang = st.lang;
  return _pick(
    title: _tr(lang, 'نوع تقویم', 'Calendar type', 'نوع التقويم'),
    current: st.calendarKey,
    options: [
      _Opt(
        'auto',
        _tr(lang, 'خودکار', 'Automatic', 'تلقائي'),
        _tr(lang, 'فارسی: شمسی • English: میلادی • عربی: هجری',
            'Persian: Jalali • English: Gregorian • Arabic: Hijri',
            'الفارسية: شمسي • الإنجليزية: ميلادي • العربية: هجري'),
      ),
      _Opt('jalali', _tr(lang, 'شمسی (جلالی)', 'Jalali (Persian)', 'الشمسي (الجلالي)')),
      _Opt('gregorian', _tr(lang, 'میلادی', 'Gregorian', 'الميلادي')),
      _Opt('hijri', _tr(lang, 'قمری (هجری)', 'Hijri (Islamic)', 'الهجري (القمري)')),
    ],
    onPick: st.setCalendarKey,
  );
}
