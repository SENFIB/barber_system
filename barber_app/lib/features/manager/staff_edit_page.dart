import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings_s2.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

/// ویرایش یک آرایشگر: نام، تخصص، خدمات، ساعت، روز تعطیل، اضافه‌کار
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

  String _start = '09:00';
  String _end = '18:00';
  final Set<int> _off = {};
  final Set<String> _svc = {};
  bool _all = true;
  bool _otDefault = true;

  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  String? _err;
  bool _busy = false;

  String get _lang => SettingsScope.read(context).lang;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _name.text = jStr(s['name']);
    _spec.text = jStr(s['specialty']);
    _start = _normTime(s['work_start'], '09:00');
    _end = _normTime(s['work_end'], '18:00');

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  @override
  void dispose() {
    _name.dispose();
    _spec.dispose();
    _ot.dispose();
    super.dispose();
  }

  String _normTime(dynamic v, String d) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(jStr(v));
    if (m == null) return d;
    return '${m[1]!.padLeft(2, '0')}:${m[2]}';
  }

  int _toMin(String t) {
    final p = t.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
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
        _err = T2(_lang).error(e);
      });
    }
  }

  Future<void> _pickTime(bool start) async {
    final cur = _toMin(start ? _start : _end);
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (r == null) return;
    final v =
        '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _start = v;
      } else {
        _end = v;
      }
    });
  }

  Future<void> _save() async {
    final x = T2(_lang);
    final name = _name.text.trim();
    if (name.isEmpty) {
      toast(context, x.t('v_required'));
      return;
    }
    if (_toMin(_start) >= _toMin(_end)) {
      toast(context, x.t('err_BAD_TIME'));
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
      'work_start': _start,
      'work_end': _end,
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

  Widget _timeCard(String label, String value, bool start) {
    return Glass(
      onTap: () => _pickTime(start),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(label,
                style: TextStyle(color: muted(context), fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(value,
                textDirection: TextDirection.ltr,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _servicesBox(T2 x) {
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
                      label: Text(
                          '${jStr(r['name'])} · ${jStr(r['duration_min'])} ${x.t('unit_min')}'),
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
    final x = T2(st.lang);
    final days = st.lang == 'en'
        ? const [0, 1, 2, 3, 4, 5, 6]
        : const [6, 0, 1, 2, 3, 4, 5];

    return GlassScaffold(
      title: x.t('ed_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Glass(
            child: Column(
              children: [
                GlassField(
                  controller: _name,
                  label: x.t('barber_name'),
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _spec,
                  label: x.t('ed_specialty'),
                  icon: Icons.content_cut_rounded,
                ),
              ],
            ),
          ),

          SectionLabel(x.t('ed_services')),
          _servicesBox(x),

          SectionLabel(x.t('ed_hours')),
          Row(
            children: [
              Expanded(child: _timeCard(x.t('work_start'), _start, true)),
              const SizedBox(width: 12),
              Expanded(child: _timeCard(x.t('work_end'), _end, false)),
            ],
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
                            label: Text('$v'),
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
