import 'package:flutter/material.dart';
import '../features/legal/privacy_gate.dart';
import '../features/settings/settings_page.dart';
import 'brand.dart';
import 'clock.dart';
import 'settings.dart';
import 'widgets.dart';

/// کلید ناوبری برنامه: هدر بالای Navigator است و برای باز کردن پنجره‌ها
/// از context خودِ Navigator استفاده می‌کند.
final GlobalKey<NavigatorState> kNavKey = GlobalKey<NavigatorState>();

/// وقتی پنجره‌ی انتخابِ هدر باز است true می‌شود.
final ValueNotifier<bool> _pickerOpen = ValueNotifier<bool>(false);

void _closePicker() {
  if (_pickerOpen.value) {
    kNavKey.currentState?.pop();
  }
}

String _tr(String lang, String fa, String en, String ar) =>
    lang == 'fa' ? fa : (lang == 'ar' ? ar : en);

void _openRules(AppSettings st) {
  final ctx = kNavKey.currentContext;
  if (ctx == null) return;
  if (_pickerOpen.value) return;
  openAppPolicy(ctx, st.lang);
}

void _openSettings() {
  if (_pickerOpen.value) return;
  kNavKey.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
  );
}

/// هدر ثابت برنامه
/// ردیف بالا: لوگو و نام (یک طرف) | تنظیمات، تم، زبان (طرف مقابل)
/// ردیف پایین: ساعت و تاریخ با ثانیه | ساعت، تقویم، قوانین
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final l = lk(context);
    final mq = MediaQuery.of(context);
    final lang = st.lang;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Color.alphaBlend(
        l.primary.withOpacity(l.dark ? 0.12 : 0.08), l.bg[0]);
    final langCode = lang == 'fa' ? 'فا' : (lang == 'ar' ? 'ع' : 'EN');

    // ---- ردیف بالا: دکمه‌ها ----
    final topBtns = <Widget>[
      _HBtn(
        semantic: _tr(lang, 'تنظیمات', 'Settings', 'الإعدادات'),
        icon: Icons.settings_rounded,
        onTap: _openSettings,
      ),
    ];
    if (st.showHdrBtns) {
      topBtns.add(_HBtn(
        semantic: _tr(lang, 'تم روشن و تاریک', 'Light / dark theme',
            'الوضع الفاتح / الداكن'),
        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        onTap: () => st.setThemeKey(isDark ? 'light' : 'dark'),
      ));
    }
    if (st.showHdrLang) {
      topBtns.add(_HBtn(
        semantic: _tr(lang, 'زبان', 'Language', 'اللغة'),
        icon: Icons.language_rounded,
        label: langCode,
        onTap: () => _langSheet(st),
      ));
    }

    // ---- ردیف پایین: دکمه‌ها ----
    final bottomBtns = <Widget>[];
    if (st.showHdrBtns) {
      bottomBtns.add(_HBtn(
        semantic: _tr(lang, 'ساعت', 'Time', 'الوقت'),
        icon: st.usePhoneTime ? Icons.smartphone_rounded : Icons.public_rounded,
        active: st.usePhoneTime,
        onTap: () => _timeSheet(st),
      ));
      bottomBtns.add(_HBtn(
        semantic: _tr(lang, 'تقویم', 'Calendar', 'التقويم'),
        icon: Icons.calendar_month_rounded,
        onTap: () => _calSheet(st),
      ));
      bottomBtns.add(_HBtn(
        semantic: _tr(
            lang, 'قوانین و مقررات', 'Terms and policy', 'القوانين والأحكام'),
        icon: Icons.gavel_rounded,
        onTap: () => _openRules(st),
      ));
    }

    List<Widget> spaced(List<Widget> src) {
      final out = <Widget>[];
      for (var i = 0; i < src.length; i++) {
        if (i > 0) out.add(const SizedBox(width: 6));
        out.add(src[i]);
      }
      return out;
    }

    final showSecondRow = st.showHdrClock || bottomBtns.isNotEmpty;

    final bar = Material(
      color: base,
      child: Container(
        padding: EdgeInsets.only(top: mq.padding.top),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: l.cardBorder)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: EsmairoMark(size: 44),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appNameFor(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...spaced(topBtns),
                      ],
                    ),
                  ),
                ),
                if (showSecondRow)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: st.showHdrClock
                              ? HeaderClock(
                                  lang: lang,
                                  calendar: st.calendar,
                                  phone: st.usePhoneTime,
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (bottomBtns.isNotEmpty) const SizedBox(width: 8),
                        ...spaced(bottomBtns),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // وقتی پنجره‌ی انتخاب باز است، یک لایه‌ی نامرئی روی هدر می‌افتد
    // تا ضربه روی هدر هم پنجره را ببندد.
    return ValueListenableBuilder<bool>(
      valueListenable: _pickerOpen,
      child: bar,
      builder: (context, open, child) {
        return Stack(
          children: [
            child!,
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closePicker,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
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
  if (_pickerOpen.value) return; // هم‌زمان فقط یک پنجره
  _pickerOpen.value = true;
  try {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.25),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle:
                              o.subtitle == null ? null : Text(o.subtitle!),
                          trailing: o.value == current
                              ? Icon(Icons.check_circle_rounded,
                                  color: l.primary)
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
  } finally {
    _pickerOpen.value = false;
  }
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
        _tr(lang, 'ساعت منطقه‌ی زبان', 'Language region time',
            'وقت منطقة اللغة'),
        _tr(lang, 'فارسی: تهران • English: لندن • عربی: مکه',
            'Persian: Tehran • English: London • Arabic: Makkah',
            'الفارسية: طهران • الإنجليزية: لندن • العربية: مكة'),
      ),
      _Opt(
        'phone',
        _tr(lang, 'ساعت و تاریخ دستگاه', 'Device time and date',
            'وقت وتاريخ الجهاز'),
        _tr(lang, 'از ساعت همین دستگاه، با هر زبانی',
            'From this device clock, in any language',
            'من ساعة هذا الجهاز، بأي لغة'),
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
      _Opt('jalali',
          _tr(lang, 'شمسی (جلالی)', 'Jalali (Persian)', 'الشمسي (الجلالي)')),
      _Opt('gregorian', _tr(lang, 'میلادی', 'Gregorian', 'الميلادي')),
      _Opt('hijri',
          _tr(lang, 'قمری (هجری)', 'Hijri (Islamic)', 'الهجري (القمري)')),
    ],
    onPick: st.setCalendarKey,
  );
}
