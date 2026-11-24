import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_header.dart';
import 'app/fmt.dart';
import 'app/settings.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'features/customer/customer_home.dart';
import 'features/manager/manager_entry.dart';
import 'features/onboarding/language_page.dart';
import 'features/onboarding/role_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  kDigitsLang = settings.lang;
  runApp(SettingsScope(settings: settings, child: const BarberApp()));
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final look = st.look;
    // زبان اعداد همیشه با زبان برنامه یکی است
    kDigitsLang = st.lang;
    final dir = st.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: kNavKey,
      title: S(st.lang).t('app_name'),
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
      page = const CustomerHome();
    } else {
      key = 'shop';
      page = const ManagerEntry();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(key), child: page),
    );
  }
}
