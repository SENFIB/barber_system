import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/platform.dart';
import 'app/settings.dart';
import 'features/customer/customer_home.dart';
import 'features/manager/manager_entry.dart';
import 'features/onboarding/language_page.dart';
import 'features/onboarding/role_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(BarberApp(settings: settings));
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key, required this.settings});

  final AppSettings settings;

  Widget _home() {
    if (settings.language == null) {
      return LanguagePage(settings: settings);
    }
    // ویندوز: مستقیم بخش آرایشگاه
    if (isWindowsApp) {
      return ManagerEntry(settings: settings);
    }
    if (settings.role == null) {
      return RolePage(settings: settings);
    }
    if (settings.role == 'customer') {
      return CustomerHome(settings: settings);
    }
    return ManagerEntry(settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Barber',
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.lang),
          supportedLocales: const [Locale('fa'), Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
          ),
          themeMode: settings.themeMode,
          home: _home(),
        );
      },
    );
  }
}
