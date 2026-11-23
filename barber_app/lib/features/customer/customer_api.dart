import 'package:barber_core/barber_core.dart';
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
  CustomerApi(this.st);
  final AppSettings st;

  String get deviceId => st.deviceId;

  Future<Map<String, dynamic>> _call(String action,
      [Map<String, dynamic>? params]) async {
    final client = ApiClient(st.apiUrl);
    final dynamic r = await client.call(action, params ?? <String, dynamic>{});
    if (r is Map) return Map<String, dynamic>.from(r);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> shopSearch(String q) =>
      _call('shop_search', <String, dynamic>{'q': q});

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

  Future<Map<String, dynamic>> myBookings() =>
      _call('my_bookings', <String, dynamic>{'device_id': deviceId});

  Future<Map<String, dynamic>> cancel(String groupId) => _call(
      'customer_cancel',
      <String, dynamic>{'device_id': deviceId, 'group_id': groupId});

  Future<Map<String, dynamic>> checkin(String groupId) => _call(
      'customer_checkin',
      <String, dynamic>{'device_id': deviceId, 'group_id': groupId});

  Future<Map<String, dynamic>> rate(List<Map<String, dynamic>> ratings) =>
      _call('customer_rate',
          <String, dynamic>{'device_id': deviceId, 'ratings': ratings});
}
