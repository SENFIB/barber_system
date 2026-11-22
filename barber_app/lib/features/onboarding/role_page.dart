import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import 'language_page.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S(settings.lang);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('app_name'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.content_cut, size: 64),
              const SizedBox(height: 16),
              Text(
                s.t('who_are_you'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.person_search,
                title: s.t('customer'),
                subtitle: s.t('customer_desc'),
                onTap: () => settings.setRole('customer'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.storefront,
                title: s.t('shop'),
                subtitle: s.t('shop_desc'),
                onTap: () => settings.setRole('shop'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.language),
                label: Text(s.t('change_language')),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LanguagePage(settings: settings, fromSettings: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
