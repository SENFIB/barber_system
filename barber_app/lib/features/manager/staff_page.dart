import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/biz_panel.dart';
import '../../app/cal_fmt.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';
import 'shifts_editor.dart';
import 'shop_api.dart';
import 'shop_raw.dart';
import 'shop_settings_page.dart';
import 'staff_edit_page.dart';

class _NewStaff {
  const _NewStaff(this.name, this.role, this.serves);
  final String name;
  final String role;
  final bool serves;
}

class StaffPage extends StatefulWidget {
  const StaffPage(this.ctx, {super.key});

  final ShopCtx ctx;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool _loading = true;
  bool _busy = false;
  String? _err;
  bool _owner = false;
  String _myId = '';
  int _max = 0;
  List<Map<String, dynamic>> _staff = [];
  late BizPanel _panel;

  String get _lang => SettingsScope.read(context).lang;
  ShopRaw get _raw => ShopRaw(SettingsScope.read(context));

  @override
  void initState() {
    super.initState();
    _panel = BizPanel.of(widget.ctx.session.shop.bizType);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _err = null;
      });
    }
    try {
      final raw = _raw;
      final meF = raw.call('me');
      final listF = raw.call('staff_list');
      final me = await meF;
      final d = await listF;
      if (!mounted) return;
      final sh = me['shop'];
      setState(() {
        _owner = jStr(me['role']) == 'owner';
        _myId = jStr(me['staff_id']);
        _staff = jRows(d['staff']);
        _max = jInt(d['max_staff']) ?? 0;
        if (sh is Map && '${sh['biz_type'] ?? ''}'.isNotEmpty) {
          _panel = BizPanel.of('${sh['biz_type']}');
        }
        _loading = false;
        _err = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = T6(_lang).error(e);
      });
    }
  }

  Future<bool> _act(Future<void> Function() fn, [String? okMsg]) async {
    if (_busy) return false;
    setState(() => _busy = true);
    var ok = false;
    try {
      await fn();
      ok = true;
      if (okMsg != null && mounted) toast(context, okMsg);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return false;
      if (_lost(e)) return false;
      toast(context, T6(_lang).error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return ok;
  }

  Future<void> _edit(Map<String, dynamic> r) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StaffEditPage(widget.ctx, r, isOwner: _owner),
      ),
    );
    if (ok == true) _load(silent: true);
  }

  Future<void> _add() async {
    final x = T6(_lang);
    final lang = _lang;
    final nameC = TextEditingController();
    final otherC = TextEditingController();
    final res = await showDialog<_NewStaff>(
      context: context,
      builder: (dc) {
        var pick = 'main';
        return StatefulBuilder(builder: (dc2, setD) {
          void submit() {
            final n = nameC.text.trim();
            if (n.isEmpty) return;
            var role = '';
            var serves = true;
            if (pick.startsWith('s:')) {
              for (final r in kSupportRoles) {
                if ('s:${r.key}' == pick) {
                  role = r.name(lang);
                  serves = false;
                }
              }
            } else if (pick == 'other') {
              role = otherC.text.trim();
            }
            Navigator.pop(dc2, _NewStaff(n, role, serves));
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(_panel.addStaff(lang)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_panel.addHint(lang),
                      style: TextStyle(
                          color: muted(dc2), fontSize: 13, height: 1.6)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameC,
                    autofocus: true,
                    textInputAction: pick == 'other'
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) {
                      if (pick != 'other') submit();
                    },
                    decoration:
                        InputDecoration(labelText: _panel.staffName(lang)),
                  ),
                  const SizedBox(height: 16),
                  Text(_panel.roleLabel(lang),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(_panel.noun(lang)),
                        selected: pick == 'main',
                        onSelected: (_) => setD(() => pick = 'main'),
                      ),
                      for (final r in kSupportRoles)
                        ChoiceChip(
                          label: Text(r.name(lang)),
                          selected: pick == 's:${r.key}',
                          onSelected: (_) =>
                              setD(() => pick = 's:${r.key}'),
                        ),
                      ChoiceChip(
                        label: Text(_panel.roleOther(lang)),
                        selected: pick == 'other',
                        onSelected: (_) => setD(() => pick = 'other'),
                      ),
                    ],
                  ),
                  if (pick == 'other') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherC,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                          labelText: _panel.roleOtherHint(lang)),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dc2),
                  child: Text(x.t('cancel'))),
              TextButton(onPressed: submit, child: Text(x.t('add'))),
            ],
          );
        });
      },
    );
    if (res == null || res.name.isEmpty) return;
    var newId = '';
    final ok = await _act(() async {
      final r = await _raw.call('staff_add', {
        'name': res.name,
        if (res.role.isNotEmpty) 'specialty': res.role,
        'work_start': '09:00',
        'work_end': '18:00',
      });
      newId = jStr(r['staff_id']);
    }, x.t('staff_added'));
    // منشی و نظافتچی نوبت نمی‌گیرند؛ صفحه‌ی ساعت کار برایشان باز نمی‌شود
    if (ok && res.serves && newId.isNotEmpty && mounted) {
      final rows = _staff.where((r) => jStr(r['staff_id']) == newId).toList();
      if (rows.isNotEmpty) await _edit(rows.first);
    }
  }

  Future<void> _remove(Map<String, dynamic> r) async {
    final x = T6(_lang);
    final yes = await confirmDialog(
      context,
      title: x.t('remove'),
      message: '${jStr(r['name'])}\n${x.t('remove_confirm')}',
      okLabel: x.t('remove'),
      cancelLabel: x.t('cancel'),
      danger: true,
    );
    if (!yes) return;
    await _act(() async {
      await _raw.call('staff_remove', {'staff_id': jStr(r['staff_id'])});
    }, x.t('staff_removed'));
  }

  Future<void> _ownerBarber(bool v) async {
    final x = T6(_lang);
    if (!v) {
      final yes = await confirmDialog(
        context,
        title: _panel.stopSelf(_lang),
        message: _panel.stopSelfConfirm(_lang),
        okLabel: x.t('ok'),
        cancelLabel: x.t('cancel'),
        danger: true,
      );
      if (!yes) return;
    }
    final ok = await _act(() async {
      await _raw.call('owner_barber', {
        'is_barber': v,
        'owner_is_barber': v,
        'value': v,
        'enabled': v,
        'enable': v,
        'on': v,
      });
    }, x.t(v ? 'staff_added' : 'staff_removed'));
    if (ok) widget.ctx.reload();
  }

  Future<void> _inviteCreate(Map<String, dynamic> r) async {
    final x = T6(_lang);
    await _act(() async {
      await _raw.call('invite_create', {'staff_id': jStr(r['staff_id'])});
    }, x.t('invite_created'));
  }

  Future<void> _inviteRevoke(Map<String, dynamic> r, String code) async {
    final x = T6(_lang);
    await _act(() async {
      await _raw.call('invite_revoke', {
        'staff_id': jStr(r['staff_id']),
        'invite_code': code,
      });
    }, x.t('invite_revoked'));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopSettingsPage(widget.ctx)),
    );
  }

  Widget _info(IconData icon, String text, {Color? color}) {
    final c = color ?? muted(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: TextStyle(color: c, fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _unsetBanner(T6 x) {
    final unset = _staff
        .where((r) =>
            scheduleUnset(r) && supportRoleOf(jStr(r['specialty'])) == null)
        .toList();
    if (unset.isEmpty) return const SizedBox.shrink();
    final msg = _owner
        ? x.t('sh_unset_owner', {'n': unset.length})
        : x.t('sh_unset_mine');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        tint: Colors.orange.withOpacity(0.18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 13.5, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteBox(Map<String, dynamic> r, Map<String, dynamic>? inv, T6 x) {
    if (inv == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GradientButton(
          label: x.t('invite_create'),
          icon: Icons.vpn_key_rounded,
          compact: true,
          outlined: true,
          onPressed: _busy ? null : () => _inviteCreate(r),
        ),
      );
    }
    final code = jStr(inv['code']);
    final exp = jStr(inv['expires_at']);
    final date = exp.isEmpty
        ? ''
        : CalFmt.date(exp, SettingsScope.read(context).calendarKey, _lang);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lk(context).primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lk(context).primary.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2),
                  ),
                ),
                IconButton(
                  tooltip: x.t('copied'),
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (mounted) toast(context, x.t('copied'));
                  },
                ),
                IconButton(
                  tooltip: x.t('invite_revoke'),
                  icon: Icon(Icons.link_off_rounded,
                      color: lk(context).danger),
                  onPressed: _busy ? null : () => _inviteRevoke(r, code),
                ),
              ],
            ),
            if (date.isNotEmpty)
              Text(localDigits('${x.t('invite_expires')}: $date', _lang),
                  style: TextStyle(color: muted(context), fontSize: 12.5)),
            const SizedBox(height: 4),
            Text(x.t('invite_hint'),
                style: TextStyle(
                    color: muted(context), fontSize: 12.5, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> r, T6 x, String lang) {
    final id = jStr(r['staff_id']);
    final mine = id == _myId;
    final name = jStr(r['name']);
    final spec = jStr(r['specialty']);
    final support = supportRoleOf(spec);
    final hasLogin = jBool(r['has_login']);
    final ot = jInt(r['overtime_min']);
    final cnt = jInt(r['rating_count']) ?? 0;
    final avg =
        r['rating_avg'] is num ? (r['rating_avg'] as num).toDouble() : 0.0;
    final svcN =
        r['service_id_list'] is List ? (r['service_id_list'] as List).length : 0;
    final unset = scheduleUnset(r);
    final off = <int>[];
    if (r['days_off_list'] is List) {
      for (final v in (r['days_off_list'] as List)) {
        final n = jInt(v);
        if (n != null) off.add(n);
      }
    }
    final sep = lang == 'en' ? ', ' : '، ';
    final offText = off.map((d) => x.t('d_$d')).join(sep);
    final inv = r['invite'] is Map
        ? Map<String, dynamic>.from(r['invite'] as Map)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        onTap: () => _edit(r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientIcon(support?.icon ?? _panel.staffIcon, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                          ),
                          if (mine) ...[
                            const SizedBox(width: 8),
                            Pill(x.t('you')),
                          ],
                          if (hasLogin && !mine) ...[
                            const SizedBox(width: 8),
                            Pill(x.t('has_login'), color: Colors.green),
                          ],
                        ],
                      ),
                      if (spec.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(spec,
                              style: TextStyle(
                                  color: muted(context), fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, color: muted(context), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (unset && support == null)
                  _info(Icons.warning_amber_rounded, x.t('sh_not_set'),
                      color: Colors.orange)
                else if (!unset)
                  _info(Icons.schedule_rounded,
                      shiftsText(shiftsOfStaff(r), lang)),
                if (ot != null && ot > 0)
                  _info(Icons.more_time_rounded,
                      x.t('sp_overtime', {'n': ot})),
                if (support == null)
                  _info(
                      _panel.icon,
                      svcN == 0
                          ? x.t('sp_all_services')
                          : x.t('sp_services_n', {'n': svcN})),
                if (off.isNotEmpty)
                  _info(Icons.event_busy_rounded,
                      x.t('sp_days_off', {'d': offText})),
                if (cnt > 0)
                  _info(Icons.star_rounded,
                      localDigits('${avg.toStringAsFixed(1)} ($cnt)', lang)),
              ],
            ),
            if (_owner && !mine && !hasLogin) _inviteBox(r, inv, x),
            if (_owner) ...[
              if (mine)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _busy ? null : () => _ownerBarber(false),
                    child: Text(_panel.stopSelf(lang)),
                  ),
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => _remove(r),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: lk(context).danger, size: 20),
                    label: Text(x.t('remove'),
                        style: TextStyle(color: lk(context).danger)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(T6 x, String lang) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_err!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: GradientButton(
                    label: x.t('retry'),
                    icon: Icons.refresh_rounded,
                    onPressed: _load),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _unsetBanner(x),
          if (_owner) ...[
            if (_max > 0)
              Glass(
                child: Row(
                  children: [
                    const GradientIcon(Icons.groups_rounded, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _panel.capacity(lang, fmtNum(_staff.length, lang),
                            fmtNum(_max, lang)),
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            GradientButton(
              label: _panel.addStaff(lang),
              icon: Icons.person_add_rounded,
              onPressed: _busy ? null : _add,
            ),
            const SizedBox(height: 14),
            if (_myId.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_panel.becomeSelf(lang),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(_panel.becomeSelfDesc(lang),
                          style: TextStyle(
                              color: muted(context), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: _panel.becomeSelf(lang),
                        icon: _panel.staffIcon,
                        compact: true,
                        outlined: true,
                        onPressed: _busy ? null : () => _ownerBarber(true),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (_staff.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(_panel.noStaff(lang),
                    style: TextStyle(color: muted(context))),
              ),
            )
          else
            for (final r in _staff) _card(r, x, lang),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final x = T6(st.lang);
    return GlassScaffold(
      title: (_owner || _loading)
          ? _panel.staffTitle(st.lang)
          : _panel.staffMine(st.lang),
      actions: [
        if (_owner)
          IconButton(
            tooltip: x.t('ss_title'),
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openSettings,
          ),
      ],
      body: _body(x, st.lang),
    );
  }
}
