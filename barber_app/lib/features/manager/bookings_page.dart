import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/cal_fmt.dart';
import '../../app/currency.dart';
import '../../app/date_pick.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'manual_booking_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';
import 'timeoff_page.dart';
const Map<String, String> _appCustomer = {
  'fa': 'مشتری (از برنامه)',
  'en': 'App customer',
  'ar': 'زبون من التطبيق',
};
const Map<String, Map<String, String>> _bx = {
  'fa': {
    'tab0': 'جاری',
    'tab1': 'انجام‌شده',
    'tab2': 'نیامده',
    'tab3': 'لغوشده',
    'locked': 'فعال می‌شود از ساعت {t}',
    'expired': 'مهلت این اقدام تمام شده است',
    'total': 'جمع',
    'view1': 'ردیفی',
    'view2': '۲ ستون',
    'view3': '۳ ستون',
  },
  'en': {
    'tab0': 'Current',
    'tab1': 'Done',
    'tab2': 'No-show',
    'tab3': 'Cancelled',
    'locked': 'Unlocks at {t}',
    'expired': 'The time to act has passed',
    'total': 'Total',
    'view1': 'List',
    'view2': '2 columns',
    'view3': '3 columns',
  },
  'ar': {
    'tab0': 'الحالية',
    'tab1': 'المنجزة',
    'tab2': 'لم يحضر',
    'tab3': 'الملغاة',
    'locked': 'يُفعَّل من الساعة {t}',
    'expired': 'انتهت مهلة الإجراء',
    'total': 'المجموع',
    'view1': 'قائمة',
    'view2': 'عمودان',
    'view3': '3 أعمدة',
  },
};
String _lx(String lang, String k) =>
    (_bx[lang] ?? _bx['fa']!)[k] ?? _bx['fa']![k] ?? k;
/// تا چند دقیقه بعد از پایان نوبت، دکمه‌ها فعال می‌مانند
const int _kGraceMin = 15;
/// اگر «نام» در واقع یک شناسه‌ی فنی باشد (مثل c_83hd92kd01) نشان داده نمی‌شود
String _niceName(String n, String lang) {
  final s = n.trim();
  if (s.isEmpty) return '—';
  final looksId = RegExp(r'^[A-Za-z0-9_\-]{10,}$').hasMatch(s) &&
      RegExp(r'[0-9_\-]').hasMatch(s);
  if (looksId) return _appCustomer[lang] ?? _appCustomer['fa']!;
  return s;
}
/// تاریخ + دقیقه → دقیقه‌ی مطلق (برای مقایسه)
int _absOf(String date, int min) {
  final d = date.length >= 10 ? date.substring(0, 10) : date;
  final p = DateTime.tryParse(d);
  if (p == null) return -1;
  return DateTime.utc(p.year, p.month, p.day).millisecondsSinceEpoch ~/ 60000 +
      min;
}
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
  int _tab = 0;
  int _cols = 0; // 0 = خودکار (ویندوز: ۲ ستون)
  String? _shopCur;
  int _baseAbs = -1;
  DateTime _fetchedAt = DateTime.now();
  Timer? _tick;
  bool get _owner => widget.ctx.session.isOwner;
  T6 _tr() => T6(SettingsScope.read(context).lang);
  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }
  @override
  void dispose() {
    _tick?.cancel();
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
  /// «الان» به دقیقه‌ی مطلق؛ از ساعت سرور و گذشت زمان از آخرین دریافت
  int _curAbs() {
    if (_baseAbs >= 0) {
      return _baseAbs + DateTime.now().difference(_fetchedAt).inMinutes;
    }
    final n = DateTime.now();
    return _absOf(bIso(DateTime(n.year, n.month, n.day)), n.hour * 60 + n.minute);
  }
  Future<List<Map<String, dynamic>>> _loadStaff(ShopRaw raw) async {
    if (!_owner || _staff.isNotEmpty) return _staff;
    try {
      final sr = await raw.call('staff_list');
      return bFirstList(sr, ['staff', 'items', 'list']);
    } catch (_) {
      return _staff;
    }
  }
  Future<void> _loadCur(ShopRaw raw) async {
    if (_shopCur != null) return;
    try {
      final me = await raw.call('me');
      final sh = me['shop'];
      if (sh is Map) _shopCur = '${sh['currency'] ?? ''}';
    } catch (_) {}
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
      // سه درخواست هم‌زمان (سریع‌تر)
      final staffF = _loadStaff(raw);
      final curF = _loadCur(raw);
      final r = await raw.call('bookings_list', params);
      final staff = await staffF;
      await curF;
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
      var base = -1;
      if (bStr(now['date']).isNotEmpty) {
        final nm = bStr(now['time']).isNotEmpty
            ? bMin(bStr(now['time']))
            : bInt(now['min']);
        base = _absOf(bStr(now['date']), nm);
      }
      setState(() {
        _now = now;
        _baseAbs = base;
        _fetchedAt = DateTime.now();
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
    final st = SettingsScope.read(context);
    final cur = bParse(_date ?? '') ?? DateTime.now();
    final d = await pickLocalDate(
      context,
      initial: cur,
      first: DateTime(2020),
      last: DateTime(2100),
      calKey: st.calendarKey,
      lang: st.lang,
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
  /// گروه‌ها: تازه‌ترین نوبت بالا
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
    list.sort((a, b) => bMin(bStr(b.first['start_time']))
        .compareTo(bMin(bStr(a.first['start_time']))));
    return list;
  }
  /// 0 جاری، 1 انجام‌شده، 2 نیامده، 3 لغوشده
  int _cat(List<Map<String, dynamic>> g) {
    final ss = g.map((b) => bStr(b['status'])).toList();
    if (ss.any((s) => s == 'booked' || s == 'checked_in')) return 0;
    if (ss.any((s) => s == 'finished')) return 1;
    if (ss.any((s) => s == 'no_show')) return 2;
    return 3;
  }
  /// 0 = هنوز قفل ، 1 = فعال ، 2 = مهلت تمام شد
  int _win(String date, String start, String end) {
    final s = _absOf(date, bMin(start));
    var e = _absOf(date, bMin(end));
    if (s < 0) return 1;
    if (e < s) e += 1440;
    final now = _curAbs();
    if (now < s) return 0;
    if (now <= e + _kGraceMin) return 1;
    return 2;
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
    final t = T6(st.lang);
    final all = _groups();
    final counts = <int>[0, 0, 0, 0];
    for (final g in all) {
      counts[_cat(g)]++;
    }
    final groups = all.where((g) => _cat(g) == _tab).toList();
    final wide = MediaQuery.of(context).size.width >= 900;
    final cols = wide ? (_cols == 0 ? 2 : _cols) : 1;
    final children = <Widget>[
      _dayBar(t),
      const SizedBox(height: 10),
      _tabBar(t, counts),
      const SizedBox(height: 10),
    ];
    if (wide) {
      children.add(_viewBar(t, cols));
      children.add(const SizedBox(height: 10));
    }
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
      } else if (cols == 1) {
        for (final g in groups) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _groupCard(g, t),
          ));
        }
      } else {
        for (var i = 0; i < groups.length; i += cols) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: i + j < groups.length
                        ? _groupCard(groups[i + j], t)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ));
        }
      }
    }
    children.add(const SizedBox(height: 90));
    final double maxW = cols == 1 ? 720.0 : (cols == 2 ? 1100.0 : 1500.0);
    return GlassScaffold(
      title: t.t('b_title'),
      maxWidth: maxW,
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
  Widget _viewBar(T6 t, int cols) {
    const icons = <IconData>[
      Icons.view_agenda_rounded,
      Icons.grid_view_rounded,
      Icons.apps_rounded,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                avatar: Icon(icons[i - 1], size: 18),
                label: Text(_lx(t.lang, 'view$i')),
                selected: cols == i,
                onSelected: (_) => setState(() => _cols = i),
              ),
            ),
        ],
      ),
    );
  }
  Widget _tabBar(T6 t, List<int> counts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text('${_lx(t.lang, 'tab$i')} · ${fmtNum(counts[i], t.lang)}'),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
              ),
            ),
        ],
      ),
    );
  }
  Widget _dayBar(T6 t) {
    final st = SettingsScope.read(context);
    final day = _date;
    final dt = day == null ? null : bParse(day);
    final wd = dt == null ? '' : t.t('d_${dt.weekday % 7}');
    final isToday = day != null && day == bStr(_now['date']);
    final dateText =
        day == null ? '—' : CalFmt.date(day, st.calendarKey, t.lang);
    // فلش‌ها خودشان در RTL برعکس می‌شوند؛ دستی برعکس نکن
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
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
                    Text(dateText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted(context))),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: day == null ? null : () => _shift(1),
          ),
        ],
      ),
    );
  }
  Widget _filterBar(T6 t) {
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
  Widget _groupCard(List<Map<String, dynamic>> g, T6 t) {
    final first = g.first;
    final name = _niceName(bStr(first['customer_name']), t.lang);
    final phone = bStr(first['customer_phone']);
    final manual = g.any((b) => bStr(b['source']) == 'manual');
    final cur = bStr(first['currency']).isNotEmpty
        ? bStr(first['currency'])
        : (_shopCur ?? '');
    var endMin = 0;
    var endStr = '';
    var startMin = 24 * 60;
    var startStr = bStr(first['start_time']);
    var total = 0;
    for (final b in g) {
      final m = bMin(bStr(b['end_time']));
      if (m >= endMin) {
        endMin = m;
        endStr = bStr(b['end_time']);
      }
      final sm = bMin(bStr(b['start_time']));
      if (sm < startMin) {
        startMin = sm;
        startStr = bStr(b['start_time']);
      }
      final s = bStr(b['status']);
      if (s != 'cancelled' && s != 'no_show') total += parsePrice(b['price']);
    }
    final allDead = g.every((b) {
      final s = bStr(b['status']);
      return s == 'cancelled' || s == 'no_show';
    });
    final anyBooked = g.any((b) => bStr(b['status']) == 'booked');
    final gw = _win(bStr(first['date']), startStr, endStr);
    final gid = bStr(first['group_id']);
    final card = Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(localDigits('$startStr – $endStr', t.lang),
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
                child: Text(name,
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
                        Text(localDigits(phone, t.lang),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: muted(context))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
          for (final b in g) _line(b, t, cur),
          if (g.length > 1 && total > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text('${_lx(t.lang, 'total')}: ',
                      style: TextStyle(color: muted(context))),
                  Text(fmtMoney(total, cur, t.lang),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          // «لغو» از لحظه‌ی ثبت نوبت فعال است (تا ۱۵ دقیقه بعد از پایان)
          if (anyBooked && gw != 2) ...[
            const SizedBox(height: 4),
            GradientButton(
              compact: true,
              danger: true,
              icon: Icons.cancel_rounded,
              label: t.t('b_cancel'),
              onPressed: _busy
                  ? null
                  : () {
                      _confirmAct(
                        message: t.t('b_cancel_q'),
                        yes: t.t('b_cancel_yes'),
                        danger: true,
                        action: 'booking_cancel',
                        params: gid.isNotEmpty
                            ? <String, dynamic>{'group_id': gid}
                            : <String, dynamic>{
                                'booking_id': bStr(first['booking_id'])
                              },
                      );
                    },
            ),
          ],
        ],
      ),
    );
    return allDead ? Opacity(opacity: 0.6, child: card) : card;
  }
  Widget _line(Map<String, dynamic> b, T6 t, String cur) {
    final status = bStr(b['status']);
    final active = status == 'booked' || status == 'checked_in';
    final w = active
        ? _win(bStr(b['date']), bStr(b['start_time']), bStr(b['end_time']))
        : 1;
    final canDone = active;
    final canNo = status == 'booked';
    final rating = bInt(b['rating']);
    final price = parsePrice(b['price']);
    final dur = bInt(b['duration_min']);
    final bid = bStr(b['booking_id']);
    final sub = <String>[
      if (bStr(b['staff_name']).isNotEmpty) bStr(b['staff_name']),
      if (dur > 0) '${fmtNum(dur, t.lang)} ${t.t('b_min')}',
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
                    if (price > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(fmtMoney(price, cur, t.lang),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13.5)),
                      ),
                  ],
                ),
              ),
              if (rating > 0) ...[
                const Icon(Icons.star_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 2),
                Text(fmtNum(rating, t.lang),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
              ],
              Pill(t.t('b_status_$status'), color: _stColor(status)),
            ],
          ),
          if (active && w == 2) ...[
            const SizedBox(height: 6),
            Text(_lx(t.lang, 'expired'),
                style: TextStyle(color: muted(context), fontSize: 12)),
          ],
          if (active && w != 2) ...[
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
                    onPressed: (_busy || w != 1)
                        ? null
                        : () {
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
                    onPressed: (_busy || w != 1)
                        ? null
                        : () {
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
            if (w == 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    _lx(t.lang, 'locked').replaceAll('{t}',
                        localDigits(bStr(b['start_time']), t.lang)),
                    style: TextStyle(color: muted(context), fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}
