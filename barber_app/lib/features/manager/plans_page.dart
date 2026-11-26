import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/fmt.dart';
import '../../app/plans_config.dart';
import '../../app/settings.dart';
import '../../app/strings_pay.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'pay_api.dart';
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
      case 'personal':
        return Icons.dns_rounded;
    }
    return Icons.content_cut_rounded;
  }

  String _priceLine(PlanDef p, T6 t, String lang) {
    if (p.autoPay) {
      return t.t('pl_per_month',
          {'p': fmtNum(p.usdtMonthly, lang), 'c': 'USDT'});
    }
    final c = t.t('pl_toman');
    if (p.oneTime > 0) {
      return t.t('pl_one_time', {'p': fmtNum(p.oneTime, lang), 'c': c});
    }
    if (p.monthly == 0) return t.t('pl_free_now');
    return t.t('pl_per_month', {'p': fmtNum(p.monthly, lang), 'c': c});
  }

  int _total(PlanDef p) {
    if (p.oneTime > 0) return p.oneTime;
    if (p.autoPay) return planTotalUsdt(p, _months);
    return planTotal(p, _months);
  }

  /// خرید خودکار با تتر (پایه و پرو)
  Future<void> _buyUsdt(PlanDef p) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayPage(ctx: widget.ctx, plan: p, months: _months),
      ),
    );
    if (ok == true) {
      await widget.ctx.reload();
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// ثبت درخواست (ویژه و شخصی)
  Future<void> _request(PlanDef p, String lang) async {
    final pt = PayT(lang);
    final t6 = T6(lang);
    final contact = TextEditingController();
    final note = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(pt.t('req_title', {'plan': t6.t('pl_name_${p.key}')})),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pt.t('req_desc')),
              const SizedBox(height: 12),
              TextField(
                controller: contact,
                decoration: InputDecoration(labelText: pt.t('req_contact')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: InputDecoration(labelText: pt.t('req_note')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(pt.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (contact.text.trim().length < 3) return;
              Navigator.pop(c, true);
            },
            child: Text(pt.t('req_send')),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final shop = widget.ctx.session.shop;
    try {
      await PayApi(widget.ctx.api.settings).request(
        plan: p.key,
        months: p.oneTime > 0 ? 0 : _months,
        shopName: shop.name,
        phone: shop.phone,
        contact: contact.text.trim(),
        note: note.text.trim(),
      );
      if (mounted) toast(context, pt.t('req_ok'));
    } on ApiException catch (e) {
      if (mounted) toast(context, pt.error(e));
    } catch (_) {
      if (mounted) toast(context, pt.t('err_NETWORK'));
    }
  }

  /// «کد لایسنس دارم»: برای پلن ویژه/شخصی دو کادر (لایسنس + exec) نشان می‌دهد
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
    final tomanPaid = p.oneTime > 0 || p.monthly > 0;
    final paid = isUsdt || tomanPaid;
    final monthly = p.oneTime == 0 && (isUsdt || p.monthly > 0);
    final unit = isUsdt ? 'USDT' : t.t('pl_toman');
    final total = _total(p);
    final base = isUsdt ? p.usdtMonthly : p.monthly;
    final full = monthly ? base * _months : total;
    final saved = full - total;
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
          if (saved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.t('pl_save', {'p': fmtNum(saved, lang), 'c': unit}),
                style: const TextStyle(color: AppColors.green),
              ),
            ),
          const SizedBox(height: 14),
          if (isUsdt)
            GradientButton(
              icon: Icons.shopping_cart_rounded,
              label: pt.t('buy_usdt'),
              onPressed: () {
                _buyUsdt(p);
              },
            )
          else
            GradientButton(
              icon: Icons.support_agent_rounded,
              label: pt.t('req_btn'),
              onPressed: () {
                _request(p, lang);
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
