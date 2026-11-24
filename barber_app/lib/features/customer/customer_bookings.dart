import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../manager/booking_common.dart';
import 'customer_api.dart';

class MyBookingsTab extends StatefulWidget {
  const MyBookingsTab({super.key, required this.api, this.refresh});
  final CustomerApi api;
  final ValueListenable<int>? refresh;
  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  bool _loading = true;
  bool _busy = false;
  Object? _err;
  List<List<Map<String, dynamic>>> _groups = <List<Map<String, dynamic>>>[];

  T6 _tr() => T6(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_onRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) _load();
  }

  bool _isActive(List<Map<String, dynamic>> g) => g.any((b) {
        final s = bStr(b['status']);
        return s == 'booked' || s == 'checked_in';
      });

  String _key(List<Map<String, dynamic>> g) =>
      '${bStr(g.first['date'])} ${bStr(g.first['start_time'])}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.api.myBookings();
      if (!mounted) return;
      final rows = bFirstList(r, ['bookings']);
      final map = <String, List<Map<String, dynamic>>>{};
      for (final b in rows) {
        final g = bStr(b['group_id']).isNotEmpty
            ? bStr(b['group_id'])
            : bStr(b['booking_id']);
        (map[g] ??= <Map<String, dynamic>>[]).add(b);
      }
      final groups = map.values.toList();
      for (final g in groups) {
        g.sort((a, b) => bMin(bStr(a['start_time']))
            .compareTo(bMin(bStr(b['start_time']))));
      }
      final active = groups.where(_isActive).toList()
        ..sort((a, b) => _key(a).compareTo(_key(b)));
      final past = groups.where((g) => !_isActive(g)).toList()
        ..sort((a, b) => _key(b).compareTo(_key(a)));
      setState(() {
        _groups = <List<Map<String, dynamic>>>[...active, ...past];
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

  Future<void> _run(Future<void> Function() f, {String? okMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
      if (!mounted) return;
      if (okMsg != null) bSnack(context, okMsg);
      await _load();
    } catch (e) {
      if (!mounted) return;
      bSnack(context, _tr().error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _gid(List<Map<String, dynamic>> g) =>
      bStr(g.first['group_id']).isNotEmpty
          ? bStr(g.first['group_id'])
          : bStr(g.first['booking_id']);

  Future<void> _cancel(List<Map<String, dynamic>> g) async {
    final t = _tr();
    final ok = await confirmDialog(
      context,
      title: t.t('cu_cancel'),
      message: t.t('cu_cancel_q'),
      okLabel: t.t('cu_cancel_yes'),
      cancelLabel: t.t('c_cancel'),
      danger: true,
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await widget.api.cancel(_gid(g));
    }, okMsg: t.t('b_saved'));
  }

  Future<void> _checkin(List<Map<String, dynamic>> g) async {
    final t = _tr();
    final ok = await confirmDialog(
      context,
      title: t.t('cu_checkin'),
      message: t.t('cu_checkin_q'),
      okLabel: t.t('cu_checkin_yes'),
      cancelLabel: t.t('c_cancel'),
      danger: false,
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await widget.api.checkin(_gid(g));
    }, okMsg: t.t('b_saved'));
  }

  Future<void> _rate(List<Map<String, dynamic>> g) async {
    final t = _tr();
    final rows = g.where((b) => cFlag(b['needs_rating'])).toList();
    if (rows.isEmpty) return;
    final res = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => _RateDialog(rows: rows, t: t),
    );
    if (res == null || !mounted) return;
    await _run(() async {
      await widget.api.rate(res);
    }, okMsg: t.t('cu_rate_thanks'));
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
    final t = T6(SettingsScope.of(context).lang);
    final children = <Widget>[];
    if (_loading && _groups.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (_err != null) {
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
    } else if (_groups.isEmpty) {
      children.add(Glass(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              const GradientIcon(Icons.event_available_rounded, size: 44),
              const SizedBox(height: 12),
              Text(t.t('cu_mine_empty'),
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ),
      ));
    } else {
      if (_loading) {
        children.add(const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: LinearProgressIndicator(minHeight: 3),
        ));
      }
      var shownPast = false;
      var shownActive = false;
      for (final g in _groups) {
        final active = _isActive(g);
        if (active && !shownActive) {
          shownActive = true;
          children.add(_title(t.t('cu_upcoming')));
        }
        if (!active && !shownPast) {
          shownPast = true;
          children.add(_title(t.t('cu_past')));
        }
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _card(g, t),
        ));
      }
    }
    children.add(const SizedBox(height: 30));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        children: children,
      ),
    );
  }

  Widget _title(String s) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(s,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _card(List<Map<String, dynamic>> g, T6 t) {
    final first = g.first;
    var endMin = 0;
    var endStr = '';
    for (final b in g) {
      final m = bMin(bStr(b['end_time']));
      if (m >= endMin) {
        endMin = m;
        endStr = bStr(b['end_time']);
      }
    }
    final canCancel = g.any((b) => cFlag(b['can_cancel']));
    final canCheckin = g.any((b) => cFlag(b['can_checkin']));
    final needRate = g.any((b) => cFlag(b['needs_rating']));
    final hasBooked = g.any((b) => bStr(b['status']) == 'booked');
    final dead = g.every((b) {
      final s = bStr(b['status']);
      return s == 'cancelled' || s == 'no_show';
    });
    final phone = bStr(first['shop_phone']);
    final address = bStr(first['shop_address']);
    final dt = bParse(bStr(first['date']));
    final wd = dt == null ? '' : t.t('d_${dt.weekday % 7}');
    final card = Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bStr(first['shop_name']),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 18, color: muted(context)),
                  const SizedBox(width: 6),
                  Text(wd,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(localDigits(bStr(first['date']), t.lang),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Text(
                  localDigits('${bStr(first['start_time'])} – $endStr', t.lang),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded, size: 18, color: muted(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(localDigits(address, t.lang),
                      style: TextStyle(color: muted(context), fontSize: 12.5)),
                ),
              ],
            ),
          ],
          if (phone.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Clipboard.setData(ClipboardData(text: phone));
                bSnack(context, t.t('b_copied'));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 18, color: muted(context)),
                    const SizedBox(width: 6),
                    Text(localDigits(phone, t.lang),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: muted(context))),
                  ],
                ),
              ),
            ),
          const Divider(height: 22),
          for (final b in g) _line(b, t),
          if (hasBooked && !canCancel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(t.t('cu_late'),
                  style: TextStyle(color: muted(context), fontSize: 12)),
            ),
          if (canCheckin || needRate || canCancel)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canCheckin)
                  GradientButton(
                    compact: true,
                    icon: Icons.event_seat_rounded,
                    label: t.t('cu_checkin'),
                    onPressed: () {
                      if (!_busy) _checkin(g);
                    },
                  ),
                if (needRate)
                  GradientButton(
                    compact: true,
                    icon: Icons.star_rounded,
                    label: t.t('cu_rate'),
                    onPressed: () {
                      if (!_busy) _rate(g);
                    },
                  ),
                if (canCancel)
                  GradientButton(
                    compact: true,
                    danger: true,
                    outlined: true,
                    icon: Icons.cancel_rounded,
                    label: t.t('cu_cancel'),
                    onPressed: () {
                      if (!_busy) _cancel(g);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
    return dead ? Opacity(opacity: 0.6, child: card) : card;
  }

  Widget _line(Map<String, dynamic> b, T6 t) {
    final status = bStr(b['status']);
    final rating = bInt(b['rating']);
    final price = bInt(b['price']);
    final dur = bInt(b['duration_min']);
    final sub = <String>[
      if (bStr(b['staff_name']).isNotEmpty) bStr(b['staff_name']),
      if (dur > 0) '${fmtNum(dur, t.lang)} ${t.t('b_min')}',
      if (price > 0) fmtNum(price, t.lang),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                        style:
                            TextStyle(color: muted(context), fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          if (rating > 0) ...[
            const Icon(Icons.star_rounded, size: 18, color: AppColors.amber),
            const SizedBox(width: 2),
            Text(fmtNum(rating, t.lang),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
          ],
          Pill(t.t('b_status_$status'), color: _stColor(status)),
        ],
      ),
    );
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog({required this.rows, required this.t});
  final List<Map<String, dynamic>> rows;
  final T6 t;
  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  final Map<String, int> _v = <String, int>{};
  bool _missing = false;

  void _send() {
    for (final r in widget.rows) {
      if ((_v[bStr(r['booking_id'])] ?? 0) < 1) {
        setState(() => _missing = true);
        return;
      }
    }
    Navigator.of(context).pop(<Map<String, dynamic>>[
      for (final r in widget.rows)
        <String, dynamic>{
          'booking_id': bStr(r['booking_id']),
          'rating': _v[bStr(r['booking_id'])] ?? 0,
        },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(t.t('cu_rate_title')),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('cu_rate_note'),
                  style: TextStyle(color: muted(context), fontSize: 12.5)),
              const SizedBox(height: 12),
              for (final r in widget.rows) ...[
                Text(
                  [bStr(r['service_name']), bStr(r['staff_name'])]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() {
                          _v[bStr(r['booking_id'])] = i;
                          _missing = false;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            (_v[bStr(r['booking_id'])] ?? 0) >= i
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 34,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_missing)
                Text(t.t('cu_rate_all'),
                    style: TextStyle(color: lk(context).danger)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.t('c_cancel')),
        ),
        FilledButton(
          onPressed: _send,
          child: Text(t.t('cu_rate_send')),
        ),
      ],
    );
  }
}
