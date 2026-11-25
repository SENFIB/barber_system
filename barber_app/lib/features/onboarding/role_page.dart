import 'package:flutter/material.dart';
import '../../app/brand.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    final l = st.lang;

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
        children: [
          const Center(child: EsmairoLogo(size: 92)),
          const SizedBox(height: 22),
          Center(
            child: Text(s.t('welcome'),
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(s.t('who_are_you'),
                style: TextStyle(color: muted(context), fontSize: 16)),
          ),
          const SizedBox(height: 30),
          card(
            icon: Icons.storefront_rounded,
            gradient: AppColors.gradient,
            title: _x(l, 'کسب‌وکار', 'Business', 'نشاط تجاري'),
            desc: _x(
                l,
                'ورود یا ثبت‌نام کسب‌وکار، مدیریت نوبت‌ها و پرسنل',
                'Log in or sign up your business, manage bookings and staff',
                'دخول أو تسجيل نشاطك وإدارة المواعيد والموظفين'),
            onTap: () => st.setRole('shop'),
          ),
          const SizedBox(height: 16),
          card(
            icon: Icons.person_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.pink, AppColors.amber],
            ),
            title: s.t('role_customer'),
            desc: _x(
                l,
                'جستجوی کسب‌وکار و رزرو نوبت',
                'Find a business and book an appointment',
                'ابحث عن نشاط واحجز موعدًا'),
            onTap: () => st.setRole('customer'),
          ),
        ],
      ),
    );
  }
}
