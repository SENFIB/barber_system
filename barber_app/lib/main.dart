import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:barber_core/barber_core.dart';

void main() => runApp(const BarberApp());

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سیستم نوبت‌دهی آرایشگاه')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.content_cut, size: 64),
            const SizedBox(height: 16),
            const Text('ساخت با GitHub Actions موفق بود ✅'),
            const SizedBox(height: 8),
            Text('پکیج مشترک: $kCoreName'),
            const SizedBox(height: 8),
            Text('نسخه: $_version'),
          ],
        ),
      ),
    );
  }
}
