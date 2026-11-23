import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s4.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../manager/booking_common.dart';
import 'customer_api.dart';
import 'customer_store.dart';

class ShopPhoto extends StatelessWidget {
  const ShopPhoto({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 14,
  });
  final String url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget ph() => Container(
          width: width,
          height: height,
          color: lk(context).primary.withOpacity(0.12),
          child: const Center(
              child: GradientIcon(Icons.storefront_rounded, size: 40)),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.trim().isEmpty
          ? ph()
          : Image.network(
              url.trim(),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ph(),
              loadingBuilder: (c, child, p) => p == null ? child : ph(),
            ),
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.api, required this.card});
  final CustomerApi api;
  final Map<String, dynamic> card;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _loading = true;
  bool _busy = false;
  bool _slotsBusy = false;
  Object? _err;
  late Map<String, dynamic> _shop;
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

  String get _shopId => bStr(widget.card['shop_id']);
  T4 _tr() => T4(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    _shop = Map<String, dynamic>.from(widget.card);
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.api.shopDetail(_shopId);
      final saved = await CustomerStore.load();
      if (!mounted) return;
      final sh = r['shop'];
      setState(() {
        if (sh is Map) {
          _shop = <String, dynamic>{..._shop, ...Map<String, dynamic>.from(sh)};
        }
        _services = bRows(r['services']);
        _staff = bRows(r['staff']);
        final ms = bInt(r['max_services'], 3);
        _maxServices = ms < 1 ? 1 : ms;
        final ma = bInt(r['max_advance_days'], 30);
        _maxAdvance = ma < 1 ? 30 : (ma > 60 ? 60 : ma);
        if (_name.text.isEmpty) _name.text = saved.name;
        if (_phone.text.isEmpty) _phone.text = saved.phone;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  Map<String, dynamic> _svc(String id) => _services.firstWhere(
        (s) => bStr(s['service_id']) == id,
        orElse: () => <String, dynamic>{},
      );

  String _staffName(String id) {
    for (final s in _staff) {
      if (bStr(s['staff_id']) == id) return bStr(s['name']);
    }
    return id;
  }

  void _resetSlots() {
    _slots = null;
    _slotIdx = -1;
  }

  void _toggle(String id) {
    if (_picked.contains(id)) {
      setState(() {
        _picked.remove(id);
        _choice.remove(id);
        _resetSlots();
      });
      return;
    }
    if (_picked.length >= _maxServices) {
      bSnack(context, _tr().t('m_max', {'n': fmtNum(_maxServices)}));
      return;
    }
    setState(() {
      _picked.add(id);
      _resetSlots();
    });
  }

  void _setDay(DateTime d) {
    setState(() {
      _day = d;
      _resetSlots();
    });
    if (_picked.isNotEmpty) _loadSlots();
  }

  Future<void> _loadSlots() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('cu_pick'));
      return;
    }
    setState(() {
      _slotsBusy = true;
      _slotIdx = -1;
    });
    try {
      final choice = <String, String>{};
      for (final sid in _picked) {
        final c = _choice[sid] ?? '';
        if (c.isNotEmpty) choice[sid] = c;
      }
      final r = await widget.api.slots(
        shopId: _shopId,
        date: bIso(_day),
        serviceIds: List<String>.from(_picked),
        staffChoice: choice,
      );
      if (!mounted) return;
      setState(() => _slots = bFirstList(r, ['slots']));
    } catch (e) {
      if (!mounted) return;
      bSnack(context, t.error(e));
    } finally {
      if (mounted) setState(() => _slotsBusy = false);
    }
  }

  Future<void> _book() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('cu_pick'));
      return;
    }
    final slots = _slots;
    if (slots == null || _slotIdx < 0 || _slotIdx >= slots.length) {
      bSnack(context, t.t('m_pick_slot'));
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      bSnack(context, t.t('cu_need_name'));
      return;
    }
    final phone = bDigits(_phone.text);
    if (phone.isEmpty) {
      bSnack(context, t.t('cu_need_phone'));
      return;
    }
    final slot = slots[_slotIdx];
    final choice = <String, String>{};
    for (final a in bRows(slot['assign'])) {
      choice[bStr(a['service_id'])] = bStr(a['staff_id']);
    }
    setState(() => _busy = true);
    try {
      await widget.api.book(
        shopId: _shopId,
        name: name,
        phone: phone,
        date: bIso(_day),
        startTime: bStr(slot['start']),
        serviceIds: List<String>.from(_picked),
        staffChoice: choice,
      );
      await CustomerStore.save(name, phone);
      if (!mounted) return;
      bSnack(context, t.t('cu_booked_ok'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      bSnack(context, t.error(e));
      if (e is ApiException && e.code == 'SLOT_TAKEN') {
        _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _policy(T4 t) {
    final m = bInt(_shop['cancel_before_min'], 120);
    final txt = (m >= 60 && m % 60 == 0)
        ? t.t('cu_h', {'n': fmtNum(m ~/ 60)})
        : t.t('cu_m', {'n': fmtNum(m)});
    return t.t('cu_policy', {'t': txt});
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final t = T4(SettingsScope.of(context).lang);
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
      body = _content(t);
    }
    return GlassScaffold(
      title: bStr(_shop['name']),
      maxWidth: 720,
      body: body,
    );
  }

  Widget _header(T4 t) {
    final avg = cDouble(_shop['rating_avg']);
    final count = bInt(_shop['rating_count']);
    final phone = bStr(_shop['phone']);
    final address = [bStr(_shop['city']), bStr(_shop['address'])]
        .where((e) => e.isNotEmpty)
        .join('، ');
    final desc = bStr(_shop['description']);
    return Glass(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bStr(_shop['photo_url']).isNotEmpty)
            ShopPhoto(
              url: bStr(_shop['photo_url']),
              width: double.infinity,
              height: 180,
              radius: 20,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(bStr(_shop['name']),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    if (count > 0) ...[
                      const Icon(Icons.star_rounded,
                          size: 20, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Text('(${fmtNum(count)})',
                          style: TextStyle(color: muted(context))),
                    ] else
                      Pill(t.t('cu_new')),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_rounded,
                          size: 18, color: muted(context)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(address)),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      bSnack(context, t.t('b_copied'));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 18, color: muted(context)),
                          const SizedBox(width: 6),
                          Text(phone, textDirection: TextDirection.ltr),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded,
                              size: 14, color: muted(context)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(desc, style: TextStyle(color: muted(context))),
                ],
                const SizedBox(height: 10),
                Text(_policy(t),
                    style: TextStyle(color: muted(context), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(T4 t) {
    final cur = bStr(_shop['currency']);
    var total = 0;
    var totalDur = 0;
    for (final id in _picked) {
      final s = _svc(id);
      total += bInt(s['price']);
      totalDur += bInt(s['duration_min']);
    }
    final slots = _slots;
    final days = <DateTime>[
      for (var i = 0; i <= _maxAdvance; i++)
        DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day + i),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _header(t),
        _label(t.t('cu_services')),
        if (_services.isEmpty)
          Glass(
            child: Text(t.t('cu_no_services'),
                style: TextStyle(color: muted(context))),
          )
        else ...[
          Text(t.t('cu_pick'),
              style: TextStyle(color: muted(context), fontSize: 12.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _services)
                FilterChip(
                  label: Text([
                    bStr(s['name']),
                    '${fmtNum(bInt(s['duration_min']))} ${t.t('b_min')}',
                    if (bInt(s['price']) > 0)
                      '${fmtNum(bInt(s['price']))} $cur'.trim(),
                  ].join(' · ')),
                  selected: _picked.contains(bStr(s['service_id'])),
                  onSelected: (_) => _toggle(bStr(s['service_id'])),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.t('m_max', {'n': fmtNum(_maxServices)}),
              style: TextStyle(color: muted(context), fontSize: 12)),
        ],
        if (_picked.isNotEmpty) ...[
          _label(t.t('m_barber')),
          for (final sid in _picked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _choiceRow(sid, t),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${t.t('cu_total')}: ',
                  style: TextStyle(color: muted(context))),
              Text('${fmtNum(total)} $cur'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Text('· ${fmtNum(totalDur)} ${t.t('b_min')}',
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ],
        _label(t.t('m_date')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(
                        '${t.t('d_${d.weekday % 7}')} ${fmtNum(d.day)}'),
                    selected: bIso(d) == bIso(_day),
                    onSelected: (_) => _setDay(d),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(bIso(_day),
            textDirection: TextDirection.ltr,
            style: TextStyle(color: muted(context), fontSize: 12)),
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
                    label: Text(bStr(slots[i]['start']),
                        textDirection: TextDirection.ltr),
                    selected: i == _slotIdx,
                    onSelected: (_) => setState(() => _slotIdx = i),
                  ),
              ],
            ),
        ],
        if (slots != null && _slotIdx >= 0 && _slotIdx < slots.length) ...[
          _label(t.t('cu_summary')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in bRows(slots[_slotIdx]['assign']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${bStr(_svc(bStr(a['service_id']))['name'])} · ${_staffName(bStr(a['staff_id']))}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('${bStr(a['start'])} – ${bStr(a['end'])}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: muted(context))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        GlassField(
          controller: _name,
          label: t.t('cu_your_name'),
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 12),
        GlassField(
          controller: _phone,
          label: t.t('cu_your_phone'),
          icon: Icons.phone_rounded,
          keyboard: TextInputType.phone,
          ltr: true,
        ),
        const SizedBox(height: 6),
        Text(t.t('cu_saved_note'),
            style: TextStyle(color: muted(context), fontSize: 12)),
        const SizedBox(height: 20),
        GradientButton(
          loading: _busy,
          icon: Icons.check_rounded,
          label: t.t('cu_book'),
          onPressed: () {
            if (!_busy) _book();
          },
        ),
      ],
    );
  }

  Widget _choiceRow(String sid, T4 t) {
    final svc = _svc(sid);
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
                    label: Text(
                      bInt(s['rating_count']) > 0
                          ? '${bStr(s['name'])} ★ ${cDouble(s['rating_avg']).toStringAsFixed(1)}'
                          : bStr(s['name']),
                    ),
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
