import 'package:barber_core/barber_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// آدرس فهرست سرورها. خالی = خاموش (فقط سرور اصلی).
const String kRegistryUrl = 'https://script.google.com/macros/s/AKfycbxR0G1ac1CUmUXhwsCQZhvDM8tLpLBrDPtzSpuuWDNOswoInekG6WZN3DpvfhcyUV4Z/exec';

const String _kSaved = 'cust_servers';

/// فهرست سرورهایی که مشتری باید در آن‌ها دنبال آرایشگاه و نوبت بگردد.
class ServerRegistry {
  static List<String> _cache = <String>[];
  static DateTime? _at;

  static List<String> _unique(Iterable<String> src) {
    final out = <String>[];
    for (final s in src) {
      final u = s.trim();
      if (u.isEmpty || !u.startsWith('https://')) continue;
      if (!out.contains(u)) out.add(u);
    }
    return out;
  }

  /// سرورهای فهرست (۱۰ دقیقه در حافظه نگه داشته می‌شود)
  static Future<List<String>> remote() async {
    if (kRegistryUrl.trim().isEmpty) return <String>[];
    final now = DateTime.now();
    if (_at != null &&
        _cache.isNotEmpty &&
        now.difference(_at!).inMinutes < 10) {
      return _cache;
    }
    try {
      final dynamic d = await ApiClient(kRegistryUrl.trim())
          .call('registry_list', <String, dynamic>{})
          .timeout(const Duration(seconds: 12));
      final out = <String>[];
      if (d is Map && d['servers'] is List) {
        for (final e in (d['servers'] as List)) {
          out.add('$e');
        }
      }
      _cache = _unique(out);
      _at = now;
      return _cache;
    } catch (_) {
      return _cache;
    }
  }

  /// سرورهایی که مشتری قبلاً در آن‌ها نوبت گرفته
  static Future<List<String>> saved() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getStringList(_kSaved) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> remember(String url) async {
    try {
      final u = url.trim();
      if (u.isEmpty) return;
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_kSaved) ?? <String>[];
      if (!list.contains(u)) {
        list.add(u);
        while (list.length > 20) {
          list.removeAt(0);
        }
        await p.setStringList(_kSaved, list);
      }
    } catch (_) {}
  }

  /// برای جستجوی آرایشگاه‌ها
  static Future<List<String>> forSearch(String current) async =>
      _unique(<String>[current, kDefaultApiUrl, ...await remote()]);

  /// برای «نوبت‌های من»
  static Future<List<String>> forBookings(String current) async =>
      _unique(<String>[current, kDefaultApiUrl, ...await saved()]);
}
