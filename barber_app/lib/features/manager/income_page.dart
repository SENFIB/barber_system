import 'package:flutter/material.dart';
import '../../app/currency.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

const Map<String, Map<String, String>> _ix = {
  'fa': {
    'title': 'درآمد',
    'r0': 'امروز',
    'r1': '۷ روز اخیر',
    'r2': '۳۰ روز اخیر',
    'r3': 'همه (موجود)',
    'total': 'جمع درآمد',
    'mine': 'درآمد من',
    'visits': 'مراجعه',
    'custs': 'مشتری',
    'avg': 'میانگین هر مراجعه',
    'by_staff': 'به تفکیک پرسنل',
    'my_custs': 'مشتری‌های من',
    'visit': 'مراجعه',
    'note': 'فقط نوبت‌های «انجام‌شده» و تا زمان پاکسازی خودکار سوابق حساب می‌شوند.',
    'empty': 'در این بازه درآمدی ثبت نشده است',
    'app_cust': 'مشتری (از برنامه)',
    'unknown': 'نامشخص',
  },
  'en': {
    'title': 'Income',
    'r0': 'Today',
    'r1': 'Last 7 days',
    'r2': 'Last 30 days',
    'r3': 'All available',
    'total': 'Total income',
    'mine': 'My income',
    'visits': 'Visits',
    'custs': 'Customers',
    'avg': 'Average per visit',
    'by_staff': 'By staff',
    'my_custs': 'My customers',
    'visit': 'visits',
    'note':
        'Only finished bookings are counted, and only until the automatic cleanup.',
    'empty': 'No income recorded in this period',
    'app_cust': 'App customer',
    'unknown': 'Unknown',
  },
  'ar': {
    'title': 'الإيرادات',
    'r0': 'اليوم',
    'r1': 'آخر ٧ أيام',
    'r2': 'آخر ٣٠ يومًا',
    'r3': 'الكل (المتاح)',
    'total': 'إجمالي الإيرادات',
    'mine': 'إيراداتي',
    'visits': 'زيارات',
    'custs': 'زبائن',
    'avg': 'متوسط الزيارة',
    'by_staff': 'حسب الموظفين',
    'my_custs': 'زبائني',
    'visit': 'زيارات',
    'note': 'تُحتسب المواعيد المنجزة فقط وحتى موعد التنظيف التلقائي.',
    'empty': 'لا توجد إيرادات في هذه الفترة',
    'app_cust': 'زبون من التطبيق',
    'unknown': 'غير معروف',
  },
};

String _lx(String lang, String k) =>
    (_ix[lang] ?? _ix['fa']!)[k] ?? _ix['fa']![k] ?? k;

String _d10(String s) => s.length >= 10 ? s.substring(0, 10) : s;

class _Cust {
  _Cust(this.name, this.phone);
  final String name;
  final String phone;
  int sum = 0;
  final Set<String> groups = <String>{};
}

class _Stf {
  _Stf(this.name);
  final String name;
  int sum = 0;
  final Set<String> groups = <String>{};
  final Map<String, _Cust> custs = <String, _Cust>{};
}

class _Agg {
  int total = 0;
  final Set<String> groups = <String>{};
  final Set<String> custKeys = <String>{};
  final Map<String, _Stf> staff = <String, _Stf>{};
}

class IncomePage extends StatefulWidget {
  const IncomePage(this.ctx, {super.key});
  final ShopCtx ctx;
  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  bool _loading = true;
  Object? _err;
  int _range = 1; // 0 امروز، 1 هفت روز، 2 سی روز، 3 همه
  int _seq = 0;
  String _cur = '';
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  final Set<String> _closed = <String>{};

  bool get _owner => widget.ctx.session.isOwner;

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
    final my = ++_seq;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final raw = ShopRaw(SettingsScope.read(context));
      final n = DateTime.now();
      var back = 0;
      if (_range == 0) {
        back = 1;
      } else if (_range == 1) {
        back = 8;
      } else if (_range == 2) {
        back = 31;
      }
      final from = _range == 3
          ? '2020-01-01'
          : bIso(DateTime(n.year, n.month, n.day - back));
      final to = bIso(DateTime(n.year, n.month, n.day + 1));

      Future<void> loadCur() async {
        if (_cur.isNotEmpty) return;
        try {
          final me = await raw.call('me');
          final sh = me['shop'];
          if (sh is Map) _cur = '${sh['currency'] ?? ''}';
        } catch (_) {}
      }

      final curF = loadCur();
      final r = await raw
          .call('bookings_list', <String, dynamic>{'date_from': from, 'date_to': to});
      await curF;
      if (!mounted || my != _seq) return;

      final nowRaw = r['now'];
      final now = nowRaw is Map
          ? Map<String, dynamic>.from(nowRaw)
          : <String, dynamic>{};
      final nowDate =
          bStr(now['date']).isNotEmpty ? _d10(bStr(now['date'])) : bIso(n);
      var minDate = '';
      if (_range < 3) {
        const days = <int>[0, 6, 29];
        final d = bParse(nowDate);
        if (d != null) {
          minDate = bIso(DateTime(d.year, d.month, d.day - days[_range]));
        }
      }
      final sid = '${widget.ctx.session.staffId}';
      final all = bFirstList(r, ['bookings']);
      final rows = all.where((b) {
        if (bStr(b['status']) != 'finished') return false;
        final d = _d10(bStr(b['date']));
        if (d.compareTo(nowDate) > 0) return false;
        if (minDate.isNotEmpty && d.compareTo(minDate) < 0) return false;
        if (!_owner && sid.isNotEmpty && sid != 'null') {
          final bs = bStr(b['staff_id']);
          if (bs.isNotEmpty && bs != sid) return false;
        }
        return true;
      }).toList();
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || my != _seq) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }

  _Agg _agg(String lang) {
    final a = _Agg();
    for (final b in _rows) {
      final price = parsePrice(b['price']);
      final gid = bStr(b['group_id']).isNotEmpty
          ? bStr(b['group_id'])
          : bStr(b['booking_id']);
      var sname = _owner ? bStr(b['staff_name']).trim() : '_me';
      if (sname.isEmpty) sname = _lx(lang, 'unknown');
      final phone = bStr(b['customer_phone']).trim();
      var cname = bStr(b['customer_name']).trim();
      final looksId = RegExp(r'^[A-Za-z0-9_\-]{10,}$').hasMatch(cname) &&
          RegExp(r'[0-9_\-]').hasMatch(cname);
      if (cname.isEmpty) {
        cname = '—';
      } else if (looksId) {
        cname = _lx(lang, 'app_cust');
      }
      final key = phone.isNotEmpty ? phone : cname;
      a.total += price;
      a.groups.add(gid);
      a.custKeys.add(key);
      final s = a.staff[sname] ??= _Stf(sname);
      s.sum += price;
      s.groups.add(gid);
      final c = s.custs[key] ??= _Cust(cname, phone);
      c.sum += price;
      c.groups.add(gid);
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final lang = st.lang;
    final t = T6(lang);
    final a = _agg(lang);
    final staff = a.staff.values.toList()
      ..sort((x, y) => y.sum.compareTo(x.sum));

    final children = <Widget>[
      _rangeBar(lang),
      const SizedBox(height: 10),
    ];

    if (_loading && _rows.isEmpty) {
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
      } else if (_rows.isEmpty && !_loading) {
        children.add(Glass(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                GradientIcon(Icons.payments_rounded, size: 44),
                const SizedBox(height: 12),
                Text(_lx(lang, 'empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted(context))),
              ],
            ),
          ),
        ));
      } else {
        children.add(_summary(a, lang));
        children.add(const SizedBox(height: 14));
        if (_owner) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Text(_lx(lang, 'by_staff'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ));
        } else {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Text(_lx(lang, 'my_custs'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ));
        }
        for (final s in staff) {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _staffCard(s, a, lang),
          ));
        }
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_lx(lang, 'note'),
              style: TextStyle(color: muted(context), fontSize: 12)),
        ));
      }
    }
    children.add(const SizedBox(height: 40));

    return GlassScaffold(
      title: _lx(lang, 'title'),
      maxWidth: 720,
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

  Widget _rangeBar(String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(_lx(lang, 'r$i')),
                selected: _range == i,
                onSelected: (_) {
                  if (_range == i) return;
                  setState(() => _range = i);
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted(context), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summary(_Agg a, String lang) {
    final visits = a.groups.length;
    final avg = visits > 0 ? a.total ~/ visits : 0;
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(_lx(lang, _owner ? 'total' : 'mine'),
              style: TextStyle(color: muted(context))),
          const SizedBox(height: 6),
          Text(fmtMoney(a.total, _cur, lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const Divider(height: 26),
          Row(
            children: [
              _stat(fmtNum(visits, lang), _lx(lang, 'visits')),
              _stat(fmtNum(a.custKeys.length, lang), _lx(lang, 'custs')),
              _stat(fmtMoney(avg, _cur, lang), _lx(lang, 'avg')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staffCard(_Stf s, _Agg a, String lang) {
    final open = !_closed.contains(s.name);
    final share = a.total > 0 ? s.sum / a.total : 0.0;
    final custs = s.custs.values.toList()
      ..sort((x, y) => y.sum.compareTo(x.sum));
    final title = s.name == '_me' ? _lx(lang, 'mine') : s.name;
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              if (open) {
                _closed.add(s.name);
              } else {
                _closed.remove(s.name);
              }
            }),
            child: Row(
              children: [
                GradientIcon(Icons.person_rounded, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                          '${fmtNum(custs.length, lang)} ${_lx(lang, 'custs')} · ${fmtNum(s.groups.length, lang)} ${_lx(lang, 'visit')}',
                          style: TextStyle(
                              color: muted(context), fontSize: 12.5)),
                    ],
                  ),
                ),
                Text(fmtMoney(s.sum, _cur, lang),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: muted(context)),
              ],
            ),
          ),
          if (_owner) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: share, minHeight: 6),
            ),
          ],
          if (open) ...[
            const Divider(height: 24),
            for (final c in custs) _custRow(c, lang),
          ],
        ],
      ),
    );
  }

  Widget _custRow(_Cust c, String lang) {
    final visits = c.groups.length;
    final sub = <String>[
      if (c.phone.isNotEmpty) localDigits(c.phone, lang),
      if (visits > 1) '${fmtNum(visits, lang)} ${_lx(lang, 'visit')}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, size: 18, color: muted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                if (sub.isNotEmpty)
                  Text(sub,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: muted(context), fontSize: 12)),
              ],
            ),
          ),
          Text(fmtMoney(c.sum, _cur, lang),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
