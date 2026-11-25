import 'package:flutter/material.dart';

String resolveCalKind(String key, String lang) {
  if (key == 'jalali' || key == 'hijri' || key == 'gregorian') return key;
  if (lang == 'fa') return 'jalali';
  if (lang == 'ar') return 'hijri';
  return 'gregorian';
}

int _gToJdn(int y, int m, int d) {
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

List<int> _jdnToG(int j) {
  final a = j + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  final day = e - (153 * m + 2) ~/ 5 + 1;
  final month = m + 3 - 12 * (m ~/ 10);
  final year = 100 * b + d - 4800 + m ~/ 10;
  return <int>[year, month, day];
}

List<int> _g2j(int gy, int gm, int gd) {
  const gdm = <int>[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days = 355666 +
      365 * gy +
      (gy2 + 3) ~/ 4 -
      (gy2 + 99) ~/ 100 +
      (gy2 + 399) ~/ 400 +
      gd +
      gdm[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  int jm;
  int jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return <int>[jy, jm, jd];
}

List<int> _j2g(int jy0, int jm, int jd) {
  final jy = jy0 + 1595;
  var days = -355668 +
      365 * jy +
      (jy ~/ 33) * 8 +
      ((jy % 33) + 3) ~/ 4 +
      jd +
      (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
  var gy = 400 * (days ~/ 146097);
  days %= 146097;
  if (days > 36524) {
    days -= 1;
    gy += 100 * (days ~/ 36524);
    days %= 36524;
    if (days >= 365) days += 1;
  }
  gy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    gy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  var gd = days + 1;
  final leap = (gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0;
  final sal = <int>[0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var gm = 0;
  while (gm < 13 && gd > sal[gm]) {
    gd -= sal[gm];
    gm++;
  }
  return <int>[gy, gm, gd];
}

int _hToJdn(int y, int m, int d) {
  return d + (29.5 * (m - 1)).ceil() + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948439;
}

List<int> _jdnToH(int jd) {
  final y = (30 * (jd - 1948440) + 10646) ~/ 10631;
  var m = ((jd - (29 + _hToJdn(y, 1, 1))) / 29.5).ceil() + 1;
  if (m > 12) m = 12;
  if (m < 1) m = 1;
  final d = jd - _hToJdn(y, m, 1) + 1;
  return <int>[y, m, d];
}

int _toJdn(String k, int y, int m, int d) {
  if (k == 'jalali') {
    final g = _j2g(y, m, d);
    return _gToJdn(g[0], g[1], g[2]);
  }
  if (k == 'hijri') return _hToJdn(y, m, d);
  return _gToJdn(y, m, d);
}

List<int> _fromJdn(String k, int j) {
  if (k == 'jalali') {
    final g = _jdnToG(j);
    return _g2j(g[0], g[1], g[2]);
  }
  if (k == 'hijri') return _jdnToH(j);
  return _jdnToG(j);
}

int _monthLen(String k, int y, int m) {
  final ny = m == 12 ? y + 1 : y;
  final nm = m == 12 ? 1 : m + 1;
  return _toJdn(k, ny, nm, 1) - _toJdn(k, y, m, 1);
}

String _dg(String s, String lang) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  if (lang != 'fa' && lang != 'ar') return s;
  final map = lang == 'fa' ? fa : ar;
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 48 && r <= 57) {
      sb.write(map[r - 48]);
    } else {
      sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

const _monthsG = <String, List<String>>{
  'fa': ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'],
  'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
};
const _monthsJ = <String, List<String>>{
  'fa': ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'],
  'en': ['Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'],
  'ar': ['فروردين', 'أرديبهشت', 'خرداد', 'تير', 'مرداد', 'شهريور', 'مهر', 'آبان', 'آذر', 'دي', 'بهمن', 'إسفند'],
};
const _monthsH = <String, List<String>>{
  'fa': ['محرم', 'صفر', 'ربیع‌الاول', 'ربیع‌الثانی', 'جمادی‌الاول', 'جمادی‌الثانی', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذیقعده', 'ذیحجه'],
  'en': ['Muharram', 'Safar', 'Rabi I', 'Rabi II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah'],
  'ar': ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'],
};

String _monthName(String k, int m, String lang) {
  final l = (lang == 'fa' || lang == 'ar') ? lang : 'en';
  final t = k == 'jalali' ? _monthsJ : (k == 'hijri' ? _monthsH : _monthsG);
  return t[l]![(m - 1).clamp(0, 11)];
}

// weekday: 1=Mon ... 7=Sun
const _wdLabels = <String, List<String>>{
  'fa': ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'],
  'en': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  'ar': ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
};

/// Formats a date as y/m/d in the chosen calendar, with local digits.
String fmtPickDate(DateTime d, String calKey, String lang) {
  final k = resolveCalKind(calKey, lang);
  final p = _fromJdn(k, _gToJdn(d.year, d.month, d.day));
  String two(int n) => n < 10 ? '0$n' : '$n';
  final sep = k == 'gregorian' ? '-' : '/';
  return _dg('${p[0]}$sep${two(p[1])}$sep${two(p[2])}', lang);
}

/// Same as [fmtPickDate] but takes a Gregorian ISO string (yyyy-MM-dd).
String fmtPickIso(String iso, String calKey, String lang) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return fmtPickDate(d, calKey, lang);
}

Future<DateTime?> pickLocalDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  required String calKey,
  required String lang,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _CalDialog(
      initial: initial,
      first: first,
      last: last,
      kind: resolveCalKind(calKey, lang),
      lang: lang,
    ),
  );
}

class _CalDialog extends StatefulWidget {
  const _CalDialog({
    required this.initial,
    required this.first,
    required this.last,
    required this.kind,
    required this.lang,
  });
  final DateTime initial;
  final DateTime first;
  final DateTime last;
  final String kind;
  final String lang;

  @override
  State<_CalDialog> createState() => _CalDialogState();
}

class _CalDialogState extends State<_CalDialog> {
  late int _y;
  late int _m;
  late int _selJdn;
  late int _minJdn;
  late int _maxJdn;
  late int _todayJdn;

  @override
  void initState() {
    super.initState();
    int j(DateTime d) => _gToJdn(d.year, d.month, d.day);
    _selJdn = j(widget.initial);
    _minJdn = j(widget.first);
    _maxJdn = j(widget.last);
    _todayJdn = j(DateTime.now());
    final p = _fromJdn(widget.kind, _selJdn);
    _y = p[0];
    _m = p[1];
  }

  void _shift(int delta) {
    setState(() {
      _m += delta;
      if (_m > 12) {
        _m = 1;
        _y++;
      } else if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  String get _cancel =>
      widget.lang == 'fa' ? 'انصراف' : (widget.lang == 'ar' ? 'إلغاء' : 'Cancel');
  String get _today =>
      widget.lang == 'fa' ? 'امروز' : (widget.lang == 'ar' ? 'اليوم' : 'Today');

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final lang = widget.lang;
    final cs = Theme.of(context).colorScheme;
    final satFirst = k != 'gregorian';
    final firstJdn = _toJdn(k, _y, _m, 1);
    final len = _monthLen(k, _y, _m);
    final wd = firstJdn % 7 + 1;
    final offset = satFirst ? (wd % 7 + 1) % 7 : wd % 7;
    final labels = _wdLabels[(lang == 'fa' || lang == 'ar') ? lang : 'en']!;

    final cells = <int?>[];
    for (var i = 0; i < offset; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= len; d++) {
      cells.add(d);
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    Widget head() {
      final row = <Widget>[];
      for (var c = 0; c < 7; c++) {
        final w = satFirst ? (c + 5) % 7 + 1 : (c + 6) % 7 + 1;
        final red = w == 5 && (lang == 'fa' || lang == 'ar');
        row.add(Expanded(
          child: Center(
            child: Text(
              labels[w - 1],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: red ? Colors.red : null,
              ),
            ),
          ),
        ));
      }
      return Row(children: row);
    }

    final rows = <Widget>[];
    for (var r = 0; r < cells.length ~/ 7; r++) {
      final row = <Widget>[];
      for (var c = 0; c < 7; c++) {
        final d = cells[r * 7 + c];
        if (d == null) {
          row.add(const Expanded(child: SizedBox(height: 40)));
          continue;
        }
        final jdn = firstJdn + d - 1;
        final enabled = jdn >= _minJdn && jdn <= _maxJdn;
        final sel = jdn == _selJdn;
        final isToday = jdn == _todayJdn;
        final w = jdn % 7 + 1;
        final red = w == 5 && (lang == 'fa' || lang == 'ar');
        row.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled
                  ? () {
                      final g = _jdnToG(jdn);
                      Navigator.of(context).pop(DateTime(g[0], g[1], g[2]));
                    }
                  : null,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? cs.primary : null,
                  border: isToday && !sel
                      ? Border.all(color: cs.primary, width: 1.4)
                      : null,
                ),
                child: Text(
                  _dg('$d', lang),
                  style: TextStyle(
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    color: sel
                        ? cs.onPrimary
                        : (!enabled
                            ? Colors.grey.withOpacity(0.5)
                            : (red ? Colors.red : null)),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      rows.add(Row(children: row));
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_monthName(k, _m, lang)} ${_dg('$_y', lang)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: () => _shift(1),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              head(),
              const SizedBox(height: 4),
              ...rows,
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final p = _fromJdn(k, _todayJdn);
                      setState(() {
                        _y = p[0];
                        _m = p[1];
                      });
                    },
                    child: Text(_today),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
