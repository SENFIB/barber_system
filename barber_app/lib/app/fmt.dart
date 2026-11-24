import 'cal_conv.dart';

/// زبانِ اعداد (main.dart آن را با زبان برنامه هماهنگ نگه می‌دارد)
String kDigitsLang = 'fa';

/// تقویمِ نمایش (main.dart از انتخاب هدر/زبان تنظیمش می‌کند).
/// هر تاریخ YYYY-MM-DD که از localDigits رد شود، به این تقویم تبدیل می‌شود.
CalKind kCalKind = CalKind.gregorian;

/// ارقام انگلیسی را به رقم‌های زبان تبدیل می‌کند و تاریخ‌ها را به تقویم انتخابی می‌برد.
/// fa → ۰۱۲۳۴۵۶۷۸۹ ، ar → ٠١٢٣٤٥٦٧٨٩ ، en → بدون تغییر
String localDigits(String s, [String? lang]) {
  final l = lang ?? kDigitsLang;
  var t = s;
  if (kCalKind != CalKind.gregorian && t.length >= 10) {
    t = CalConv.convertText(t, kCalKind, l);
  }
  if (l == 'en') return t;
  final base = l == 'ar' ? 0x0660 : 0x06F0;
  final b = StringBuffer();
  for (final r in t.runes) {
    if (r >= 0x30 && r <= 0x39) {
      b.writeCharCode(base + (r - 0x30));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// عدد با جداکننده‌ی هزارگانِ کامای معمولی (روی خط) و رقم‌های زبان:
/// 1250000 → 1,250,000 / ۱,۲۵۰,۰۰۰
String fmtNum(num n, [String? lang]) {
  final l = lang ?? kDigitsLang;
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return localDigits((n < 0 ? '-' : '') + b.toString(), l);
}
