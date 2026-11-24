// تبدیل تاریخ میلادی <-> شمسی <-> هجری قمری + قالب‌بندی
// این فایل به هیچ فایل دیگری از برنامه وابسته نیست.

enum CalKind { gregorian, jalali, hijri }

class CDate {
  final int y, m, d;
  const CDate(this.y, this.m, this.d);
  @override
  String toString() => '$y-$m-$d';
}

class CalConv {
  CalConv._();

  /// هجری قمری این‌جا محاسباتی (جدولی) است و ممکن است با رؤیت هلال تا ±۱ روز فرق کند.
  /// در صورت نیاز می‌توان این عدد را ۱- یا ۱ کرد.
  static int hijriOffset = 0;

  static CalKind autoKind(String lang) =>
      lang == 'fa' ? CalKind.jalali : (lang == 'ar' ? CalKind.hijri : CalKind.gregorian);

  /// key: auto | jalali | gregorian | hijri
  static CalKind kindOf(String key, String lang) {
    switch (key) {
      case 'jalali':
        return CalKind.jalali;
      case 'gregorian':
        return CalKind.gregorian;
      case 'hijri':
        return CalKind.hijri;
      default:
        return autoKind(lang);
    }
  }

  /// اولین روز هفته (DateTime.saturday=6 ، DateTime.sunday=7)
  static int firstWeekday(CalKind k, String lang) {
    if (k == CalKind.jalali || k == CalKind.hijri) return DateTime.saturday;
    return lang == 'ar' ? DateTime.saturday : DateTime.sunday;
  }

  // ---------------------------------------------------------------- Julian day
  static int _jdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
  }

  static CDate _fromJdn(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return CDate(year, month, day);
  }

  // ---------------------------------------------------------------- Hijri
  static CDate _hijriFromJdn(int jdn) {
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final m = (24 * l) ~/ 709;
    final d = l - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return CDate(y, m, d);
  }

  static int _jdnFromHijri(int y, int m, int d) =>
      d + (59 * (m - 1) + 1) ~/ 2 + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948439;

  // ---------------------------------------------------------------- Jalali
  static CDate _g2j(int gy, int gm, int gd) {
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return CDate(jy, jm, jd);
  }

  static CDate _j2g(int jy, int jm, int jd) {
    jy += 1595;
    var days = -355668 +
        (365 * jy) +
        ((jy ~/ 33) * 8) +
        (((jy % 33) + 3) ~/ 4) +
        jd +
        (jm < 7 ? (jm - 1) * 31 : ((jm - 7) * 30) + 186);
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
    final leap = (gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0);
    final sal = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var gm = 0;
    while (gm < 13 && gd > sal[gm]) {
      gd -= sal[gm];
      gm++;
    }
    return CDate(gy, gm, gd);
  }

  // ---------------------------------------------------------------- public API
  static CDate fromGregorian(int gy, int gm, int gd, CalKind k) {
    switch (k) {
      case CalKind.gregorian:
        return CDate(gy, gm, gd);
      case CalKind.jalali:
        return _g2j(gy, gm, gd);
      case CalKind.hijri:
        return _hijriFromJdn(_jdn(gy, gm, gd) + hijriOffset);
    }
  }

  static CDate fromDateTime(DateTime t, CalKind k) =>
      fromGregorian(t.year, t.month, t.day, k);

  static DateTime toGregorian(CDate c, CalKind k) {
    switch (k) {
      case CalKind.gregorian:
        return DateTime(c.y, c.m, c.d);
      case CalKind.jalali:
        final g = _j2g(c.y, c.m, c.d);
        return DateTime(g.y, g.m, g.d);
      case CalKind.hijri:
        final g = _fromJdn(_jdnFromHijri(c.y, c.m, c.d) - hijriOffset);
        return DateTime(g.y, g.m, g.d);
    }
  }

  /// تعداد روزهای یک ماه در تقویم انتخابی (برای انتخابگر تاریخ)
  static int monthLength(int y, int m, CalKind k) {
    if (k == CalKind.gregorian) return DateTime(y, m + 1, 0).day;
    final a = toGregorian(CDate(y, m, 1), k);
    final b = m == 12 ? toGregorian(CDate(y + 1, 1, 1), k) : toGregorian(CDate(y, m + 1, 1), k);
    return DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
  }

  // ---------------------------------------------------------------- names
  static const Map<String, List<String>> _gMon = {
    'fa': ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'],
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
  };
  static const Map<String, List<String>> _jMon = {
    'fa': ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'],
    'en': ['Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'],
    'ar': ['فروردين', 'أرديبهشت', 'خرداد', 'تير', 'مرداد', 'شهريور', 'مهر', 'آبان', 'آذر', 'دي', 'بهمن', 'إسفند'],
  };
  static const Map<String, List<String>> _hMon = {
    'fa': ['محرم', 'صفر', 'ربیع‌الاول', 'ربیع‌الثانی', 'جمادی‌الاول', 'جمادی‌الثانی', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذی‌قعده', 'ذی‌حجه'],
    'en': ['Muharram', 'Safar', 'Rabi I', 'Rabi II', 'Jumada I', 'Jumada II', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'],
    'ar': ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'],
  };
  // ایندکس = DateTime.weekday - 1  (دوشنبه ... یکشنبه)
  static const Map<String, List<String>> _wd = {
    'fa': ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'],
    'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    'ar': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  };

  static String _lg(String lang) => (lang == 'fa' || lang == 'ar') ? lang : 'en';

  static String monthName(CalKind k, int m, String lang) {
    final l = _lg(lang);
    final list = k == CalKind.jalali ? _jMon[l]! : (k == CalKind.hijri ? _hMon[l]! : _gMon[l]!);
    if (m < 1 || m > 12) return '$m';
    return list[m - 1];
  }

  static String weekdayName(int weekday, String lang) => _wd[_lg(lang)]![(weekday - 1) % 7];

  /// ارقام انگلیسی -> ارقام زبان (فارسی/عربی)
  static String digits(String s, String lang) {
    final base = lang == 'fa' ? 0x06F0 : (lang == 'ar' ? 0x0660 : 0);
    if (base == 0) return s;
    final sb = StringBuffer();
    for (final r in s.runes) {
      sb.writeCharCode(r >= 48 && r <= 57 ? base + (r - 48) : r);
    }
    return sb.toString();
  }

  // ---------------------------------------------------------------- format
  static DateTime? parseIso(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    return DateTime(y, mo, d);
  }

  static String _p2(int n) => n < 10 ? '0$n' : '$n';

  /// عددی: ۱۴۰۵/۰۹/۰۳  (میلادی: 2026-11-24)
  static String numeric(String iso, CalKind k, String lang) {
    final g = parseIso(iso);
    if (g == null) return iso;
    if (k == CalKind.gregorian) return digits(iso.substring(0, 10), lang);
    final c = fromDateTime(g, k);
    return digits('${c.y}/${_p2(c.m)}/${_p2(c.d)}', lang);
  }

  /// بلند: شنبه ۳ آذر ۱۴۰۵
  static String long(String iso, CalKind k, String lang, {bool weekday = true}) {
    final g = parseIso(iso);
    if (g == null) return iso;
    final c = fromDateTime(g, k);
    final s = '${weekday ? '${weekdayName(g.weekday, lang)} ' : ''}${c.d} ${monthName(k, c.m, lang)} ${c.y}';
    return digits(s, lang);
  }

  /// کوتاه بدون سال: ۳ آذر
  static String dayMonth(String iso, CalKind k, String lang) {
    final g = parseIso(iso);
    if (g == null) return iso;
    final c = fromDateTime(g, k);
    return digits('${c.d} ${monthName(k, c.m, lang)}', lang);
  }

  /// هر YYYY-MM-DD داخل یک متن را به تقویم انتخابی تبدیل می‌کند (برای میلادی دست نمی‌زند)
  static String convertText(String text, CalKind k, String lang) {
    if (k == CalKind.gregorian) return text;
    return text.replaceAllMapped(RegExp(r'(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)'), (m) {
      final mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return m.group(0)!;
      final c = fromGregorian(int.parse(m.group(1)!), mo, d, k);
      return '${c.y}/${_p2(c.m)}/${_p2(c.d)}';
    });
  }
}
