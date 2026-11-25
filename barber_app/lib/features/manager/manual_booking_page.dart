import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/biz_words.dart' show bwRole;
import '../../app/date_pick.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

class ManualBookingPage extends StatefulWidget {
  const ManualBookingPage(this.ctx, {super.key, this.initialDate});
  final ShopCtx ctx;
  final String? initialDate;

  @override
  State<ManualBookingPage> createState() => _ManualBookingPageState();
}

class _ManualBookingPageState extends State<ManualBookingPage> {
  bool _loading = true;
  bool _busy = false;
  bool _slotsBusy = false;
  Object? _err;
  String _shopId = '';
  List<Map<String, dynamic>> _services = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _staff = <Map<String, dynamic>>[];
  int _maxServices = 3;
  int _maxAdvance = 30;
  final List<String> _picked = <String>[];
  final Map<String, String> _choice = <String, String>{};
  late DateTime _day;
  List<Map<String, dynamic>>? _slots;
  int _slotIdx = -1;
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool get _owner => widget.ctx.session.isOwner;
  String get _myStaff => bStr(widget.ctx.session.staffId);
  T6 _tr() => T6(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    var d = bParse(widget.initialDate ?? '') ?? today;
    if (d.isBefore(today)) d = today;
    _day = d;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      if (mounted) Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final raw = ShopRaw(SettingsScope.read(context));
      final me = await raw.call('me');
      final shop = me['shop'];
      final sid = shop is Map ? bStr(shop['shop_id']) : '';
      final r = await raw.call('shop_detail', <String, dynamic>{'shop_id': sid});
      if (!mounted) return;
      setState(() {
        _shopId = sid;
        _services = bRows(r['services']);
        _staff = bRows(r['staff']);
        final ms = bInt(r['max_services'], 3);
        _maxServices = ms < 1 ? 1 : ms;
        final ma = bInt(r['max_advance_days'], 30);
        _maxAdvance = ma < 1 ? 30 : ma;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }

  List<Map<String, dynamic>> _eligible(String sid) {
    return _staff.where((s) {
      final ids = bIds(s['service_ids']);
      return ids.isEmpty || ids.contains(sid);
    }).toList();
  }

  List<Map<String, dynamic>> _visibleServices() {
    if (_owner) return _services;
    final mine = _staff.where((s) => bStr(s['staff_id']) == _myStaff).toList();
    if (mine.isEmpty) return <Map<String, dynamic>>[];
    final ids = bIds(mine.first['service_ids']);
    return _services.where((s) {
      return ids.isEmpty || ids.contains(bStr(s['service_id']));
    }).toList();
  }

  void _resetSlots() {
    _slots = null;
    _slotIdx = -1;
  }

  void _toggle(String id) {
    final lang = SettingsScope.read(context).lang;
    if (_picked.contains(id)) {
      setState(() {
        _picked.remove(id);
        _choice.remove(id);
        _resetSlots();
      });
      return;
    }
    if (_owner && _picked.length >= _maxServices) {
      bSnack(context, _tr().t('m_max', {'n': fmtNum(_maxServices, lang)}));
      return;
    }
    setState(() {
      if (!_owner) {
        _picked.clear();
        _choice.clear();
      }
      _picked.add(id);
      _resetSlots();
    });
  }

  Future<void> _pickDate() async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final s = SettingsScope.read(context);
    final d = await pickLocalDate(
      context,
      initial: _day,
      first: today,
      last: today.add(Duration(days: _maxAdvance + 1)),
      calKey: s.calendarKey,
      lang: s.lang,
    );
    if (d == null || !mounted) return;
    setState(() {
      _day = d;
      _resetSlots();
    });
  }

  Future<void> _loadSlots() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('m_pick_service'));
      return;
    }
    setState(() {
      _slotsBusy = true;
      _slotIdx = -1;
    });
    try {
      final choice = <String, String>{};
      for (final sid in _picked) {
        final c = _owner ? (_choice[sid] ?? '') : _myStaff;
        if (c.isNotEmpty) choice[sid] = c;
      }
      final r = await ShopRaw(SettingsScope.read(context)).call(
        'slots',
        <String, dynamic>{
          'shop_id': _shopId,
          'date': bIso(_day),
          'service_ids': List<String>.from(_picked),
          'staff_choice': choice,
        },
      );
      if (!mounted) return;
      setState(() => _slots = bFirstList(r, ['slots']));
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      bSnack(context, t.error(e));
    } finally {
      if (mounted) setState(() => _slotsBusy = false);
    }
  }

  Future<void> _save() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('m_pick_service'));
      return;
    }
    final slots = _slots;
    if (slots == null || _slotIdx < 0 || _slotIdx >= slots.length) {
      bSnack(context, t.t('m_pick_slot'));
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      bSnack(context, t.t('m_need_name'));
      return;
    }
    final slot = slots[_slotIdx];
    final items = bRows(slot['assign'])
        .map((a) => <String, dynamic>{
              'service_id': bStr(a['service_id']),
              'staff_id': bStr(a['staff_id']),
            })
        .toList();
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call(
        'booking_manual',
        <String, dynamic>{
          'items': items,
          'date': bIso(_day),
          'start_time': bStr(slot['start']),
          'customer_name': name,
          'customer_phone': bDigits(_phone.text),
        },
      );
      if (!mounted) return;
      bSnack(context, t.t('m_ok'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      bSnack(context, t.error(e));
      if (e is ApiException && e.code == 'SLOT_TAKEN') {
        _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
      );

  String _chooseRole(String lang) {
    final type = '${widget.ctx.session.shop.bizType}';
    final r = bwRole(type);
    final i = lang == 'fa' ? 0 : (lang == 'ar' ? 2 : 1);
    final w = '${r[i]}';
    if (lang == 'fa') return 'انتخاب $w';
    if (lang == 'ar') return 'اختيار $w';
    return 'Choose $w';
  }

  @override
  Widget build(BuildContext context) {
    final t = T6(SettingsScope.of(context).lang);
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Glass(
            child: Column(
              children: [
                Text(t.error(_err!), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GradientButton(
                  compact: true,
                  icon: Icons.refresh_rounded,
                  label: t.t('c_retry'),
                  onPressed: () {
                    _load();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = _form(t);
    }
    return GlassScaffold(
      title: t.t('m_title'),
      maxWidth: 600,
      body: body,
    );
  }

  Widget _form(T6 t) {
    final st = SettingsScope.of(context);
    final services = _visibleServices();
    final slots = _slots;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _label(t.t('m_services')),
        if (services.isEmpty)
          Glass(
            child: Text(t.t('m_no_services'),
                style: TextStyle(color: muted(context))),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in services)
                FilterChip(
                  label: Text(
                      '${bStr(s['name'])} · ${fmtNum(bInt(s['duration_min']), t.lang)} ${t.t('b_min')}'),
                  selected: _picked.contains(bStr(s['service_id'])),
                  onSelected: (_) => _toggle(bStr(s['service_id'])),
                ),
            ],
          ),
          if (_owner)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(t.t('m_max', {'n': fmtNum(_maxServices, t.lang)}),
                  style: TextStyle(color: muted(context), fontSize: 12)),
            ),
        ],
        if (_owner && _picked.isNotEmpty) ...[
          _label(_chooseRole(t.lang)),
          for (final sid in _picked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _choiceRow(sid, t),
            ),
        ],
        _label(t.t('m_date')),
        Glass(
          onTap: _pickDate,
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded),
              const SizedBox(width: 10),
              Text(t.t('d_${_day.weekday % 7}'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Text(fmtPickDate(_day, st.calendarKey, st.lang),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GradientButton(
          outlined: true,
          loading: _slotsBusy,
          icon: Icons.schedule_rounded,
          label: t.t('m_show_slots'),
          onPressed: () {
            if (!_slotsBusy) _loadSlots();
          },
        ),
        if (slots != null) ...[
          _label(t.t('m_slots')),
          if (slots.isEmpty)
            Glass(
              child: Text(t.t('m_no_slots'),
                  style: TextStyle(color: muted(context))),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < slots.length; i++)
                  ChoiceChip(
                    label: Text(localDigits(bStr(slots[i]['start']), t.lang),
                        textDirection: TextDirection.ltr),
                    selected: i == _slotIdx,
                    onSelected: (_) => setState(() => _slotIdx = i),
                  ),
              ],
            ),
        ],
        const SizedBox(height: 18),
        GlassField(
          controller: _name,
          label: t.t('m_name'),
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 12),
        GlassField(
          controller: _phone,
          label: t.t('m_phone'),
          icon: Icons.phone_rounded,
          keyboard: TextInputType.phone,
          ltr: true,
        ),
        const SizedBox(height: 22),
        GradientButton(
          loading: _busy,
          icon: Icons.check_rounded,
          label: t.t('m_save'),
          onPressed: () {
            if (!_busy) _save();
          },
        ),
      ],
    );
  }

  Widget _choiceRow(String sid, T6 t) {
    final svc = _services.firstWhere(
      (s) => bStr(s['service_id']) == sid,
      orElse: () => <String, dynamic>{},
    );
    final el = _eligible(sid);
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bStr(svc['name']),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (el.isEmpty)
            Text(t.t('m_staff_none'),
                style: TextStyle(color: lk(context).danger))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.t('m_any')),
                  selected: (_choice[sid] ?? '').isEmpty,
                  onSelected: (_) => setState(() {
                    _choice[sid] = '';
                    _resetSlots();
                  }),
                ),
                for (final s in el)
                  ChoiceChip(
                    label: Text(bStr(s['name'])),
                    selected: _choice[sid] == bStr(s['staff_id']),
                    onSelected: (_) => setState(() {
                      _choice[sid] = bStr(s['staff_id']);
                      _resetSlots();
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
