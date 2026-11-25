import 'fmt.dart';

class CalFmt {
  const CalFmt._();

  static String _byLang(String lang) =>
      lang == 'fa' ? 'jalali' : (lang == 'ar' ? 'hijri' : 'gregorian');

  /// نوع تقویم نهایی. در حالت «خودکار»: فارسی شمسی، عربی هجری، انگلیسی میلادی
  static String kind(String key, String lang) {
    final k = key.toLowerCase();
    if (k.isEmpty || k == 'auto') return _byLang(lang);
    if (k.contains('jal') ||
        k.contains('shams') ||
        k.contains('persian') ||
        k == 'fa') {
      return 'jalali';
    }
    if (k.contains('hij') ||
        k.contains('qamar') ||
        k.contains('islam') ||
        k == 'ar') {
      return 'hijri';
    }
    if (k.contains('greg') || k.contains('mil') || k == 'g' || k == 'en') {
      return 'gregorian';
    }
    return _byLang(lang);
  }

  static List<int> _jalali(int gy, int gm, int gd) {
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
    final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
    return [jy, jm, jd];
  }

  static List<int> _hijri(int gy, int gm, int gd) {
    final a = (14 - gm) ~/ 12;
    final y = gy + 4800 - a;
    final m = gm + 12 * a - 3;
    final jdn = gd +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final hm = (24 * l) ~/ 709;
    final hd = l - (709 * hm) ~/ 24;
    final hy = 30 * n + j - 30;
    return [hy, hm, hd];
  }

  static String _two(int v) => v < 10 ? '0$v' : '$v';

  /// [سال، ماه، روز] در تقویم انتخابی. اگر ورودی درست نباشد null
  static List<int>? ymd(String? iso, String calendarKey, String lang) {
    if (iso == null || iso.trim().isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso.trim());
    if (m == null) return null;
    final gy = int.parse(m.group(1)!);
    final gm = int.parse(m.group(2)!);
    final gd = int.parse(m.group(3)!);
    if (gm < 1 || gm > 12 || gd < 1 || gd > 31) return null;
    final k = kind(calendarKey, lang);
    if (k == 'jalali') return _jalali(gy, gm, gd);
    if (k == 'hijri') return _hijri(gy, gm, gd);
    return [gy, gm, gd];
  }

  static String date(String? iso, String calendarKey, String lang) {
    if (iso == null || iso.trim().isEmpty) return '—';
    final p = ymd(iso, calendarKey, lang);
    if (p == null) return localDigits(iso.trim(), lang);
    final text = '${p[0]}/${_two(p[1])}/${_two(p[2])}';
    return localDigits(text, lang);
  }
}
