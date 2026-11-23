import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    return GlassScaffold(
      title: s.t('customer_title'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: muted(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.t('search_hint'),
                      style: TextStyle(color: muted(context))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Glass(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const GradientIcon(Icons.content_cut_rounded, size: 70),
                const SizedBox(height: 18),
                Text(s.t('customer_soon_title'),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  s.t('customer_soon_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted(context), height: 1.7),
                ),
                const SizedBox(height: 14),
                const Pill('Beta', color: AppColors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
