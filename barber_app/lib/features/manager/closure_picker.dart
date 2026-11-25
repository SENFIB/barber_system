import 'package:flutter/material.dart';
import '../../app/cal_names.dart';
import '../../app/extra_http.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';

class ClosureResult {
  final String from;
  final String to;
  final String reason;
  ClosureResult(this.from, this.to, this.reason);
}

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'انتخاب بازه‌ی تعطیلی',
    'hint': 'روز شروع و روز پایان را بزن. برای یک روز، همان روز را دوباره بزن.',
    'from': 'از',
    'to': 'تا',
    'reason': 'دلیل (اختیاری)',
    'ok': 'تأیید',
    'pick': 'یک روز انتخاب کن',
  },
  'en': {
    'title': 'Choose closure dates',
    'hint': 'Tap the first and the last day. For a single day tap it twice.',
    'from': 'From',
    'to': 'to',
    'reason': 'Reason (optional)',
    'ok': 'Confirm',
    'pick': 'Pick a day',
  },
  'ar': {
    'title': 'اختيار فترة الإغلاق',
    'hint': 'اضغط أول يوم وآخر يوم. ليوم واحد اضغطه مرتين.',
    'from': 'من',
    'to': 'إلى',
    'reason': 'السبب (اختياري)',
    'ok': 'تأكيد',
    'pick': 'اختر يومًا',
  },
};

const Map<String, List<String>> _wdNames = {
  // index 0 = Sunday
  'fa': ['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'],
  'en': ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  'ar': ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
};

// ---------------------------------------------------------------------------
// تبدیل تقویم‌ها (محلی، بدون سرور)
// ---------------------------------------------------------------------------
int _tm(int a, int b) => a - (a ~/ b) * b;

int _g2jdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d +
      (153 * mm + 2) ~/ 5 +
      365 * yy +
      yy ~/ 4 -
      yy ~/ 100 +
      yy ~/ 400 -
      32045;
}

List<int> _jdn2g(int jdn) {
  final a = jdn + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  return [
    100 * b + d - 4800 + m ~/ 10,
    m + 3 - 12 * (m ~/ 10),
    e - (153 * m + 2) ~/ 5 + 1,
  ];
}

const List<int> _jBreaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097,
  2192, 2262, 2324, 2394, 2456, 3178
];

/// [leap, gy, march]
List<int> _jalCal(int jy) {
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _jBreaks[0];
  var jump = 0;
  for (var i = 1; i < _jBreaks.length; i++) {
    final jm = _jBreaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += (jump ~/ 33) * 8 + _tm(jump, 33) ~/ 4;
    jp = jm;
  }
  var n = jy - jp;
  leapJ += (n ~/ 33) * 8 + (_tm(n, 33) + 3) ~/ 4;
  if (_tm(jump, 33) == 4 && jump - n == 4) leapJ += 1;
  final leapG = gy ~/ 4 - ((gy ~/ 100 + 1) * 3) ~/ 4 - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
  var leap = _tm(_tm(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;
  return [leap, gy, march];
}

int _j2jdn(int jy, int jm, int jd) {
  final r = _jalCal(jy);
  return _g2jdn(r[1], 3, r[2]) + (jm - 1) * 31 - (jm ~/ 7) * (jm - 7) + jd - 1;
}

List<int> _jdn2j(int jdn) {
  final gy = _jdn2g(jdn)[0];
  var jy = gy - 621;
  final r = _jalCal(jy);
  final jdn1f = _g2jdn(gy, 3, r[2]);
  var k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) return [jy, 1 + k ~/ 31, k % 31 + 1];
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r[0] == 1) k += 1;
  }
  return [jy, 7 + k ~/ 30, k % 30 + 1];
}

int _h2jdn(int y, int m, int d) =>
    d + (29.5 * (m - 1)).ceil() + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948439;

List<int> _jdn2h(int jdn) {
  final y = (30 * (jdn - 1948440) + 10646) ~/ 10631;
  var m = ((jdn - (29 + _h2jdn(y, 1, 1))) / 29.5).ceil() + 1;
  if (m > 12) m = 12;
  final d = jdn - _h2jdn(y, m, 1) + 1;
  return [y, m, d];
}

class ClosurePickerPage extends StatefulWidget {
  const ClosurePickerPage(
      {super.key, required this.settings, required this.calendar});
  final AppSettings settings;
  // نگه داشته شده برای سازگاری؛ تقویم از تنظیمات برنامه خوانده می‌شود
  final String calendar;

  @override
  State<ClosurePickerPage> createState() => _ClosurePickerPageState();
}

class _ClosurePickerPageState extends State<ClosurePickerPage> {
  late String _cal;
  int _off = 0;
  int _y = 0;
  int _m = 1;
  List<String> _days = <String>[];
  String _today = '';
  String? _a;
  String? _b;
  String _aLabel = '';
  String _bLabel = '';
  final _reason = TextEditingController();

  AppSettings get _st => widget.settings;
  String get _lang => _st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _cal = _resolveCal();
    _build();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _resolveCal() {
    final k = _st.calendarKey;
    if (k == 'jalali' || k == 'gregorian' || k == 'hijri') return k;
    return _lang == 'fa' ? 'jalali' : (_lang == 'ar' ? 'hijri' : 'gregorian');
  }

  String _iso(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  String _isoJdn(int jdn) {
    final g = _jdn2g(jdn);
    return _iso(g[0], g[1], g[2]);
  }

  List<int> _fromJdn(int jdn) {
    if (_cal == 'jalali') return _jdn2j(jdn);
    if (_cal == 'hijri') return _jdn2h(jdn);
    return _jdn2g(jdn);
  }

  int _toJdn(int y, int m, int d) {
    if (_cal == 'jalali') return _j2jdn(y, m, d);
    if (_cal == 'hijri') return _h2jdn(y, m, d);
    return _g2jdn(y, m, d);
  }

  void _build() {
    final now = DateTime.now();
    final t = _fromJdn(_g2jdn(now.year, now.month, now.day));
    final idx = t[0] * 12 + (t[1] - 1) + _off;
    final y = idx ~/ 12;
    final m = idx % 12 + 1;
    final start = _toJdn(y, m, 1);
    final ny = m == 12 ? y + 1 : y;
    final nm = m == 12 ? 1 : m + 1;
    final n = _toJdn(ny, nm, 1) - start;
    _y = y;
    _m = m;
    _days = [for (var i = 0; i < n; i++) _isoJdn(start + i)];
    _today = _iso(now.year, now.month, now.day);
  }

  void _go(int delta) {
    setState(() {
      _off += delta;
      _build();
    });
  }

  String _label(int day) =>
      '${localDigits(day, _lang)} ${calMonthName(_cal, _m, _lang)} ${localDigits(_y, _lang)}';

  void _tap(String iso, int day) {
    final label = _label(day);
    setState(() {
      if (_a == null || _b != null) {
        _a = iso;
        _aLabel = label;
        _b = null;
        _bLabel = '';
      } else if (iso.compareTo(_a!) < 0) {
        _b = _a;
        _bLabel = _aLabel;
        _a = iso;
        _aLabel = label;
      } else {
        _b = iso;
        _bLabel = label;
      }
    });
  }

  void _confirm() {
    if (_a == null) {
      toast(context, _t('pick'));
      return;
    }
    Navigator.of(context)
        .pop(ClosureResult(_a!, _b ?? _a!, _reason.text.trim()));
  }

  Widget _cell(BuildContext context, int day, String iso) {
    final cs = Theme.of(context).colorScheme;
    final past = iso.compareTo(_today) < 0;
    final sel = iso == _a || iso == _b;
    final inRange = _a != null &&
        _b != null &&
        iso.compareTo(_a!) > 0 &&
        iso.compareTo(_b!) < 0;
    Color? bg;
    if (sel) {
      bg = cs.primary;
    } else if (inRange) {
      bg = cs.primary.withOpacity(0.2);
    }
    Color? fg;
    if (sel) {
      fg = cs.onPrimary;
    } else if (past) {
      fg = muted(context).withOpacity(0.4);
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: past ? null : () => _tap(iso, day),
        child: Container(
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(
            localDigits(day, _lang),
            style:
                TextStyle(color: fg, fontWeight: sel ? FontWeight.bold : null),
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    if (_days.isEmpty) return const SizedBox.shrink();
    final startJs = _cal == 'gregorian' ? 1 : 6;
    final names = _wdNames[_lang] ?? _wdNames['fa']!;
    final order = [for (var i = 0; i < 7; i++) (startJs + i) % 7];
    final head = Row(
      children: [
        for (final w in order)
          Expanded(
            child: Center(
              child: Text(names[w],
                  style: TextStyle(color: muted(context), fontSize: 12)),
            ),
          ),
      ],
    );
    final first = DateTime.parse(_days.first);
    final blanks = ((first.weekday % 7) - startJs + 7) % 7;
    final cells = <Widget>[
      for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
      for (var i = 0; i < _days.length; i++) _cell(context, i + 1, _days[i]),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: [
          for (var j = 0; j < 7; j++)
            Expanded(child: AspectRatio(aspectRatio: 1, child: cells[i + j])),
        ],
      ));
    }
    return Column(children: [head, const SizedBox(height: 6), ...rows]);
  }

  @override
  Widget build(BuildContext context) {
    final title = _days.isEmpty
        ? ''
        : '${calMonthName(_cal, _m, _lang)} ${localDigits(_y, _lang)}';
    var summary = _t('pick');
    if (_a != null) {
      summary = '${_t('from')} $_aLabel';
      if (_b != null) summary += ' ${_t('to')} $_bLabel';
    }
    return GlassScaffold(
      title: _t('title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(_t('hint'), style: TextStyle(color: muted(context))),
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _off <= 0 ? null : () => _go(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _off >= 24 ? null : () => _go(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _grid(context),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(summary, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          GlassField(
            controller: _reason,
            label: _t('reason'),
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: _t('ok'),
            icon: Icons.check_rounded,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
