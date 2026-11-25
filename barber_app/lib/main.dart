import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/app_header.dart';
import 'app/cal_conv.dart';
import 'app/fmt.dart';
import 'app/reminders.dart';
import 'app/settings.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'app/version_gate.dart';
import 'features/customer/customer_home.dart';
import 'features/legal/privacy_gate.dart';
import 'features/manager/manager_entry.dart';
import 'features/onboarding/language_page.dart';
import 'features/onboarding/role_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  kDigitsLang = settings.lang;
  kCalKind = CalConv.kindOf(settings.calendarKey, settings.lang);
  await Reminders.init();
  runApp(SettingsScope(settings: settings, child: const BarberApp()));
}

/// اسکرول سر جاش می‌ماند، فقط نوار اسکرول دیده نمی‌شود
class _NoBarScroll extends MaterialScrollBehavior {
  const _NoBarScroll();

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final look = st.look;
    // زبان اعداد همیشه با زبان برنامه یکی است
    kDigitsLang = st.lang;
    // تقویم نمایش از انتخاب هدر (یا پیش‌فرض زبان)
    kCalKind = CalConv.kindOf(st.calendarKey, st.lang);
    final dir = st.isRtl ? TextDirection.rtl : TextDirection.ltr;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: kNavKey,
      title: S(st.lang).t('app_name'),
      scrollBehavior: const _NoBarScroll(),
      theme: buildTheme(Brightness.light, look),
      darkTheme: buildTheme(Brightness.dark, look),
      themeMode: st.themeMode,
      // جهت از روی زبان تعیین می‌شود (فارسی/عربی راست‌چین، انگلیسی چپ‌چین)
      locale: Locale(st.lang),
      supportedLocales: const [Locale('fa'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler:
                TextScaler.linear(mq.textScaler.scale(1.0) * look.fontScale),
          ),
          child: Directionality(
            textDirection: dir,
            child: Builder(
              builder: (inner) => Column(
                children: [
                  // هدر ثابت: بین صفحه‌ها عوض نمی‌شود
                  const AppHeader(),
                  Expanded(
                    // بالای صفحه را خود هدر پر کرده؛ صفحه‌ها دوباره فاصله نمی‌گیرند
                    child: MediaQuery.removePadding(
                      context: inner,
                      removeTop: true,
                      child: child ?? const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    String key;
    Widget page;
    if (st.language == null) {
      key = 'lang';
      page = const LanguagePage();
    } else if (st.role == null) {
      key = 'role';
      page = const RolePage();
    } else if (st.role == 'customer') {
      key = 'customer';
      page = const VersionGate(app: 'customer', child: CustomerHome());
    } else {
      key = 'shop';
      page = const VersionGate(app: 'manager', child: ManagerEntry());
    }
    final sw = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(key), child: page),
    );
    // بعد از انتخاب زبان، تا قبول حریم خصوصی و قوانین هیچ صفحه‌ای باز نمی‌شود
    if (st.language == null) return sw;
    return PrivacyGate(lang: st.lang, child: sw);
  }
}
