enum CalKind { jalali, gregorian, hijri }

class YMD {
  const YMD(this.y, this.m, this.d);
  final int y, m, d;
}

CalKind defaultCal(String lang) => lang == 'en'
    ? CalKind.gregorian
    : (lang == 'ar' ? CalKind.hijri : CalKind.jalali);

CalKind calFrom(String? s, String lang) {
  switch (s) {
    case 'jalali':
      return CalKind.jalali;
    case 'gregorian':
      return CalKind.gregorian;
    case 'hijri':
      return CalKind.hijri;
    default:
      return defaultCal(lang);
  }
}

int _li(String lang) => lang == 'en' ? 1 : (lang == 'ar' ? 2 : 0);

// ───────── تاریخ ISO (میلادی، UTC) ─────────
DateTime parseIso(String s) {
  final p = s.split('-');
  if (p.length != 3) return DateTime.utc(1970);
  return DateTime.utc(int.tryParse(p[0]) ?? 1970, int.tryParse(p[1]) ?? 1,
      int.tryParse(p[2]) ?? 1);
}

String isoOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayIso() {
  final n = DateTime.now();
  return isoOf(DateTime.utc(n.year, n.month, n.day));
}

String addDaysIso(String iso, int n) =>
    isoOf(parseIso(iso).add(Duration(days: n)));

// ───────── شمسی ─────────
YMD _g2j(int gy, int gm, int gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
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
  int jm, jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return YMD(jy, jm, jd);
}

DateTime _j2g(int jy0, int jm, int jd) {
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
  final sa = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var gm = 0;
  while (gm < 13 && gd > sa[gm]) {
    gd -= sa[gm];
    gm++;
  }
  return DateTime.utc(gy, gm, gd);
}

// ───────── قمری (محاسباتی، ممکن است تا یک روز با تقویم رسمی فرق کند) ─────────
int _jdnOf(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970)).inDays +
    2440588;

int _h2jdn(int y, int m, int d) =>
    d + (29.5 * (m - 1)).ceil() + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948439;

YMD _jdn2h(int jdn) {
  final y = (30 * (jdn - 1948440) + 10646) ~/ 10631;
  var m = ((jdn - (29 + _h2jdn(y, 1, 1))) / 29.5).ceil() + 1;
  if (m > 12) m = 12;
  if (m < 1) m = 1;
  return YMD(y, m, jdn - _h2jdn(y, m, 1) + 1);
}

YMD toCal(DateTime g, CalKind k) {
  if (k == CalKind.gregorian) return YMD(g.year, g.month, g.day);
  if (k == CalKind.jalali) return _g2j(g.year, g.month, g.day);
  return _jdn2h(_jdnOf(g));
}

DateTime fromCal(YMD v, CalKind k) {
  if (k == CalKind.gregorian) return DateTime.utc(v.y, v.m, v.d);
  if (k == CalKind.jalali) return _j2g(v.y, v.m, v.d);
  return DateTime.utc(1970)
      .add(Duration(days: _h2jdn(v.y, v.m, v.d) - 2440588));
}

int daysInMonth(CalKind k, int y, int m) {
  for (var d = 31; d >= 29; d--) {
    final b = toCal(fromCal(YMD(y, m, d), k), k);
    if (b.y == y && b.m == m && b.d == d) return d;
  }
  return 28;
}

int weekStart(CalKind k) => k == CalKind.gregorian ? 0 : 6; // 0=یکشنبه … 6=شنبه

// ───────── نام‌ها ─────────
const _months = <CalKind, List<List<String>>>{
  CalKind.jalali: [
    ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'],
    ['Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'],
    ['فروردين', 'أرديبهشت', 'خرداد', 'تير', 'مرداد', 'شهريور', 'مهر', 'آبان', 'آذر', 'دي', 'بهمن', 'إسفند'],
  ],
  CalKind.gregorian: [
    ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'],
    ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
  ],
  CalKind.hijri: [
    ['محرم', 'صفر', 'ربیع‌الاول', 'ربیع‌الثانی', 'جمادی‌الاول', 'جمادی‌الثانی', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذی‌القعده', 'ذی‌الحجه'],
    ['Muharram', 'Safar', 'Rabi I', 'Rabi II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah'],
    ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'],
  ],
};

const _wdFull = [
  ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'],
  ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
];

const _wdShort = [
  ['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'],
  ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
];

String monthName(CalKind k, int m, String lang) {
  final i = m < 1 ? 0 : (m > 12 ? 11 : m - 1);
  return _months[k]![_li(lang)][i];
}

/// sundayIdx: 0=یکشنبه … 6=شنبه (همان قرارداد سرور)
String weekdayName(int sundayIdx, String lang) =>
    _wdFull[_li(lang)][sundayIdx % 7];

String weekdayShort(int sundayIdx, String lang) =>
    _wdShort[_li(lang)][sundayIdx % 7];

String localDigits(String s, String lang) {
  if (lang == 'en') return s;
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final t = lang == 'fa' ? fa : ar;
  final b = StringBuffer();
  for (final c in s.runes) {
    if (c >= 48 && c <= 57) {
      b.write(t[c - 48]);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}

String fmtDate(String iso, CalKind k, String lang,
    {bool weekday = false, bool year = true}) {
  final g = parseIso(iso);
  final v = toCal(g, k);
  var s = '${localDigits('${v.d}', lang)} ${monthName(k, v.m, lang)}';
  if (year) s += ' ${localDigits('${v.y}', lang)}';
  if (weekday) {
    s = '${weekdayName(g.weekday % 7, lang)}${lang == 'en' ? ', ' : '، '}$s';
  }
  return s;
}

String fmtTime(String t, String lang) => localDigits(t, lang);
