import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/fmt.dart';
import '../../app/plans_config.dart';
import '../../app/settings.dart';
import '../../app/strings_pay.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'pay_page.dart';
import 'renew_page.dart';
import 'shop_api.dart';

class PlansPage extends StatefulWidget {
  const PlansPage(this.ctx, {super.key});
  final ShopCtx ctx;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String _sel = '';
  int _months = 1;

  IconData _icon(String key) {
    switch (key) {
      case 'pro':
        return Icons.workspace_premium_rounded;
      case 'special':
        return Icons.diamond_rounded;
    }
    return Icons.content_cut_rounded;
  }

  String _priceLine(PlanDef p, T6 t, String lang) {
    final c = t.t('pl_toman');
    if (p.autoPay) {
      final usdt = t.t('pl_per_month',
          {'p': fmtNum(p.usdtMonthly, lang), 'c': 'USDT'});
      if (lang == 'fa' && p.cardPay) {
        final toman =
            t.t('pl_per_month', {'p': fmtNum(p.monthly, lang), 'c': c});
        return '$toman  ·  $usdt';
      }
      return usdt;
    }
    if (p.monthly == 0) return t.t('pl_free_now');
    return t.t('pl_per_month', {'p': fmtNum(p.monthly, lang), 'c': c});
  }

  /// جمع به واحد اصلی پلن (تتر برای پایه و پرو، تومان برای ویژه)
  int _total(PlanDef p) {
    if (p.autoPay) return planTotalUsdt(p, _months);
    return planTotal(p, _months);
  }

  /// خرید آنلاین. method: 'usdt' یا 'card'
  Future<void> _buy(PlanDef p, String method) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayPage(
          ctx: widget.ctx,
          plan: p,
          months: _months,
          method: method,
        ),
      ),
    );
    if (ok == true) {
      await widget.ctx.reload();
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// نام کاربری مدیر (اگر در session باشد)
  String _username() {
    try {
      final v = (widget.ctx.session as dynamic).username;
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    } catch (_) {}
    return '';
  }

  /// پلن ویژه: باز کردن برنامه‌ی ایمیل با متن آماده (همیشه فارسی)
  Future<void> _mail(PlanDef p, String lang) async {
    final pt = PayT(lang);
    final shop = widget.ctx.session.shop;
    final user = _username();
    final subject = PayT.mailSubject(p.key);
    final body = PayT.mailBody(
      planKey: p.key,
      shopName: shop.name,
      phone: shop.phone,
      username: user.isEmpty ? '—' : user,
    );
    final uri = Uri.parse(
        'mailto:$kSupportEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: kSupportEmail));
      if (mounted) toast(context, pt.t('mail_copied', {'e': kSupportEmail}));
    }
  }

  /// «کد لایسنس دارم»: برای پلن ویژه دو کادر (لایسنس + exec) نشان می‌دهد
  Future<void> _haveCode(String planKey) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RenewPage(
          api: widget.ctx.api,
          plan: planKey,
          currentPlan: widget.ctx.session.shop.plan,
        ),
      ),
    );
    if (ok == true) {
      await widget.ctx.reload();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final t = T6(lang);
    final cur = widget.ctx.session.shop.plan;
    return GlassScaffold(
      title: t.t('pl_title'),
      maxWidth: 640,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(t.t('pl_desc'),
                style: TextStyle(color: muted(context))),
          ),
          for (final p in kPlans) _card(p, t, lang, p.key == cur),
        ],
      ),
    );
  }

  Widget _card(PlanDef p, T6 t, String lang, bool current) {
    final sel = _sel == p.key;
    final nArgs = <String, Object?>{'n': p.maxBarbers, 's': p.maxShifts};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        onTap: () => setState(() => _sel = p.key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientIcon(_icon(p.key), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('pl_name_${p.key}'),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(_priceLine(p, t, lang),
                          style: TextStyle(
                              color: muted(context), fontSize: 13)),
                    ],
                  ),
                ),
                if (current) Pill(t.t('pl_current'), color: AppColors.green),
                if (sel && !current)
                  Icon(Icons.check_circle_rounded,
                      color: lk(context).primary),
              ],
            ),
            const SizedBox(height: 12),
            for (final f in p.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.t(f, nArgs))),
                  ],
                ),
              ),
            if (sel) ...[
              const Divider(height: 24),
              _panel(p, t, lang),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel(PlanDef p, T6 t, String lang) {
    final pt = PayT(lang);
    final isUsdt = p.autoPay;
    final paid = isUsdt || p.monthly > 0;
    final monthly = isUsdt || p.monthly > 0;
    final unit = isUsdt ? 'USDT' : t.t('pl_toman');
    final total = _total(p);
    final base = isUsdt ? p.usdtMonthly : p.monthly;
    final full = monthly ? base * _months : total;
    final saved = full - total;
    final showCard = lang == 'fa' && p.cardPay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (monthly)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kMonthOptions)
                ChoiceChip(
                  label: Text(
                    (kDiscountPercent[m] ?? 0) > 0
                        ? '${t.t('pl_months', {'n': m})} · ${t.t('pl_off', {'n': kDiscountPercent[m]})}'
                        : t.t('pl_months', {'n': m}),
                  ),
                  selected: _months == m,
                  onSelected: (_) => setState(() => _months = m),
                ),
            ],
          ),
        if (paid) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('${t.t('pl_total')}: ',
                  style: TextStyle(color: muted(context))),
              Text('${fmtNum(total, lang)} $unit',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          if (showCard)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${fmtNum(planTotal(p, _months), lang)} ${t.t('pl_toman')}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          if (saved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.t('pl_save', {'p': fmtNum(saved, lang), 'c': unit}),
                style: const TextStyle(color: AppColors.green),
              ),
            ),
          const SizedBox(height: 14),
          if (isUsdt) ...[
            GradientButton(
              icon: Icons.currency_bitcoin_rounded,
              label: pt.t('buy_usdt'),
              onPressed: () {
                _buy(p, 'usdt');
              },
            ),
            if (showCard) ...[
              const SizedBox(height: 10),
              GradientButton(
                icon: Icons.credit_card_rounded,
                label: pt.t('buy_card'),
                onPressed: () {
                  _buy(p, 'card');
                },
              ),
            ],
          ] else
            GradientButton(
              icon: Icons.mail_rounded,
              label: pt.t('mail_btn'),
              onPressed: () {
                _mail(p, lang);
              },
            ),
          const SizedBox(height: 10),
        ],
        GradientButton(
          outlined: true,
          icon: Icons.vpn_key_rounded,
          label: t.t('pl_have_code'),
          onPressed: () {
            _haveCode(p.key);
          },
        ),
      ],
    );
  }
}
