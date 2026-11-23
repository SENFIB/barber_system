import 'package:barber_core/barber_core.dart';

import '../../app/settings.dart';
import '../../app/util.dart';

/// هرچه صفحه‌های آرایشگاه لازم دارند در یک بسته
class ShopCtx {
  ShopCtx({
    required this.api,
    required this.session,
    required this.reload,
    required this.logout,
  });

  final ShopApi api;
  final ManagerSession session;
  final Future<void> Function() reload;
  final Future<void> Function() logout;
}

class ShopApi {
  ShopApi(this.settings);
  final AppSettings settings;

  ApiClient get _client => ApiClient(settings.apiUrl);

  Future<dynamic> _open(String action, Map<String, dynamic> p) =>
      _client.call(action, p);

  Future<dynamic> _auth(String action, [Map<String, dynamic>? p]) =>
      _client.call(action, {
        ...?p,
        'token': settings.shopToken ?? '',
        'device_id': settings.deviceId,
      });

  Map<String, dynamic> _map(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  ManagerSession _session(dynamic d, {String? token}) =>
      ManagerSession.fromJson(_map(d), token: token);

  // ── بدون ورود ──
  Future<ManagerSession> register({
    required String licenseKey,
    required String shopName,
    required String phone,
    required String username,
    required String password,
    String address = '',
    String city = '',
    String ownerName = '',
    String specialty = '',
    required bool ownerIsBarber,
  }) async {
    final p = <String, dynamic>{
      'license_key': licenseKey.trim().toUpperCase(),
      'shop_name': shopName.trim(),
      'phone': normalizeDigits(phone).replaceAll(RegExp(r'[^0-9+]'), ''),
      'username': encodeUsername(username),
      'password': password,
      'device_id': settings.deviceId,
      'owner_is_barber': ownerIsBarber,
    };
    if (address.trim().isNotEmpty) p['address'] = address.trim();
    if (city.trim().isNotEmpty) p['city'] = city.trim();
    if (ownerName.trim().isNotEmpty) p['owner_name'] = ownerName.trim();
    if (specialty.trim().isNotEmpty) p['specialty'] = specialty.trim();
    return _session(await _open('register_shop', p));
  }

  Future<ManagerSession> login(String username, String password) async {
    return _session(await _open('login', {
      'username': encodeUsername(username),
      'password': password,
      'device_id': settings.deviceId,
    }));
  }

  Future<ManagerSession> join(
      String inviteCode, String username, String password) async {
    return _session(await _open('join_with_invite', {
      'invite_code': inviteCode.trim().toUpperCase(),
      'username': encodeUsername(username),
      'password': password,
      'device_id': settings.deviceId,
    }));
  }

  // ── با ورود ──
  Future<ManagerSession> me() async =>
      _session(await _auth('me'), token: settings.shopToken);

  Future<void> renew(String licenseKey) async {
    await _auth('renew', {'license_key': licenseKey.trim().toUpperCase()});
  }

  Future<void> logout() async {
    await _auth('logout');
  }

  Future<Map<String, dynamic>> staffList() async =>
      _map(await _auth('staff_list'));

  Future<void> staffAdd({
    required String name,
    String specialty = '',
    required String workStart,
    required String workEnd,
  }) async {
    await _auth('staff_add', {
      'name': name.trim(),
      'specialty': specialty.trim(),
      'work_start': workStart,
      'work_end': workEnd,
    });
  }

  Future<void> staffRemove(String staffId) async {
    await _auth('staff_remove', {'staff_id': staffId});
  }

  Future<void> ownerBarber({
    required bool enabled,
    String name = '',
    String specialty = '',
  }) async {
    await _auth('owner_barber', {
      'enabled': enabled,
      'name': name.trim(),
      'specialty': specialty.trim(),
    });
  }

  Future<void> inviteCreate(String staffId) async {
    await _auth('invite_create', {'staff_id': staffId});
  }

  Future<void> inviteRevoke(String code) async {
    await _auth('invite_revoke', {'invite_code': code});
  }
}
