import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);

    Widget card({
      required IconData icon,
      required Gradient gradient,
      required String title,
      required String desc,
      required VoidCallback onTap,
    }) {
      return Glass(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GradientIcon(icon, size: 64, gradient: gradient),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(desc,
                      style: TextStyle(color: muted(context), height: 1.5)),
                ],
              ),
            ),
            Icon(chevron(context), color: muted(context)),
          ],
        ),
      );
    }

    return GlassScaffold(
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
        children: [
          const Center(child: AppLogo()),
          const SizedBox(height: 20),
          Center(
            child: Text(s.t('welcome'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(s.t('who_are_you'),
                style: TextStyle(color: muted(context), fontSize: 16)),
          ),
          const SizedBox(height: 30),
          // اول آرایشگاه
          card(
            icon: Icons.storefront_rounded,
            gradient: AppColors.gradient,
            title: s.t('role_shop'),
            desc: s.t('role_shop_desc'),
            onTap: () => st.setRole('shop'),
          ),
          const SizedBox(height: 16),
          // زیرش مشتری
          card(
            icon: Icons.person_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.pink, AppColors.amber],
            ),
            title: s.t('role_customer'),
            desc: s.t('role_customer_desc'),
            onTap: () => st.setRole('customer'),
          ),
        ],
      ),
    );
  }
}
