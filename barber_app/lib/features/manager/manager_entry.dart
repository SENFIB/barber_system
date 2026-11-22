import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../settings/settings_page.dart';

class ManagerEntry extends StatelessWidget {
  const ManagerEntry({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S(settings.lang);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('shop')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: s.t('settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsPage(settings: settings),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 64),
              const SizedBox(height: 16),
              Text(s.t('shop_soon'), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
