import 'package:barber_core/barber_core.dart';

import '../../app/settings.dart';

/// صدا زدن اکشن‌های بخش آرایشگاه. device_id و توکن خودکار اضافه می‌شوند.
class ShopApi {
  ShopApi(this.settings);

  final AppSettings settings;

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> params = const {},
  ]) async {
    final client =
        ApiClient(baseUrl: settings.apiUrl, token: settings.shopToken);
    final data = await client.call(action, {
      'device_id': settings.deviceId,
      ...params,
    });
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<ManagerSession> register({
    required String licenseKey,
    required String shopName,
    required String phone,
    required String username,
    required String password,
    String city = '',
    String ownerName = '',
    bool ownerIsBarber = true,
  }) async {
    final d = await _call('register_shop', {
      'license_key': licenseKey.trim(),
      'shop_name': shopName.trim(),
      'phone': phone.trim(),
      'username': username.trim(),
      'password': password,
      'city': city.trim(),
      'owner_name': ownerName.trim(),
      'owner_is_barber': ownerIsBarber,
      'language': settings.lang,
    });
    return ManagerSession.fromJson(d);
  }

  Future<ManagerSession> login(String username, String password) async {
    final d = await _call('login', {
      'username': username.trim(),
      'password': password,
    });
    return ManagerSession.fromJson(d);
  }

  Future<ManagerSession> join({
    required String inviteCode,
    required String username,
    required String password,
  }) async {
    final d = await _call('join_with_invite', {
      'invite_code': inviteCode.trim(),
      'username': username.trim(),
      'password': password,
    });
    return ManagerSession.fromJson(d);
  }

  Future<ManagerSession> me() async {
    final d = await _call('me');
    return ManagerSession.fromJson(d, token: settings.shopToken);
  }

  Future<void> renew(String licenseKey) async {
    await _call('renew', {'license_key': licenseKey.trim()});
  }

  Future<void> logout() async {
    await _call('logout').timeout(const Duration(seconds: 8));
  }
}
