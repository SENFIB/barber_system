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

/// برند سفارشی هدر (فقط پلن ویژه/شخصی با عکس کسب‌وکار).
class HeaderBrand {
  const HeaderBrand(this.photo, this.name);
  final String photo;
  final String name;
}

/// اگر null باشد لوگوی ESMAIRO نمایش داده می‌شود.
final ValueNotifier<HeaderBrand?> kHeaderBrand =
    ValueNotifier<HeaderBrand?>(null);

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

void _goLogin(AppSettings st) {
  if (_pickerOpen.value) return;
  kNavKey.currentState?.popUntil((r) => r.isFirst);
  st.setRole('shop');
}

/// هدر ثابت برنامه، فقط یک ردیف:
/// لوگو / برند | ساعت | دکمه‌ها
/// ویندوز: دکمه‌ها جدا. موبایل: یک دکمه‌ی منو.
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
    final wide = mq.size.width >= 700;
    final logoSize = wide ? 84.0 : 52.0;
    final rowH = wide ? 98.0 : 66.0;
    final hPad = wide ? 28.0 : 12.0;
    final gap = wide ? 10.0 : 6.0;

    // ---- دکمه‌ها ----
    final btns = <Widget>[];
    if (wide) {
      if (!st.hasShopToken) {
        btns.add(_HBtn(
          semantic: _tr(lang, 'ورود', 'Login', 'دخول'),
          icon: Icons.login_rounded,
          label: _tr(lang, 'ورود', 'Login', 'دخول'),
          big: true,
          onTap: () => _goLogin(st),
        ));
      }
      if (st.showHdrBtns) {
        btns.add(_HBtn(
          semantic: _tr(lang, 'ساعت', 'Time', 'الوقت'),
          icon: st.usePhoneTime
              ? Icons.smartphone_rounded
              : Icons.public_rounded,
          active: st.usePhoneTime,
          big: true,
          onTap: () => _timeSheet(st),
        ));
        btns.add(_HBtn(
          semantic: _tr(lang, 'تقویم', 'Calendar', 'التقويم'),
          icon: Icons.calendar_month_rounded,
          big: true,
          onTap: () => _calSheet(st),
        ));
        btns.add(_HBtn(
          semantic: _tr(
              lang, 'قوانین و مقررات', 'Terms and policy', 'القوانين والأحكام'),
          icon: Icons.gavel_rounded,
          big: true,
          onTap: () => _openRules(st),
        ));
        btns.add(_HBtn(
          semantic: _tr(lang, 'تم روشن و تاریک', 'Light / dark theme',
              'الوضع الفاتح / الداكن'),
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          big: true,
          onTap: () => st.setThemeKey(isDark ? 'light' : 'dark'),
        ));
      }
      if (st.showHdrLang) {
        btns.add(_HBtn(
          semantic: _tr(lang, 'زبان', 'Language', 'اللغة'),
          icon: Icons.language_rounded,
          label: langCode,
          big: true,
          onTap: () => _langSheet(st),
        ));
      }
      btns.add(_HBtn(
        semantic: _tr(lang, 'تنظیمات', 'Settings', 'الإعدادات'),
        icon: Icons.settings_rounded,
        big: true,
        onTap: _openSettings,
      ));
    } else {
      btns.add(_HBtn(
        semantic: _tr(lang, 'منو', 'Menu', 'القائمة'),
        icon: Icons.menu_rounded,
        big: false,
        onTap: () => _menuSheet(st),
      ));
    }

    List<Widget> spaced(List<Widget> src) {
      final out = <Widget>[];
      for (var i = 0; i < src.length; i++) {
        if (i > 0) out.add(SizedBox(width: gap));
        out.add(src[i]);
      }
      return out;
    }

    Widget buildBar(HeaderBrand? brand) {
      final radius = wide ? 18.0 : 12.0;
      Widget logo;
      if (brand != null) {
        logo = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            brand.photo,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => EsmairoMark(size: logoSize),
          ),
        );
      } else {
        logo = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: EsmairoMark(size: logoSize),
        );
      }
      String? title;
      if (brand != null) {
        title = brand.name;
      } else if (!wide) {
        title = appNameFor(lang);
      }
      final brandPart = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 380 : 140),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            if (title != null && title.isNotEmpty) ...[
              SizedBox(width: wide ? 14 : 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: wide ? 24 : 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

      final clockPart = LayoutBuilder(
        builder: (context, c) {
          if (!st.showHdrClock || c.maxWidth < 120) {
            return const SizedBox.shrink();
          }
          return Align(
            alignment: AlignmentDirectional.center,
            child: SizedBox(
              width: c.maxWidth > 360 ? 360 : c.maxWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: HeaderClock(
                  lang: lang,
                  calendar: st.calendar,
                  phone: st.usePhoneTime,
                ),
              ),
            ),
          );
        },
      );

      return Material(
        color: base,
        child: Container(
          padding: EdgeInsets.only(top: mq.padding.top),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: l.cardBorder)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: wide ? double.infinity : 560),
              child: SizedBox(
                height: rowH,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      brandPart,
                      SizedBox(width: gap),
                      Expanded(child: clockPart),
                      SizedBox(width: gap),
                      ...spaced(btns),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // وقتی پنجره‌ی انتخاب باز است، یک لایه‌ی نامرئی روی هدر می‌افتد
    // تا ضربه روی هدر هم پنجره را ببندد.
    return ValueListenableBuilder<bool>(
      valueListenable: _pickerOpen,
      builder: (context, open, _) {
        return Stack(
          children: [
            ValueListenableBuilder<HeaderBrand?>(
              valueListenable: kHeaderBrand,
              builder: (context, brand, __) => buildBar(brand),
            ),
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
    this.big = false,
  });

  final IconData icon;
  final String? label;
  final String semantic;
  final bool active;
  final bool big;
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
            height: 40,
            constraints: const BoxConstraints(minWidth: 40),
            padding: EdgeInsets.symmetric(horizontal: big ? 11 : 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: big ? 21 : 22,
                    color: active ? l.primary : onSurface),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 14,
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
  const _Opt(this.value, this.title, [this.subtitle, this.icon]);
  final String value;
  final String title;
  final String? subtitle;
  final IconData? icon;
}

Widget _sheetBody(
  BuildContext c, {
  required String title,
  required List<_Opt> options,
  required String current,
  required void Function(String v) onTap,
}) {
  final theme = Theme.of(c);
  final l = lk(c);
  return Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: l.cardBorder),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                      leading: o.icon == null ? null : Icon(o.icon),
                      title: Text(o.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: o.subtitle == null ? null : Text(o.subtitle!),
                      trailing: o.value == current
                          ? Icon(Icons.check_circle_rounded, color: l.primary)
                          : null,
                      onTap: () => onTap(o.value),
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
      builder: (c) => _sheetBody(
        c,
        title: title,
        options: options,
        current: current,
        onTap: (v) async {
          Navigator.of(c).pop();
          await onPick(v);
        },
      ),
    );
  } finally {
    _pickerOpen.value = false;
  }
}

/// منوی موبایل: همه‌ی دکمه‌ها در یک پنجره
Future<void> _menuSheet(AppSettings st) async {
  final ctx = kNavKey.currentContext;
  if (ctx == null) return;
  if (_pickerOpen.value) return;
  final lang = st.lang;
  final isDark = Theme.of(ctx).brightness == Brightness.dark;
  final opts = <_Opt>[
    if (!st.hasShopToken)
      _Opt('login', _tr(lang, 'ورود', 'Login', 'دخول'), null,
          Icons.login_rounded),
    _Opt('settings', _tr(lang, 'تنظیمات', 'Settings', 'الإعدادات'), null,
        Icons.settings_rounded),
    if (st.showHdrBtns)
      _Opt(
          'theme',
          isDark
              ? _tr(lang, 'تم روشن', 'Light theme', 'الوضع الفاتح')
              : _tr(lang, 'تم تاریک', 'Dark theme', 'الوضع الداكن'),
          null,
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    if (st.showHdrBtns)
      _Opt('time', _tr(lang, 'ساعت', 'Time', 'الوقت'), null,
          Icons.access_time_rounded),
    if (st.showHdrBtns)
      _Opt('cal', _tr(lang, 'تقویم', 'Calendar', 'التقويم'), null,
          Icons.calendar_month_rounded),
    if (st.showHdrBtns)
      _Opt(
          'rules',
          _tr(lang, 'قوانین و مقررات', 'Terms and policy',
              'القوانين والأحكام'),
          null,
          Icons.gavel_rounded),
    if (st.showHdrLang)
      _Opt('lang', _tr(lang, 'زبان', 'Language', 'اللغة'), null,
          Icons.language_rounded),
  ];
  _pickerOpen.value = true;
  String? chosen;
  try {
    chosen = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _sheetBody(
        c,
        title: _tr(lang, 'منو', 'Menu', 'القائمة'),
        options: opts,
        current: '',
        onTap: (v) => Navigator.of(c).pop(v),
      ),
    );
  } finally {
    _pickerOpen.value = false;
  }
  switch (chosen) {
    case 'login':
      _goLogin(st);
      break;
    case 'settings':
      _openSettings();
      break;
    case 'theme':
      st.setThemeKey(isDark ? 'light' : 'dark');
      break;
    case 'time':
      await _timeSheet(st);
      break;
    case 'cal':
      await _calSheet(st);
      break;
    case 'rules':
      _openRules(st);
      break;
    case 'lang':
      await _langSheet(st);
      break;
    default:
      break;
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
