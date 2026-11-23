import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    return GlassScaffold(
      title: s.t('app_name'),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Glass(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GradientIcon(Icons.storefront_rounded, size: 48),
                const SizedBox(height: 14),
                Text(
                  s.t('soon'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
