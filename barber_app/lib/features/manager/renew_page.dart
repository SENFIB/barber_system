import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/config.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/widgets.dart';
import 'activation_code.dart';
import 'plan_move.dart';
import 'server_code.dart';
import 'shop_api.dart';

const Map<String, String> _changePlanLabel = {
  'fa': 'تغییر پلن',
  'en': 'Change plan',
  'ar': 'تغيير الخطة',
};

/// تمدید یا فعال‌سازی با کد لایسنس.
/// [plan]: پلنی که کاربر در صفحه‌ی پلن‌ها انتخاب کرده (خالی = تمدید پلن فعلی)
/// [currentPlan]: پلن فعلی کسب‌وکار
/// برای پلن ویژه/شخصی همیشه دو کادر دارد: کد لایسنس و لینک exec.
/// با موفقیت که تمام شد `true` برمی‌گرداند.
class RenewPage extends StatefulWidget {
  const RenewPage({
    super.key,
    required this.api,
    this.plan = '',
    this.currentPlan = '',
  });
  final ShopApi api;
  final String plan;
  final String currentPlan;

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage> {
  final _key = TextEditingController();
  final _exec = TextEditingController();
  bool _loading = false;

  String get _target =>
      widget.plan.isEmpty ? widget.currentPlan : widget.plan;
  bool get _isMove =>
      widget.plan.isNotEmpty && widget.plan != widget.currentPlan;
  bool get _needsLink => _target == 'special' || _target == 'personal';

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
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const GradientIcon(Icons.vpn_key_rounded, size: 64),
                const SizedBox(height: 14),
                Text(s.t('renew_desc'),
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
