import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s3.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'manual_booking_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';
import 'timeoff_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage(this.ctx, {super.key});
  final ShopCtx ctx;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _loading = true;
  bool _busy = false;
  Object? _err;
  String? _date;
  Map<String, dynamic> _now = <String, dynamic>{};
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _staff = <Map<String, dynamic>>[];
  String _staffFilter = '';

  bool get _owner => widget.ctx.session.isOwner;
  T3 _tr() => T3(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
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
      String from;
      String to;
      if (_date == null) {
        final n = DateTime.now();
        from = bIso(DateTime(n.year, n.month, n.day - 1));
        to = bIso(DateTime(n.year, n.month, n.day + 1));
      } else {
        from = _date!;
        to = _date!;
      }
      final params = <String, dynamic>{'date_from': from, 'date_to': to};
      if (_owner && _staffFilter.isNotEmpty) params['staff_id'] = _staffFilter;
      final r = await raw.call('bookings_list', params);
      if (!mounted) return;
      final nowRaw = r['now'];
      final now = nowRaw is Map
          ? Map<String, dynamic>.from(nowRaw)
          : <String, dynamic>{};
      final day = _date ??
          (bStr(now['date']).isNotEmpty
              ? bStr(now['date'])
              : bIso(DateTime.now()));
      final all = bFirstList(r, ['bookings']);
      var staff = _staff;
      if (_owner && staff.isEmpty) {
        try {
          final sr = await raw.call('staff_list');
          staff = bFirstList(sr, ['staff', 'items', 'list']);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _now = now;
        _date = day;
        _staff = staff;
        _rows = all.where((b) => bStr(b['date']).startsWith(day)).toList();
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

  Future<void> _act(String action, Map<String, dynamic> params) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call(action, params);
      if (!mounted) return;
      bSnack(context, _tr().t('b_saved'));
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      bSnack(context, _tr().error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAct({
    required String message,
    required String yes,
    required bool danger,
    required String action,
    required Map<String, dynamic> params,
  }) async {
    final t = _tr();
    final ok = await confirmDialog(
      context,
      title: t.t('b_title'),
      message: message,
      okLabel: yes,
      cancelLabel: t.t('c_cancel'),
      danger: danger,
    );
    if (ok != true || !mounted) return;
    await _act(action, params);
  }

  void _shift(int n) {
    final d = bParse(_date ?? '');
    if (d == null) return;
    setState(() => _date = bIso(DateTime(d.year, d.month, d.day + n)));
    _load();
  }

  Future<void> _pick() async {
    final cur = bParse(_date ?? '') ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    setState(() => _date = bIso(d));
    _load();
  }

  Future<void> _newManual() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ManualBookingPage(widget.ctx, initialDate: _date),
      ),
    );
    if (ok == true && mounted) _load();
  }

  List<List<Map<String, dynamic>>> _groups() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final b in _rows) {
      final g = bStr(b['group_id']).isNotEmpty
          ? bStr(b['group_id'])
          : bStr(b['booking_id']);
      (map[g] ??= <Map<String, dynamic>>[]).add(b);
    }
    final list = map.values.toList();
    for (final g in list) {
      g.sort((a, b) => bMin(bStr(a['start_time']))
          .compareTo(bMin(bStr(b['start_time']))));
    }
    list.sort((a, b) => bMin(bStr(a.first['start_time']))
        .compareTo(bMin(bStr(b.first['start_time']))));
    return list;
  }

  bool _started(Map<String, dynamic> b) {
    final today = bStr(_now['date']);
    final d = bStr(b['date']);
    if (today.isEmpty) return false;
    if (d.compareTo(today) < 0) return true;
    if (d != today) return false;
    final nm = bStr(_now['time']).isNotEmpty
        ? bMin(bStr(_now['time']))
        : bInt(_now['min']);
    return bMin(bStr(b['start_time'])) <= nm;
  }

  Color _stColor(String s) {
    switch (s) {
      case 'booked':
        return AppColors.blue;
      case 'checked_in':
        return AppColors.amber;
      case 'finished':
        return AppColors.green;
      case 'no_show':
        return AppColors.pink;
      case 'cancelled':
        return lk(context).danger;
    }
    return muted(context);
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final t = T3(st.lang);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final groups = _groups();

    final children = <Widget>[
      _dayBar(t, rtl),
      const SizedBox(height: 10),
    ];
    if (_owner && _staff.length > 1) {
      children.add(_filterBar(t));
      children.add(const SizedBox(height: 10));
    }
    if (_loading && _date == null) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else {
      if (_loading) {
        children.add(const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: LinearProgressIndicator(minHeight: 3),
        ));
      }
      if (_err != null) {
        children.add(Glass(
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
        ));
      } else if (groups.isEmpty && !_loading) {
        children.add(Glass(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                GradientIcon(Icons.event_available_rounded, size: 44),
                const SizedBox(height: 12),
                Text(t.t('b_empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted(context))),
              ],
            ),
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            spacing: 8,
            children: [
              Pill(t.t('b_count', {'n': fmtNum(groups.length)})),
            ],
          ),
        ));
        for (final g in groups) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _groupCard(g, t),
          ));
        }
      }
    }
    children.add(const SizedBox(height: 90));

    return GlassScaffold(
      title: t.t('b_title'),
      maxWidth: 720,
      actions: [
        if (_owner)
          IconButton(
            tooltip: t.t('b_timeoff'),
            icon: const Icon(Icons.event_busy_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TimeOffPage(widget.ctx)),
            ),
          ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lk(context).primary,
        foregroundColor: lk(context).onPrimary,
        icon: const Icon(Icons.add_call),
        label: Text(t.t('b_new')),
        onPressed: _newManual,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: children,
        ),
      ),
    );
  }

  Widget _dayBar(T3 t, bool rtl) {
    final day = _date;
    final dt = day == null ? null : bParse(day);
    final wd = dt == null ? '' : t.t('d_${dt.weekday % 7}');
    final isToday = day != null && day == bStr(_now['date']);
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(rtl
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded),
            onPressed: day == null ? null : () => _shift(-1),
          ),
          Expanded(
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(wd,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Pill(t.t('b_today')),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(day ?? '—',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: muted(context))),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded),
            onPressed: day == null ? null : () => _shift(1),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(T3 t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(t.t('b_all')),
              selected: _staffFilter.isEmpty,
              onSelected: (_) {
                setState(() => _staffFilter = '');
                _load();
              },
            ),
          ),
          for (final s in _staff)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(bStr(s['name'])),
                selected: _staffFilter == bStr(s['staff_id']),
                onSelected: (_) {
                  setState(() => _staffFilter = bStr(s['staff_id']));
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupCard(List<Map<String, dynamic>> g, T3 t) {
    final first = g.first;
    final name = bStr(first['customer_name']);
    final phone = bStr(first['customer_phone']);
    final manual = g.any((b) => bStr(b['source']) == 'manual');
    var endMin = 0;
    var endStr = '';
    for (final b in g) {
      final m = bMin(bStr(b['end_time']));
      if (m >= endMin) {
        endMin = m;
        endStr = bStr(b['end_time']);
      }
    }
    final allDead = g.every((b) {
      final s = bStr(b['status']);
      return s == 'cancelled' || s == 'no_show';
    });
    final anyBooked = g.any((b) => bStr(b['status']) == 'booked');
    final gid = bStr(first['group_id']);

    final card = Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${bStr(first['start_time'])} – $endStr',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (manual) Pill(t.t('b_manual'), color: AppColors.amber),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 18, color: muted(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name.isEmpty ? '—' : name,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
              if (phone.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    bSnack(context, t.t('b_copied'));
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 16, color: muted(context)),
                        const SizedBox(width: 4),
                        Text(phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: muted(context))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
          for (final b in g) _line(b, t),
          if (anyBooked) ...[
            const SizedBox(height: 4),
            GradientButton(
              compact: true,
              danger: true,
              icon: Icons.cancel_rounded,
              label: t.t('b_cancel'),
              onPressed: () {
                if (_busy) return;
                _confirmAct(
                  message: t.t('b_cancel_q'),
                  yes: t.t('b_cancel_yes'),
                  danger: true,
                  action: 'booking_cancel',
                  params: gid.isNotEmpty
                      ? <String, dynamic>{'group_id': gid}
                      : <String, dynamic>{'booking_id': bStr(first['booking_id'])},
                );
              },
            ),
          ],
        ],
      ),
    );
    return allDead ? Opacity(opacity: 0.6, child: card) : card;
  }

  Widget _line(Map<String, dynamic> b, T3 t) {
    final status = bStr(b['status']);
    final canDone = status == 'booked' || status == 'checked_in';
    final canNo = status == 'booked' && _started(b);
    final rating = bInt(b['rating']);
    final price = bInt(b['price']);
    final dur = bInt(b['duration_min']);
    final bid = bStr(b['booking_id']);
    final sub = <String>[
      if (bStr(b['staff_name']).isNotEmpty) bStr(b['staff_name']),
      if (dur > 0) '${fmtNum(dur)} ${t.t('b_min')}',
      if (price > 0) fmtNum(price),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bStr(b['service_name']),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    if (sub.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub,
                            style: TextStyle(
                                color: muted(context), fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
              if (rating > 0) ...[
                const Icon(Icons.star_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 2),
                Text(fmtNum(rating),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
              ],
              Pill(t.t('b_status_$status'), color: _stColor(status)),
            ],
          ),
          if (canDone || canNo) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canDone)
                  GradientButton(
                    compact: true,
                    icon: Icons.check_circle_rounded,
                    label: t.t('b_done'),
                    onPressed: () {
                      if (_busy) return;
                      _confirmAct(
                        message: t.t('b_done_q'),
                        yes: t.t('b_done_yes'),
                        danger: false,
                        action: 'booking_finish',
                        params: <String, dynamic>{'booking_id': bid},
                      );
                    },
                  ),
                if (canNo)
                  GradientButton(
                    compact: true,
                    outlined: true,
                    icon: Icons.person_off_rounded,
                    label: t.t('b_noshow'),
                    onPressed: () {
                      if (_busy) return;
                      _confirmAct(
                        message: t.t('b_noshow_q'),
                        yes: t.t('b_noshow_yes'),
                        danger: true,
                        action: 'booking_noshow',
                        params: <String, dynamic>{'booking_id': bid},
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
