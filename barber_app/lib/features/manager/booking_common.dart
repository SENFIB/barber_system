import 'package:flutter/material.dart';

String bStr(dynamic v) => v == null ? '' : v.toString();

int bInt(dynamic v, [int d = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(bStr(v).trim()) ?? d;
}

List<Map<String, dynamic>> bRows(dynamic v) {
  if (v is! List) return <Map<String, dynamic>>[];
  final out = <Map<String, dynamic>>[];
  for (final e in v) {
    if (e is Map) out.add(Map<String, dynamic>.from(e));
  }
  return out;
}

List<Map<String, dynamic>> bFirstList(Map r, List<String> prefer) {
  for (final k in prefer) {
    if (r[k] is List) return bRows(r[k]);
  }
  for (final v in r.values) {
    if (v is List) return bRows(v);
  }
  return <Map<String, dynamic>>[];
}

List<String> bIds(dynamic v) {
  if (v is List) {
    return v.map((e) => bStr(e).trim()).where((e) => e.isNotEmpty).toList();
  }
  final s = bStr(v);
  if (s.trim().isEmpty) return <String>[];
  return s
      .split(RegExp(r'[,|;\s]+'))
      .where((e) => e.trim().isNotEmpty)
      .toList();
}

String _p2(int n) => n.toString().padLeft(2, '0');

String bIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_p2(d.month)}-${_p2(d.day)}';

DateTime? bParse(String s) {
  final p = s.split('-');
  if (p.length < 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final dd = p[2].length >= 2 ? p[2].substring(0, 2) : p[2];
  final d = int.tryParse(dd);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

int bMin(String hhmm) {
  final p = hhmm.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

String bTime(TimeOfDay t) => '${_p2(t.hour)}:${_p2(t.minute)}';

String bDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    var i = fa.indexOf(ch);
    if (i < 0) i = ar.indexOf(ch);
    sb.write(i >= 0 ? '$i' : ch);
  }
  return sb.toString().trim();
}

void bSnack(BuildContext context, String msg) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(msg)));
}
