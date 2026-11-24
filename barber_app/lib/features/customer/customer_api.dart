import 'package:barber_core/barber_core.dart';

import '../../app/registry.dart';
import '../../app/settings.dart';

bool cFlag(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = (v?.toString() ?? '').trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

double cDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v?.toString() ?? '').trim()) ?? 0;
}

class CustomerApi {
  CustomerApi(this.st, {String? baseUrl}) : _baseUrl = baseUrl;

  final AppSettings st;
  final String? _baseUrl;

  // هر نوبت مال کدام سرور است (برای لغو، حضور و امتیاز)
  static final Map<String, String> _gidUrl = <String, String>{};
  static final Map<String, String> _bidUrl = <String, String>{};

  String get deviceId => st.deviceId;
  String get _base =>
      (_baseUrl != null && _baseUrl!.trim().isNotEmpty) ? _baseUrl!.trim() : st.apiUrl;
  String get baseUrl => _base;

  Future<Map<String, dynamic>> _callAt(String url, String action,
      [Map<String, dynamic>? params]) async {
    final client = ApiClient(url);
    final dynamic r = await client.call(action, params ?? <String, dynamic>{});
    if (r is Map) return Map<String, dynamic>.from(r);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _call(String action,
          [Map<String, dynamic>? params]) =>
      _callAt(_base, action, params);

  /// بقیهٔ سرورها: خطا نادیده گرفته می‌شود
  Future<Map<String, dynamic>?> _safe(
      String url, String action, Map<String, dynamic> params) async {
    try {
      return await _callAt(url, action, params)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _rows(dynamic v) {
    if (v is! List) return <Map<String, dynamic>>[];
    return [
      for (final e in v)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  Future<Map<String, dynamic>> shopSearch(String q) async {
    final params = <String, dynamic>{'q': q};
    final urls = await ServerRegistry.forSearch(_base);
    if (urls.length <= 1) return _callAt(_base, 'shop_search', params);

    final others = <String, Future<Map<String, dynamic>?>>{
      for (final u in urls)
        if (u != _base) u: _safe(u, 'shop_search', params),
    };
    final r = await _callAt(_base, 'shop_search', params); // خطا به کاربر می‌رسد
    if (r['shops'] is! List) return r;
    final merged = _rows(r['shops']);
    for (final e in others.entries) {
      final o = await e.value;
      if (o == null) continue;
      for (final row in _rows(o['shops'])) {
        row['_server'] = e.key;
        merged.add(row);
      }
    }
    return <String, dynamic>{...r, 'shops': merged};
  }

  Future<Map<String, dynamic>> shopDetail(String shopId) =>
      _call('shop_detail', <String, dynamic>{'shop_id': shopId});

  Future<Map<String, dynamic>> slots({
    required String shopId,
    required String date,
    required List<String> serviceIds,
    required Map<String, String> staffChoice,
  }) =>
      _call('slots', <String, dynamic>{
        'shop_id': shopId,
        'date': date,
        'service_ids': serviceIds,
        'staff_choice': staffChoice,
      });

  Future<Map<String, dynamic>> book({
    required String shopId,
    required String name,
    required String phone,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    required Map<String, String> staffChoice,
  }) =>
      _call('book', <String, dynamic>{
        'shop_id': shopId,
        'device_id': deviceId,
        'customer_name': name,
        'customer_phone': phone,
        'date': date,
        'start_time': startTime,
        'service_ids': serviceIds,
        'staff_choice': staffChoice,
      });

  void _remember(String url, List<Map<String, dynamic>> rows) {
    for (final b in rows) {
      b['_server'] = url;
      final g = '${b['group_id'] ?? ''}';
      final id = '${b['booking_id'] ?? ''}';
      if (g.isNotEmpty) _gidUrl[g] = url;
      if (id.isNotEmpty) {
        _bidUrl[id] = url;
        _gidUrl.putIfAbsent(id, () => url);
      }
    }
  }

  Future<Map<String, dynamic>> myBookings() async {
    final params = <String, dynamic>{'device_id': deviceId};
    final urls = await ServerRegistry.forBookings(_base);
    final others = <String, Future<Map<String, dynamic>?>>{
      for (final u in urls)
        if (u != _base) u: _safe(u, 'my_bookings', params),
    };
    final r = await _callAt(_base, 'my_bookings', params);
    if (r['bookings'] is! List) return r;
    final merged = _rows(r['bookings']);
    _remember(_base, merged);
    for (final e in others.entries) {
      final o = await e.value;
      if (o == null) continue;
      final rows = _rows(o['bookings']);
      _remember(e.key, rows);
      merged.addAll(rows);
    }
    return <String, dynamic>{...r, 'bookings': merged};
  }

  Future<Map<String, dynamic>> cancel(String groupId) =>
      _callAt(_gidUrl[groupId] ?? _base, 'customer_cancel',
          <String, dynamic>{'device_id': deviceId, 'group_id': groupId});

  Future<Map<String, dynamic>> checkin(String groupId) =>
      _callAt(_gidUrl[groupId] ?? _base, 'customer_checkin',
          <String, dynamic>{'device_id': deviceId, 'group_id': groupId});

  Future<Map<String, dynamic>> rate(List<Map<String, dynamic>> ratings) async {
    final byUrl = <String, List<Map<String, dynamic>>>{};
    for (final r in ratings) {
      final u = _bidUrl['${r['booking_id']}'] ?? _base;
      (byUrl[u] ??= <Map<String, dynamic>>[]).add(r);
    }
    var last = <String, dynamic>{};
    for (final e in byUrl.entries) {
      last = await _callAt(e.key, 'customer_rate',
          <String, dynamic>{'device_id': deviceId, 'ratings': e.value});
    }
    return last;
  }
}
