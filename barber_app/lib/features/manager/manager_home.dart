import 'package:flutter/material.dart';
import '../../app/fmt.dart';
import '../../app/reminders.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_s3.dart';
import '../../app/strings_s5.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';
import 'booking_rules_page.dart';
import 'bookings_page.dart';
import 'plans_page.dart';
import 'renew_page.dart';
import 'services_page.dart';
import 'shop_api.dart';
import 'staff_page.dart';
import 'timeoff_page.dart';
import 'winback_page.dart';
String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);
class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key, required this.ctx});
  final ShopCtx ctx;
  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}
class _ManagerHomeState extends State<ManagerHome> {
  String _synced = '';
  String _date(String? d, String lang) {
    if (d == null || d.isEmpty) return '—';
    final s = d.length >= 10 ? d.substring(0, 10) : d;
    return localDigits(s, lang);
  }
  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final lang = SettingsScope.of(context).lang;
    final s = S(lang);
    final t3 = T3(lang);
    final t5 = T5(lang);
    final sess = ctx.session;
    final sub = sess.subscription;
    final shop = sess.shop;
    final planKey = 'plan_${shop.plan}';
    // اعلان‌های محلیِ پایان اشتراک (۳ و ۱ روز مانده) — فقط برای صاحب
    if (sess.isOwner) {
      final k = '${sub.free}|${sub.expiresAt}|$lang';
      if (k != _synced) {
        _synced = k;
        final exp = sub.expiresAt ?? '';
        final free = sub.free;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (free || exp.isEmpty) {
            Reminders.cancelExpiry();
          } else {
            Reminders.ask().then((_) => Reminders.expiry(exp, lang));
          }
        });
      }
    }
    Widget tile({
      required IconData icon,
      required String title,
      required String desc,
      VoidCallback? onTap,
      Gradient? gradient,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Glass(
          onTap: onTap,
          child: Row(
            children: [
              GradientIcon(icon, size: 50, gradient: gradient),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style:
                            TextStyle(color: muted(context), fontSize: 12.5)),
                  ],
                ),
              ),
              if (onTap == null)
                Pill(s.t('soon'), color: AppColors.amber)
              else
                Icon(chevron(context), color: muted(context)),
            ],
          ),
        ),
      );
    }
    return GlassScaffold(
      title: s.t('app_name'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: s.t('logout'),
              message: s.t('logout_confirm'),
              okLabel: s.t('logout'),
              cancelLabel: s.t('cancel'),
              danger: true,
            );
            if (ok) {
              Reminders.cancelExpiry();
              await ctx.logout();
            }
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: ctx.reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // سربرگ
            Glass(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const GradientIcon(Icons.storefront_rounded, size: 62),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Pill(s.t(sess.isOwner ? 'role_owner' : 'role_staff')),
                            if (shop.plan.isNotEmpty)
                              Pill(
                                s.has(planKey) ? s.t(planKey) : shop.plan,
                                color: AppColors.blue,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
