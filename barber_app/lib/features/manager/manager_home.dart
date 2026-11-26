import 'package:flutter/material.dart';
import '../../app/app_header.dart';
import '../../app/biz_panel.dart';
import '../../app/cal_fmt.dart';
import '../../app/fmt.dart';
import '../../app/reminders.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_s3.dart';
import '../../app/strings_s5.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'ads_page.dart';
import 'booking_rules_page.dart';
import 'bookings_page.dart';
import 'plans_page.dart';
import 'renew_page.dart';
import 'services_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';
import 'staff_page.dart';
import 'timeoff_page.dart';
import 'winback_page.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

String _subLabel(String lang, String plan, String fallback) {
  switch (plan) {
    case 'basic':
      return _x(lang, 'اشتراک پایه', 'Basic subscription', 'الاشتراك الأساسي');
    case 'pro':
      return _x(lang, 'اشتراک پرو', 'Pro subscription', 'اشتراك برو');
    case 'special':
      return _x(
          lang, 'اشتراک ویژه', 'Special subscription', 'الاشتراك المميز');
    default:
      return fallback;
  }
}

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key, required this.ctx});

  final ShopCtx ctx;

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  String _synced = '';
  String _bizType = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadType());
  }

  @override
  void dispose() {
    // هدر دوباره لوگوی خود برنامه را نشان بدهد
    WidgetsBinding.instance
        .addPostFrameCallback((_) => kHeaderBrand.value = null);
    super.dispose();
  }

  Future<void> _loadType() async {
    try {
      final me = await ShopRaw(SettingsScope.read(context)).call('me');
      if (!mounted) return;
      final sh = me['shop'];
      if (sh is Map) {
        final k = '${sh['biz_type'] ?? ''}';
        final plan = '${sh['plan'] ?? ''}'.toLowerCase();
        final photo = '${sh['photo_url'] ?? sh['photo'] ?? ''}'.trim();
        final name = '${sh['name'] ?? ''}';
        final special = plan == 'special' || plan == 'personal';
        kHeaderBrand.value = (special && photo.startsWith('http'))
            ? HeaderBrand(photo, name)
            : null;
        if (k != _bizType) setState(() => _bizType = k);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final settings = SettingsScope.of(context);
    final lang = settings.lang;
    final s = S(lang);
    final t3 = T3(lang);
    final t5 = T5(lang);
    final sess = ctx.session;
    final sub = sess.subscription;
    final shop = sess.shop;
    final planKey = 'plan_${shop.plan}';
    final panel =
        BizPanel.of(_bizType.isNotEmpty ? _bizType : shop.bizType);

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

    final roleText = sess.isOwner
        ? _x(lang, 'مدیر', 'Owner', 'المدير')
        : _x(lang, 'نفر پرسنل', 'Staff member', 'موظف');
    final planText = s.has(planKey) ? s.t(planKey) : shop.plan;
    final pills = <Widget>[
      Pill(roleText),
    ];
    if (sess.isOwner && shop.plan.isNotEmpty) {
      pills.add(Pill(planText, color: AppColors.blue));
    }
    final typeText = panel.typeName(lang);
    if (typeText.isNotEmpty) {
      pills.add(Pill(typeText, color: AppColors.green));
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
          GradientIcon(panel.icon, size: 62),
          const SizedBox(width: 16),
          Expanded(child: headerInfo),
        ],
      ),
    );

    Widget warnCard() {
      final n = fmtNum(sub.daysLeft ?? sub.warnDays, lang);
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
                  _x(
                    lang,
                    'اشتراک شما تا $n روز دیگر تمام می‌شود. لطفاً تمدید کنید.',
                    'Your subscription ends in $n days. Please renew.',
                    'ينتهي اشتراكك خلال $n أيام. يرجى التجديد.',
                  ),
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
          Flexible(
            child: Text(
              _subLabel(lang, shop.plan, s.t('subscription')),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
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
              CalFmt.date(sub.expiresAt, settings.calendarKey, lang),
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
    if (sess.isOwner) {
      if (sub.expiringSoon) items.add(warnCard());
      items.add(subCard);
    }
    items.add(const SizedBox(height: 18));

    items.add(tile(
      icon: Icons.event_available_rounded,
      title: s.t('bookings'),
      desc: _x(
        lang,
        'نوبت‌های مشتری‌ها را ببین، لغو کن یا تمام‌شده ثبت کن',
        'See customer appointments, cancel them or mark them done',
        'اعرض مواعيد الزبائن وألغِها أو سجّلها كمنتهية',
      ),
      gradient: const LinearGradient(
        colors: [AppColors.pink, AppColors.amber],
      ),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => BookingsPage(ctx))),
    ));

    if (sess.isOwner) {
      items.add(tile(
        icon: Icons.groups_rounded,
        title: panel.staffTitle(lang),
        desc: panel.staffDesc(lang),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => StaffPage(ctx))),
      ));
    } else {
      items.add(tile(
        icon: Icons.schedule_rounded,
        title: _x(lang, 'ساعت کار و روزهای تعطیل من',
            'My hours and days off', 'ساعات عملي وأيام عطلتي'),
        desc: _x(
          lang,
          'ساعت کاری و روزهای تعطیل خودت را تنظیم و تغییر بده',
          'Set and change your own working hours and days off',
          'حدّد وعدّل ساعات عملك وأيام عطلتك',
        ),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.green],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => StaffPage(ctx))),
      ));
    }

    if (sess.isOwner) {
      items.add(tile(
        icon: Icons.design_services_rounded,
        title: _x(lang, 'خدمات', 'Services', 'الخدمات'),
        desc: _x(
          lang,
          'خدمت‌ها، مدت و قیمت‌ها را اضافه و ویرایش کن',
          'Add and edit your services, durations and prices',
          'أضف وعدّل خدماتك ومددها وأسعارها',
        ),
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
          'بازهٔ رزرو، روز تعطیل، لغو، واحد پول و تعطیلی‌های آینده',
          'Booking range, day off, cancellation, currency and planned closures',
          'فترة الحجز والعطلة والإلغاء والعملة والإغلاقات المخطط لها',
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
        desc: _x(
          lang,
          'روزها و ساعت‌هایی که کار نمی‌کنید را ثبت کن',
          'Record the days and hours you are not working',
          'سجّل الأيام والساعات التي لا تعمل فيها',
        ),
        gradient: const LinearGradient(
          colors: [AppColors.amber, AppColors.pink],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => TimeOffPage(ctx))),
      ));
      items.add(tile(
        icon: Icons.favorite_rounded,
        title: panel.msgTitle(lang),
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
        icon: Icons.campaign_rounded,
        title: _x(lang, 'تبلیغات', 'Advertising', 'الإعلانات'),
        desc: _x(
          lang,
          'معرفی کسب‌وکار شما در صفحه‌ی کسب‌وکارهای دیگر',
          'Promote your business on other businesses’ pages',
          'روّج لنشاطك في صفحات الأنشطة الأخرى',
        ),
        gradient: const LinearGradient(
          colors: [AppColors.amber, AppColors.violet],
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AdsPage())),
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
      actions: [
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
        onRefresh: () async {
          await ctx.reload();
          await _loadType();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: items,
        ),
      ),
    );
  }
}
