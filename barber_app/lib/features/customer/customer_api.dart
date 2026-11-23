import 'package:barber_core/barber_core.dart';
import '../../app/jx.dart';
import '../../app/settings.dart';

class CustomerApi {
  CustomerApi(this.settings);
  final AppSettings settings;

  ApiClient get _c => ApiClient(settings.apiUrl);
  String get _dev => settings.deviceId;

  Future<List<Map<String, dynamic>>> search(String q) async =>
      listOf(mapOf(await _c.call('shop_search', {'q': q}))['shops']);

  Future<Map<String, dynamic>> detail(String id) async =>
      mapOf(await _c.call('shop_detail', {'shop_id': id}));

  Future<Map<String, dynamic>> slots(String shopId, String date,
          List<String> services, Map<String, String> choice) async =>
      mapOf(await _c.call('slots', {
        'shop_id': shopId,
        'date': date,
        'service_ids': services,
        'staff_choice': choice,
      }));

  Future<Map<String, dynamic>> book({
    required String shopId,
    required String name,
    required String phone,
    required String date,
    required String start,
    required List<String> services,
    required Map<String, String> choice,
  }) async =>
      mapOf(await _c.call('book', {
        'shop_id': shopId,
        'device_id': _dev,
        'customer_name': name,
        'customer_phone': phone,
        'date': date,
        'start_time': start,
        'service_ids': services,
        'staff_choice': choice,
      }));

  Future<List<Map<String, dynamic>>> myBookings() async => listOf(mapOf(
      await _c.call('my_bookings', {'device_id': _dev}))['bookings']);

  Future<void> cancel(String groupId) async {
    await _c.call('customer_cancel', {'device_id': _dev, 'group_id': groupId});
  }

  Future<void> checkin(String groupId) async {
    await _c.call('customer_checkin', {'device_id': _dev, 'group_id': groupId});
  }

  Future<void> rate(List<Map<String, dynamic>> ratings) async {
    await _c.call('customer_rate', {'device_id': _dev, 'ratings': ratings});
  }
}
