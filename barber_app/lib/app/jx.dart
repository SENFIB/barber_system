Map<String, dynamic> mapOf(dynamic d) =>
    d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

List<Map<String, dynamic>> listOf(dynamic d) => d is List
    ? [
        for (final e in d)
          if (e is Map) Map<String, dynamic>.from(e)
      ]
    : <Map<String, dynamic>>[];

String strOf(dynamic v) => v == null ? '' : '$v';

int intOf(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

List<String> strList(dynamic d) =>
    d is List ? [for (final e in d) '$e'] : <String>[];

bool boolOf(dynamic v) => v == true || '$v'.toLowerCase() == 'true';

String money(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
