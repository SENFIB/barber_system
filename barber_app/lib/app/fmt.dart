/// زبانِ اعداد (main.dart آن را با زبان برنامه هماهنگ نگه می‌دارد)
String kDigitsLang = 'fa';

/// ارقام انگلیسی را به رقم‌های زبان تبدیل می‌کند.
/// fa → ۰۱۲۳۴۵۶۷۸۹ ، ar → ٠١٢٣٤٥٦٧٨٩ ، en → بدون تغییر
String localDigits(String s, [String? lang]) {
  final l = lang ?? kDigitsLang;
  if (l == 'en') return s;
  final base = l == 'ar' ? 0x0660 : 0x06F0;
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x30 && r <= 0x39) {
      b.writeCharCode(base + (r - 0x30));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// عدد با جداکننده‌ی هزارگان و رقم‌های زبان: 1250000 → 1,250,000 / ۱٬۲۵۰٬۰۰۰
String fmtNum(num n, [String? lang]) {
  final l = lang ?? kDigitsLang;
  final s = n.round().abs().toString();
  final sep = l == 'en' ? ',' : '٬';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(sep);
    b.write(s[i]);
  }
  return localDigits((n < 0 ? '-' : '') + b.toString(), l);
}
