import 'package:flutter/material.dart';
import '../../app/biz_panel.dart';
import '../../app/biz_words.dart';
import '../../app/fmt.dart';
import '../../app/plans_config.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'shifts_editor.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

/// ویرایش یک نفر از پرسنل: نام، نقش، خدمات، شیفت‌ها، روز تعطیل، اضافه‌کار
class StaffEditPage extends StatefulWidget {
  const StaffEditPage(this.ctx, this.staff, {super.key, required this.isOwner});

  final ShopCtx ctx;
  final Map<String, dynamic> staff;
  final bool isOwner;

  @override
  State<StaffEditPage> createState() => _StaffEditPageState();
}

class _StaffEditPageState extends State<StaffEditPage> {
  final _name = TextEditingController();
  final _spec = TextEditingController();
  final _ot = TextEditingController();
  List<Shift> _shifts = [];
  bool _unset = false;
  final Set<int> _off = {};
  final Set<String> _svc = {};
  bool _all = true;
  bool _otDefault = true;
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _err;
  bool _busy = false;
  String _type = '';

  String get _lang => SettingsScope.read(context).lang;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _type = '${widget.ctx.session.shop.bizType}';
    _name.text = jStr(s['name']);
    _spec.text = jStr(s['specialty']);
    _shifts = shiftsOfStaff(s);
    _unset = scheduleUnset(s);
    // روزهای تعطیل
    if (s['days_off_list'] is List) {
      for (final v in (s['days_off_list'] as List)) {
        final n = jInt(v);
        if (n != null && n >= 0 && n <= 6) _off.add(n);
      }
    } else {
      for (final p in jStr(s['days_off']).split(RegExp(r'[|,]'))) {
        final n = int.tryParse(p.trim());
        if (n != null && n >= 0 && n <= 6) _off.add(n);
      }
    }
    // خدمات
    if (s['service_id_list'] is List) {
      for (final v in (s['service_id_list'] as List)) {
        final id = jStr(v).trim();
        if (id.isNotEmpty) _svc.add(id);
      }
    } else {
      for (final p in jStr(s['service_ids']).split(',')) {
        if (p.trim().isNotEmpty) _svc.add(p.trim());
      }
    }
    _all = _svc.isEmpty;
    // اضافه‌کار
    final ot = jInt(s['overtime_min']);
    _otDefault = ot == null;
    _ot.text = ot == null ? '' : '$ot';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadType();
      _loadServices();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _spec.dispose();
    _ot.dispose();
    super.dispose();
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  /// نوع کسب‌وکار برای متن‌ها و آیکون (اگر نشد، همان مقدار نشست)
  Future<void> _loadType() async {
    try {
      final me = await ShopRaw(SettingsScope.read(context)).call('me');
      final sh = me['shop'];
      if (sh is Map) {
        final b = jStr(sh['biz_type']).trim();
        if (b.isNotEmpty && mounted) setState(() => _type = b);
      }
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await ShopRaw(SettingsScope.read(context)).call('service_list');
      dynamic list = d['services'] ?? d['items'] ?? d['list'];
      if (list == null) {
        for (final v in d.values) {
          if (v is List) {
            list = v;
            break;
          }
        }
      }
      final rows = jRows(list)
          .where((r) => r['active'] == null || jBool(r['active']))
          .toList();
      if (!mounted) return;
      setState(() {
        _services = rows;
        _loading = false;
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

  Future<void> _save() async {
    final x = T6(_lang);
    final name = _name.text.trim();
    if (name.isEmpty) {
      toast(context, x.t('v_required'));
      return;
    }
    final bad = validateShifts(_shifts);
    if (bad != null) {
      toast(context, x.t(bad));
      return;
    }
    var ids = <String>[];
    if (!_all) {
      ids = [
        for (final r in _services)
          if (_svc.contains(jStr(r['service_id']))) jStr(r['service_id']),
      ];
      if (ids.isEmpty) {
        toast(context, x.t('ed_pick_at_least'));
        return;
      }
    }
    final days = _off.toList()..sort();
    final params = <String, dynamic>{
      'staff_id': jStr(widget.staff['staff_id']),
      'name': name,
      'specialty': _spec.text.trim(),
      'service_ids': ids.join(','),
      // شروع و پایانِ کل روز (برای سرورهای قدیمی) + خودِ شیفت‌ها
      'work_start': _shifts.first.start,
      'work_end': _shifts.last.end,
      'shifts': shiftsToString(_shifts),
      'days_off': days.join('|'),
    };
    if (widget.isOwner) {
      if (_otDefault) {
        params['clear_overtime'] = true;
      } else {
        final n = int.tryParse(normalizeDigits(_ot.text).trim());
        if (n == null || n < 0 || n > 240) {
          toast(context, x.t('ed_bad_number'));
          return;
        }
        params['overtime_min'] = n;
      }
    }
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call('staff_update', params);
      if (!mounted) return;
      toast(context, x.t('ed_saved'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      toast(context, x.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _unsetBox(T6 x) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(x.t('sh_unset_title'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(x.t('sh_unset_msg'),
                      style: TextStyle(
                          color: muted(context), fontSize: 13, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChips(BizPanel panel, String lang) {
    final cur = supportRoleOf(_spec.text);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(panel.noun(lang)),
          selected: cur == null,
          onSelected: (_) => setState(() {
            if (cur != null) _spec.text = '';
          }),
        ),
        for (final r in kSupportRoles)
          ChoiceChip(
            label: Text(r.name(lang)),
            selected: cur?.key == r.key,
            onSelected: (_) => setState(() => _spec.text = r.name(lang)),
          ),
      ],
    );
  }

  Widget _servicesBox(T6 x) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _all,
            onChanged: (v) => setState(() => _all = v),
            title: Text(x.t('ed_all_services')),
            subtitle: Text(x.t('ed_all_services_hint')),
          ),
          if (!_all) ...[
            const SizedBox(height: 6),
            Text(x.t('ed_pick_services'),
                style: TextStyle(color: muted(context), fontSize: 12.5)),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ))
            else if (_err != null) ...[
              Text(_err!, style: TextStyle(color: lk(context).danger)),
              const SizedBox(height: 10),
              GradientButton(
                  label: x.t('retry'),
                  icon: Icons.refresh_rounded,
                  compact: true,
                  onPressed: _loadServices),
            ] else if (_services.isEmpty)
              Text(x.t('ed_no_services'),
                  style: TextStyle(color: muted(context), height: 1.6))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _services)
                    FilterChip(
                      label: Text(localDigits(
                          '${jStr(r['name'])} · ${jStr(r['duration_min'])} ${x.t('unit_min')}',
                          _lang)),
                      selected: _svc.contains(jStr(r['service_id'])),
                      onSelected: (v) => setState(() {
                        final id = jStr(r['service_id']);
                        if (v) {
                          _svc.add(id);
                        } else {
                          _svc.remove(id);
                        }
                      }),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final x = T6(st.lang);
    final lang = st.lang;
    final panel = BizPanel.of(_type);
    final support = supportRoleOf(_spec.text);
    final staffWord = support?.name(lang) ?? bwStaff(_type, lang);
    final days = st.lang == 'en'
        ? const [0, 1, 2, 3, 4, 5, 6]
        : const [6, 0, 1, 2, 3, 4, 5];
    final cap = shiftCapForPlan(widget.ctx.session.shop.plan);
    return GlassScaffold(
      title: '${_x(lang, 'ویرایش', 'Edit', 'تعديل')} $staffWord',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (_unset && support == null) _unsetBox(x),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassField(
                  controller: _name,
                  label: _x(lang, 'نام $staffWord', '$staffWord name',
                      'اسم $staffWord'),
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _spec,
                  label: _x(lang, 'نقش / شرح کار (اختیاری)',
                      'Role / description (optional)',
                      'الدور / الوصف (اختياري)'),
                  icon: support?.icon ?? panel.staffIcon,
                ),
                const SizedBox(height: 12),
                _roleChips(panel, lang),
              ],
            ),
          ),
          if (support == null) ...[
            SectionLabel(x.t('ed_services')),
            _servicesBox(x),
          ],
          SectionLabel(x.t('sh_title')),
          ShiftsEditor(
            shifts: _shifts,
            max: cap,
            onChanged: (v) => setState(() => _shifts = v),
          ),
          SectionLabel(x.t('ed_days_off')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(x.t('ed_days_off_hint'),
                    style: TextStyle(
                        color: muted(context), fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in days)
                      FilterChip(
                        label: Text(x.t('d_$d')),
                        selected: _off.contains(d),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _off.add(d);
                          } else {
                            _off.remove(d);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.isOwner) ...[
            SectionLabel(x.t('ed_overtime')),
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _otDefault,
                    onChanged: (v) => setState(() => _otDefault = v),
                    title: Text(x.t('ed_overtime_default')),
                    subtitle: Text(x.t('ed_overtime_hint')),
                  ),
                  if (!_otDefault) ...[
                    const SizedBox(height: 8),
                    GlassField(
                      controller: _ot,
                      label: '${x.t('ed_overtime')} (${x.t('unit_min')})',
                      icon: Icons.more_time_rounded,
                      keyboard: TextInputType.number,
                      ltr: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in const [0, 5, 10, 15, 20, 30])
                          ChoiceChip(
                            label: Text(localDigits('$v', st.lang)),
                            selected: _ot.text.trim() == '$v',
                            onSelected: (_) => setState(() => _ot.text = '$v'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: x.t('save'),
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
