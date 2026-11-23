import 'package:flutter/material.dart';

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
  runApp(SettingsScope(settings: settings, child: const BarberApp()));
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: S(st.lang).t('app_name'),
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: st.themeMode,
      builder: (context, child) => Directionality(
        textDirection: st.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox(),
      ),
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
