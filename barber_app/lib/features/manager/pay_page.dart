import 'dart:async';
import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/currency.dart';
import '../../app/plans_config.dart';
import '../../app/settings.dart';
import '../../app/strings_pay.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'pay_api.dart';
import 'plan_move.dart';
import 'shop_api.dart';

/// صفحه‌ی پرداخت با تتر. با فعال‌سازی موفق `true` برمی‌گرداند.
class PayPage extends StatefulWidget {
  const PayPage({
    super.key,
    required this.ctx,
    required this.plan,
    required this.months,
  });
  final ShopCtx ctx;
  final PlanDef plan;
  final int months;

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  final _tx = TextEditingController();
  late final PayApi _api = PayApi(widget.ctx.api.settings);
  PayOrder? _order;
  PayResult? _paid;
  String? _fatal;
  bool _loading = true;
  bool _busy = false;
  String _reviewId = '';
  Timer? _timer;
  DateTime _deadline = DateTime.now();
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tx.dispose();
    super.dispose();
  }

  String get _lang => widget.ctx.api.settings.lang;

  void _startTimer(int secs) {
    _timer?.cancel();
    _deadline = DateTime.now().add(Duration(seconds: secs));
    _left = secs;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final l = _deadline.difference(DateTime.now()).inSeconds;
      setState(() => _left = l < 0 ? 0 : l);
    });
  }

  String _clock(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _copy(String v) {
    Clipboard.setData(ClipboardData(text: v));
    toast(context, PayT(_lang).t('copied'));
  }

  Future<void> _create() async {
    try {
      final o = await _api.create(widget.plan.key, widget.months);
      if (!mounted) return;
      _order = o;
      _fatal = null;
      _startTimer(o.secondsLeft);
    } on ApiException catch (e) {
      _fatal = e.code;
    } catch (_) {
      _fatal = 'NETWORK';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _newOrder() {
    setState(() {
      _loading = true;
      _fatal = null;
      _order = null;
      _reviewId = '';
      _tx.clear();
    });
    _create();
  }

  Future<void> _submit() async {
    final o = _order;
    if (_busy || o == null) return;
    final t = PayT(_lang);
    final txid = _tx.text.trim();
    if (txid.isEmpty) {
      toast(context, t.t('need_txid'));
      return;
    }
    setState(() => _busy = true);
    PayResult? res;
    try {
      res = await _api.submit(widget.plan.key, o.payId, txid);
    } on ApiException catch (e) {
      if (mounted) toast(context, t.error(e));
    } catch (_) {
      if (mounted) toast(context, t.t('err_NETWORK'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (res != null && mounted) await _handle(res, t);
  }

  Future<void> _status() async {
    final o = _order;
    if (_busy || o == null) return;
    final t = PayT(_lang);
    setState(() => _busy = true);
    PayResult? res;
    try {
      res = await _api.status(widget.plan.key, o.payId);
    } on ApiException catch (e) {
      if (mounted) toast(context, t.error(e));
    } catch (_) {
      if (mounted) toast(context, t.t('err_NETWORK'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (res != null && mounted) await _handle(res, t);
  }

  Future<void> _handle(PayResult r, PayT t) async {
    if (r.isPaid) {
      setState(() => _paid = r);
      await _activate();
    } else if (r.status == 'review') {
      setState(() => _reviewId = r.payId);
    } else {
      toast(context, t.t('still_pending'));
    }
  }

  /// لایسنس صادرشده را با همان مسیر «کد لایسنس دارم» فعال می‌کند
  Future<void> _activate() async {
    final r = _paid;
    if (r == null || r.licenseKey.isEmpty || _busy) return;
    final st = widget.ctx.api.settings;
    final lang = st.lang;
    final t = PayT(lang);
    final plan = widget.plan.key;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      if (plan == widget.ctx.session.shop.plan) {
        await widget.ctx.api.renew(r.licenseKey);
        messenger.showSnackBar(SnackBar(content: Text(t.t('activated'))));
        if (mounted) nav.pop(true);
        return;
      }
      final res = await PlanMover.move(
        st: st,
        targetUrl: _api.urlForPlan(plan),
        license: r.licenseKey,
        plan: plan,
      );
      var msg = moveMsg(lang, 'done');
      if (res.trimmedStaff > 0 || res.trimmedShifts > 0) {
        msg +=
            '\n${moveMsg(lang, 'trim').replaceAll('{a}', '${res.trimmedStaff}').replaceAll('{b}', '${res.trimmedShifts}')}';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      await restartAfterMove(st, nav);
      return;
    } on MoveError catch (e) {
      if (mounted) toast(context, moveMsg(lang, e.code));
    } on ApiException catch (e) {
      if (mounted) toast(context, t.error(e));
    } catch (_) {
      if (mounted) toast(context, moveMsg(lang, 'other'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _card(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );

  Widget _copyRow(String label, String value, {bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: muted(context), fontSize: 12.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  value,
                  style: TextStyle(
                      fontSize: big ? 26 : 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copy(value),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final t = PayT(lang);
    final t6 = T6(lang);
    final o = _order;
    return GlassScaffold(
      title: t.t('title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_fatal != null)
            _card([
              Text(t.errorCode(_fatal!), style: const TextStyle(height: 1.6)),
              const SizedBox(height: 14),
              GradientButton(
                label: t.t('retry'),
                icon: Icons.refresh_rounded,
                onPressed: _newOrder,
              ),
            ])
          else if (_paid != null)
            _card([
              const Center(
                  child: GradientIcon(Icons.check_circle_rounded, size: 56)),
              const SizedBox(height: 12),
              Center(
                child: Text(t.t('paid_ok'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Text(t.t('paid_keep'),
                  style: TextStyle(color: muted(context), height: 1.5)),
              const SizedBox(height: 14),
              _copyRow(t.t('paid_license'), _paid!.licenseKey),
              const SizedBox(height: 10),
              GradientButton(
                label: t.t('activate_btn'),
                icon: Icons.bolt_rounded,
                loading: _busy,
                onPressed: _activate,
              ),
            ])
          else if (o != null)
            ..._orderWidgets(t, t6, o, lang),
        ],
      ),
    );
  }

  List<Widget> _orderWidgets(PayT t, T6 t6, PayOrder o, String lang) {
    final expired = _left <= 0;
    return [
      if (_reviewId.isNotEmpty)
        _card([
          Text(t.t('review', {'id': _reviewId}),
              style: const TextStyle(height: 1.6)),
        ]),
      _card([
        Text(
          '${t6.t('pl_name_${widget.plan.key}')} · ${t6.t('pl_months', {'n': widget.months})}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(t.t('send_exact'), style: TextStyle(color: muted(context))),
        const SizedBox(height: 14),
        _copyRow(t.t('amount'), o.amountText, big: true),
        const Divider(height: 24),
        _copyRow(t.t('address'), o.address),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('${t.t('network')}: ',
                style: TextStyle(color: muted(context))),
            Pill(t.t('net_name'), color: AppColors.green),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          expired
              ? t.t('expired_note')
              : t.t('time_left', {'m': lDigits(_clock(_left), lang)}),
          style: TextStyle(
              color: expired ? Colors.orangeAccent : muted(context),
              height: 1.5),
        ),
        const SizedBox(height: 10),
        Text('• ${t.t('warn_net')}',
            style: const TextStyle(
                color: Colors.orangeAccent, fontSize: 13, height: 1.6)),
        const SizedBox(height: 4),
        Text('• ${t.t('warn_amount')}',
            style: TextStyle(color: muted(context), fontSize: 13, height: 1.6)),
        const SizedBox(height: 10),
        Text('${t.t('order_id')}: ${o.payId}',
            style: TextStyle(color: muted(context), fontSize: 12)),
      ]),
      _card([
        GlassField(
          controller: _tx,
          label: t.t('txid_label'),
          icon: Icons.tag_rounded,
          ltr: true,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 6),
        Text(t.t('txid_hint'),
            style: TextStyle(color: muted(context), fontSize: 12.5, height: 1.5)),
        const SizedBox(height: 14),
        GradientButton(
          label: t.t('check_btn'),
          icon: Icons.verified_rounded,
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _busy ? null : _status,
              child: Text(t.t('status_btn')),
            ),
            if (expired)
              TextButton(
                onPressed: _busy ? null : _newOrder,
                child: Text(t.t('new_order')),
              ),
          ],
        ),
      ]),
    ];
  }
}
