import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/plans_config.dart';
import '../../app/settings.dart';
import '../../app/strings_s5.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
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

  String _digits(String s, String lang) {
    if (lang != 'fa' && lang != 'ar') return s;
    final d = lang == 'fa' ? '۰۱۲۳۴۵۶۷۸۹' : '٠١٢٣٤٥٦٧٨٩';
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      final i = '0123456789'.indexOf(ch);
      sb.write(i >= 0 ? d[i] : ch);
    }
    return sb.toString();
  }

  String _money(int v, String lang) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return _digits(b.toString(), lang);
  }

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

  String _priceLine(PlanDef p, T5 t, String lang) {
    final c = t.t('pl_toman');
    if (p.oneTime > 0) {
      return t.t('pl_one_time', {'p': _money(p.oneTime, lang), 'c': c});
    }
    if (p.monthly == 0) return t.t('pl_free_now');
    return t.t('pl_per_month', {'p': _money(p.monthly, lang), 'c': c});
  }

  int _total(PlanDef p) {
    if (p.oneTime > 0) return p.oneTime;
    return planTotal(p, _months);
  }

  String _summary(PlanDef p, T5 t, String lang) {
    final c = t.t('pl_toman');
    final months = p.oneTime > 0
        ? t.t('pl_months_one_time')
        : t.t('pl_months', {'n': _digits('$_months', lang)});
    return t.t('pl_order', {
      'plan': t.t('pl_name_${p.key}'),
      'months': months,
      'total': _money(_total(p), lang),
      'c': c,
      'shop': widget.ctx.session.shop.name,
    });
  }

  Future<void> _buy(PlanDef p, T5 t, String lang) async {
    final text = _summary(p, t, lang);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.t('pl_buy_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(text,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Text(kPayContact.trim().isEmpty
                  ? t.t('pl_unset')
                  : t.t('pl_contact', {'c': kPayContact})),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(t.t('pl_close')),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              final m = ScaffoldMessenger.maybeOf(context);
              m?.hideCurrentSnackBar();
              m?.showSnackBar(SnackBar(content: Text(t.t('pl_copied'))));
              Navigator.of(c).pop();
            },
            child: Text(t.t('pl_copy')),
          ),
        ],
      ),
    );
  }

  Future<void> _haveCode() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RenewPage(api: widget.ctx.api)),
    );
    if (ok == true) {
      await widget.ctx.reload();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final t = T5(lang);
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

  Widget _card(PlanDef p, T5 t, String lang, bool current) {
    final sel = _sel == p.key;
    final nArgs = <String, String>{'n': _digits('${p.maxBarbers}', lang)};
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

  Widget _panel(PlanDef p, T5 t, String lang) {
    final c = t.t('pl_toman');
    final paid = p.oneTime > 0 || p.monthly > 0;
    final monthly = p.oneTime == 0 && p.monthly > 0;
    final total = _total(p);
    final full = monthly ? p.monthly * _months : total;
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
                        ? '${t.t('pl_months', {'n': _digits('$m', lang)})} · ${t.t('pl_off', {'n': _digits('${kDiscountPercent[m]}', lang)})}'
                        : t.t('pl_months', {'n': _digits('$m', lang)}),
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
              Text('${_money(total, lang)} $c',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          if (saved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.t('pl_save', {'p': _money(saved, lang), 'c': c}),
                style: const TextStyle(color: AppColors.green),
              ),
            ),
          const SizedBox(height: 14),
          GradientButton(
            icon: Icons.shopping_cart_rounded,
            label: t.t('pl_buy'),
            onPressed: () {
              _buy(p, t, lang);
            },
          ),
          const SizedBox(height: 10),
        ],
        GradientButton(
          outlined: true,
          icon: Icons.vpn_key_rounded,
          label: t.t('pl_have_code'),
          onPressed: () {
            _haveCode();
          },
        ),
      ],
    );
  }
}
