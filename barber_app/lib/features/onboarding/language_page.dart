import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/widgets.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final items = const [
      ['fa', 'فارسی', 'Persian'],
      ['en', 'English', 'انگلیسی'],
      ['ar', 'العربية', 'Arabic'],
    ];
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 40, 22, 32),
        children: [
          const Center(child: AppLogo(size: 96)),
          const SizedBox(height: 22),
          const Center(
            child: Text('Barber Booking',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'زبان خود را انتخاب کنید\nChoose your language\nاختر لغتك',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted(context), height: 1.7),
            ),
          ),
          const SizedBox(height: 30),
          for (final it in items) ...[
            Glass(
              onTap: () => st.setLanguage(it[0]),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  GradientIcon(Icons.language_rounded, size: 46),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(it[1],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Icon(chevron(context), color: muted(context)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
