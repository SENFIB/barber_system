import 'package:flutter/material.dart';

import '../../app/settings.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({
    super.key,
    required this.settings,
    this.fromSettings = false,
  });

  final AppSettings settings;
  final bool fromSettings;

  static const List<(String, String)> _langs = [
    ('fa', 'فارسی'),
    ('en', 'English'),
    ('ar', 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('زبان / Language / اللغة')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.language, size: 64),
              const SizedBox(height: 24),
              for (final l in _langs) ...[
                SizedBox(
                  height: 60,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await settings.setLanguage(l.$1);
                      if (fromSettings && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l.$2, style: const TextStyle(fontSize: 20)),
                        if (settings.language == l.$1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
