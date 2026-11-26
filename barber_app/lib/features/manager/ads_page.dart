import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';
import 'ads_section.dart';

/// صفحه‌ی تبلیغات (همان بخش تبلیغات، به‌صورت صفحه‌ی جدا)
class AdsPage extends StatelessWidget {
  const AdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final title = lang == 'fa'
        ? 'تبلیغات'
        : (lang == 'ar' ? 'الإعلانات' : 'Advertising');
    return GlassScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [AdsSection()],
      ),
    );
  }
}
