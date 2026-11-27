import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/config.dart';
import '../../app/fmt.dart';
import '../../app/plans_config.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_pay.dart';
import '../../app/widgets.dart';
import 'activation_code.dart';
import 'pay_page.dart';
import 'plan_move.dart';
import 'server_code.dart';
import 'shop_api.dart';

const Map<String, String> _changePlanLabel = {
  'fa': 'تغییر پلن',
  'en': 'Change plan',
  'ar': 'تغيير الخطة',
};

String _x(String lang, String fa, String en, String ar) =>
    lang == 'fa' ? fa : (lang == 'ar' ? ar : en);

/// تمدید یا فعال‌سازی.
/// برای basic و pro سه راه دارد: پرداخت USDT، کارت‌به‌کارت (فقط فارسی) و کد لایسنس.
/// برای پلن ویژه/شخصی: همان دو کادر کد و لینک، به‌اضافه‌ی دکمه‌ی ایمیل (فقط ویژه).
/// [plan]: پلنی که کاربر انتخاب کرده (خالی = تمدید پلن فعلی)
/// [currentPlan]: پلن فعلی کسب‌وکار
/// [shopName]/[phone]/[username]: اختیاری؛ فقط برای پر شدن ایمیل سفارش.
/// با موفقیت که تمام شد `true` برمی‌گرداند.
class RenewPage extends StatefulWidget {
  const RenewPage({
    super.key,
    required this.api,
    this.plan = '',
    this.currentPlan = '',
    this.shopName = '',
    this.phone = '',
    this.username = '',
  });
  final ShopApi api;
  final String plan;
  final String currentPlan;
  final String shopName;
  final String phone;
  final String username;

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage> {
  final _key = TextEditingController();
  final _exec = TextEditingController();
  bool _loading = false;
  int _months = 1;

  String get _target =>
      widget.plan.isEmpty ? widget.currentPlan : widget.plan;
  bool get _isMove =>
      widget.plan.isNotEmpty && widget.plan != widget.currentPlan;
  bool get _needsLink => _target == 'special' || _target == 'personal';

  PlanDef? get _planDef {
    for (final p in kPlans) {
      if (p.key == _target) return p;
    }
    return null;
  }

  bool get _canPay => _planDef != null && _planDef!.autoPay;

  @override
  void dispose() {
    _key.dispose();
    _exec.dispose();
    super.dispose();
  }

  Future<void> _plainRenew(String lic, S s) async {
    setState(() => _loading = true);
    try {
      await widget.api.renew(lic);
      if (!mounted) return;
      toast(context, s.t('renew_ok'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renew() async {
    if (_loading) return;
    final st = SettingsScope.read(context);
    final lang = st.lang;
    final s = S(lang);
    final raw = _key.text.trim();
    if (raw.isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    String lic = raw;
    String? url;
    if (_needsLink) {
      final p = splitActivation(raw);
      if (p.license.isEmpty) {
        toast(context, s.t('v_required'));
        return;
      }
      lic = p.license;
      url = p.url ?? normalizeServerCode(_exec.text);
      if (url == null && _exec.text.trim().isNotEmpty) {
        toast(context, moveMsg(lang, 'bad_code'));
        return;
      }
      if (url == null && _isMove) {
        toast(context, moveMsg(lang, 'need_exec'));
        return;
      }
    } else if (_isMove) {
      url = _target == 'basic' ? kDefaultApiUrl : kProApiUrl;
    }
    // بدون انتقال: تمدید ساده روی همین سرور
    if (url == null) {
      await _plainRenew(lic, s);
      return;
    }
    if (url != st.apiUrl) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(moveMsg(lang, 'confirm')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(moveMsg(lang, 'no'))),
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(moveMsg(lang, 'yes'))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final r = await PlanMover.move(
          st: st, targetUrl: url, license: lic, plan: _target);
      var msg = moveMsg(lang, 'done');
      if (r.trimmedStaff > 0 || r.trimmedShifts > 0) {
        msg +=
            '\n${moveMsg(lang, 'trim').replaceAll('{a}', '${r.trimmedStaff}').replaceAll('{b}', '${r.trimmedShifts}')}';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      await restartAfterMove(st, nav);
      return;
    } on MoveError catch (e) {
      if (mounted) toast(context, moveMsg(lang, e.code));
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } catch (_) {
      if (mounted) toast(context, moveMsg(lang, 'other'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────── پرداخت (basic / pro) ─────────────
  // PayPage در «حالت ثبت‌نام» لایسنس را به‌صورت String برمی‌گرداند؛
  // بعد همان مسیر قبلی تمدید/تغییر پلن با آن لایسنس اجرا می‌شود.
  Future<void> _pay(String method) async {
    if (_loading) return;
    final plan = _planDef;
    if (plan == null) return;
    final st = SettingsScope.read(context);
    final lic = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => PayPage(
        settings: st,
        plan: plan,
        months: _months,
        method: method,
        shopName: widget.shopName,
        phone: widget.phone,
      ),
    ));
    if (!mounted) return;
    if (lic != null && lic.trim().isNotEmpty) {
      setState(() => _key.text = lic.trim());
      await _renew();
    }
  }

  Widget _payBox(String lang) {
    final p = _planDef!;
    final pt = PayT(lang);
    final showToman = lang == 'fa' && p.monthly > 0;
    final usdt = planTotalUsdt(p, _months).round();
    final toman = planTotal(p, _months).round();
    final monthWord = _x(lang, 'ماه', 'mo', 'شهر');
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _x(lang, 'خرید اشتراک', 'Buy a subscription', 'شراء الاشتراك'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              _x(
                  lang,
                  'بعد از پرداخت، تمدید خودکار انجام می‌شود.',
                  'After payment, renewal is applied automatically.',
                  'بعد الدفع يتم التجديد تلقائيًا.'),
              style: TextStyle(
                  color: muted(context), fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kMonthOptions)
                ChoiceChip(
                  label: Text('${fmtNum(m, lang)} $monthWord'),
                  selected: _months == m,
                  onSelected: _loading
                      ? null
                      : (_) => setState(() => _months = m),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              '${_x(lang, 'مبلغ کل', 'Total', 'الإجمالي')}: '
              '${fmtNum(usdt, lang)} USDT'
              '${showToman ? '  •  ${fmtNum(toman, lang)} ${_x(lang, 'تومان', 'Toman', 'تومان')}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          GradientButton(
            label: pt.t('buy_usdt'),
            icon: Icons.currency_bitcoin_rounded,
            onPressed: _loading ? null : () => _pay('usdt'),
          ),
          if (lang == 'fa' && p.cardPay) ...[
            const SizedBox(height: 10),
            GradientButton(
              outlined: true,
              label: pt.t('buy_card'),
              icon: Icons.credit_card_rounded,
              onPressed: _loading ? null : () => _pay('card'),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────── ایمیل برای خرید پلن ویژه ─────────────
  Future<void> _mailDev() async {
    final lang = SettingsScope.read(context).lang;
    final subject = PayT.mailSubject(_target);
    final body = PayT.mailBody(
      planKey: _target,
      shopName: widget.shopName,
      phone: widget.phone,
      username: widget.username,
    );
    final uri = Uri.parse('mailto:$kSupportEmail'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: kSupportEmail));
      if (mounted) toast(context, PayT(lang).t('mail_copied'));
    }
  }

  void _openMove() {
    final st = SettingsScope.read(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlanMovePage(settings: st)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final s = S(lang);
    return GlassScaffold(
      title: s.t('renew_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_canPay) ...[
            _payBox(lang),
            const SizedBox(height: 16),
          ],
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const GradientIcon(Icons.vpn_key_rounded, size: 64),
                const SizedBox(height: 14),
                Text(
                    _canPay
                        ? _x(
                            lang,
                            'کد لایسنس دارید؟ آن را اینجا وارد کنید.',
                            'Already have a license code? Enter it here.',
                            'هل لديك رمز ترخيص؟ أدخله هنا.')
                        : s.t('renew_desc'),
                    style: TextStyle(color: muted(context))),
                const SizedBox(height: 18),
                GlassField(
                  controller: _key,
                  label: _needsLink
                      ? moveMsg(lang, 'code')
                      : s.t('license_key'),
                  icon: Icons.vpn_key_outlined,
                  ltr: true,
                  onSubmitted: _needsLink ? null : (_) => _renew(),
                ),
                if (_needsLink) ...[
                  const SizedBox(height: 12),
                  GlassField(
                    controller: _exec,
                    label: moveMsg(lang, 'exec'),
                    icon: Icons.link_rounded,
                    ltr: true,
                    onSubmitted: (_) => _renew(),
                  ),
                  const SizedBox(height: 6),
                  Text(moveMsg(lang, 'hint'),
                      style: TextStyle(
                          color: muted(context), fontSize: 12.5, height: 1.5)),
                ],
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('renew_btn'),
                  icon: Icons.autorenew_rounded,
                  loading: _loading,
                  onPressed: _renew,
                ),
                if (_target == 'special') ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    outlined: true,
                    icon: Icons.mail_outline_rounded,
                    label: PayT(lang).t('mail_btn'),
                    onPressed: _loading ? null : _mailDev,
                  ),
                ],
                if (widget.plan.isEmpty) ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    label: _changePlanLabel[lang] ?? _changePlanLabel['fa']!,
                    icon: Icons.swap_horiz_rounded,
                    outlined: true,
                    onPressed: _loading ? null : _openMove,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
