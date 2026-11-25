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
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(color: muted(context), fontSize: 12.5),
                    ),
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

    final roleText = s.t(sess.isOwner ? 'role_owner' : 'role_staff');
    final planText = s.has(planKey) ? s.t(planKey) : shop.plan;

    final pills = <Widget>[
      Pill(roleText),
    ];
    if (shop.plan.isNotEmpty) {
      pills.add(Pill(planText, color: AppColors.blue));
    }

    final headerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.name,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: pills),
      ],
    );

    final headerCard = Glass(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const GradientIcon(Icons.storefront_rounded, size: 62),
          const SizedBox(width: 16),
          Expanded(child: headerInfo),
        ],
      ),
    );

    Widget warnCard() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Glass(
          tint: AppColors.amber.withOpacity(0.18),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.t('expiring_warn',
                      {'n': '${sub.daysLeft ?? sub.warnDays}'}),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final subRows = <Widget>[
      Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            s.t('subscription'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (sub.free) Pill(s.t('sub_free'), color: AppColors.green),
        ],
      ),
    ];

    if (!sub.free) {
      subRows.add(const SizedBox(height: 12));
      subRows.add(
        Row(
          children: [
            Text('${s.t('sub_expires')}: ',
                style: TextStyle(color: muted(context))),
            Text(
              _date(sub.expiresAt, lang),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
      if (sub.daysLeft != null) {
        subRows.add(const SizedBox(height: 4));
        subRows.add(
          Text(
            '${fmtNum(sub.daysLeft!, lang)} ${s.t('sub_days_left')}',
            style: TextStyle(color: muted(context)),
          ),
        );
      }
      if (sess.isOwner) {
        subRows.add(const SizedBox(height: 14));
        subRows.add(
          GradientButton(
            compact: true,
            outlined: true,
            icon: Icons.autorenew_rounded,
            label: s.t('renew'),
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => RenewPage(api: ctx.api)),
              );
              if (ok == true) await ctx.reload();
            },
          ),
        );
      }
    }

    final subCard = Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subRows,
      ),
    );

    final items = <Widget>[
      headerCard,
      const SizedBox(height: 14),
    ];
    if (sub.expiringSoon) items.add(warnCard());
    items.add(subCard);
    items.add(const SizedBox(height: 18));

    items.add(tile(
      icon: Icons.event_available_rounded,
      title: s.t('bookings'),
      desc: s.t('bookings_desc'),
      gradient: const LinearGradient(
        colors: [AppColors.pink, AppColors.amber],
      ),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => BookingsPage(ctx))),
    ));

    items.add(tile(
      icon: Icons.groups_rounded,
      title: s.t(sess.isOwner ? 'manage_barbers' : 'staff_mine'),
      desc: s.t(sess.isOwner ? 'manage_barbers_desc' : 'staff_mine_desc'),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => StaffPage(ctx))),
    ));

    if (sess.isOwner) {
      items.add(tile(
        icon: Icons.design_services_rounded,
        title: s.t('services'),
        desc: s.t('services_desc'),
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.blue],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ServicesPage(ctx: ctx))),
      ));

      items.add(tile(
        icon: Icons.rule_folder_rounded,
        title: _x(lang, 'قوانین و زمان رزرو', 'Booking rules', 'قواعد الحجز'),
        desc: _x(
          lang,
          'بازهٔ رزرو، روز تعطیل، تعطیلی‌های آینده، نوع آرایشگاه و خدمات پیشنهادی',
          'Booking range, days off, planned closures, shop type and suggested services',
          'فترة الحجز والعطل والإغلاقات المخطط لها ونوع الصالون والخدمات المقترحة',
        ),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.green],
        ),
        onTap: () {
          final st = SettingsScope.of(context);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BookingRulesPage(settings: st)));
        },
      ));

      items.add(tile(
        icon: Icons.event_busy_rounded,
        title: t3.t('b_timeoff'),
        desc: t3.t('b_timeoff_desc'),
        gradient: const LinearGradient(
          colors: [AppColors.amber, AppColors.pink],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => TimeOffPage(ctx))),
      ));

      items.add(tile(
        icon: Icons.favorite_rounded,
        title: _x(lang, 'پیام اختصاصی آرایشگاه', 'Custom shop message',
            'رسالة خاصة بالصالون'),
        desc: _x(
          lang,
          'متن پیام‌ها و فاصلهٔ زمانی ارسال برای مشتری‌ها',
          'Message texts and how many days later they are sent to customers',
          'نصوص الرسائل وعدد الأيام لإرسالها للزبائن',
        ),
        gradient: const LinearGradient(
          colors: [AppColors.pink, AppColors.blue],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => WinbackPage(ctx))),
      ));

      items.add(tile(
        icon: Icons.workspace_premium_rounded,
        title: t5.t('pl_tile'),
        desc: t5.t('pl_tile_desc'),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.pink],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => PlansPage(ctx))),
      ));
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
          children: items,
        ),
      ),
    );
  }
}
