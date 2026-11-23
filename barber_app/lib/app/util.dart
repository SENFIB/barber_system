import 'dart:convert';

/// ارقام فارسی و عربی را به انگلیسی تبدیل می‌کند.
String normalizeDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    var i = fa.indexOf(ch);
    if (i < 0) i = ar.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return b.toString();
}

String normalizeUsername(String s) {
  var t = normalizeDigits(s.trim());
  t = t.replaceAll('ي', 'ی').replaceAll('ى', 'ی').replaceAll('ك', 'ک');
  return t.toLowerCase();
}

/// نام کاربری: ۳ تا ۳۰ حرف، هر زبانی، بدون فاصله.
bool usernameOk(String raw) {
  final t = normalizeUsername(raw);
  final n = t.runes.length;
  if (n < 3 || n > 30) return false;
  return !RegExp(r'[\s\u0000-\u001F]').hasMatch(t);
}

final RegExp _plainName = RegExp(r'^[a-z0-9_.]{4,30}$');

/// سرور فقط a-z 0-9 _ . قبول می‌کند. اگر نام کاربری ساده بود همان را می‌فرستیم،
/// وگرنه یک شناسه‌ی ثابت و یکتا از روی آن می‌سازیم (همیشه برای یک نام، همان نتیجه).
String encodeUsername(String raw) {
  final t = normalizeUsername(raw);
  if (_plainName.hasMatch(t)) return t;
  return 'u_${_hash28(t)}';
}

String _hash28(String s) {
  var h1 = (0xcbf29ce4 << 32) | 0x84222325;
  var h2 = (0x9e3779b9 << 32) | 0x7f4a7c15;
  final bytes = utf8.encode(s);
  for (var i = 0; i < bytes.length; i++) {
    h1 = (h1 ^ bytes[i]) * 0x100000001b3;
    h2 = (h2 ^ (bytes[i] + 31 * (i + 1))) * 0x5bd1e995;
    h2 = h2 ^ (h2 >>> 29);
  }
  return _hex(h1, 16) + _hex(h2, 12);
}

String _hex(int v, int digits) {
  const d = '0123456789abcdef';
  final b = StringBuffer();
  for (var i = digits - 1; i >= 0; i--) {
    b.write(d[(v >>> (i * 4)) & 0xF]);
  }
  return b.toString();
}
