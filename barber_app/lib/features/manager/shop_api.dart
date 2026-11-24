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

  List<Map<String, dynamic>> _rows(dynamic d, String key) {
    final raw = d is Map ? d[key] : null;
    final out = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  ManagerSession _session(dynamic d, {String? token}) =>
      ManagerSession.fromJson(_map(d), token: token);

  // ───────────── بدون ورود ─────────────

  /// plan = اشتراکی که مالک خودش انتخاب کرده (basic | pro | special | personal).
  /// سرور چک می‌کند کد لایسنس با همین اشتراک بخواند.
  /// shifts = «09:00-13:00|16:00-22:00» و daysOff = روزهای تعطیل (0 = یکشنبه)
  /// برای مالکی که خودش هم آرایشگر است.
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
    String plan = '',
    String shifts = '',
    List<int>? daysOff,
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
    if (plan.isNotEmpty) p['plan'] = plan;
    if (ownerIsBarber && shifts.isNotEmpty) {
      p['shifts'] = shifts;
      final first = shifts.split('|').first.split('-');
      final last = shifts.split('|').last.split('-');
      if (first.length == 2 && last.length == 2) {
        p['work_start'] = first[0];
        p['work_end'] = last[1];
      }
      if (daysOff != null) {
        final d = [...daysOff]..sort();
        p['days_off'] = d.join('|');
      }
    }
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

  // ───────────── حساب و اشتراک ─────────────

  Future<ManagerSession> me() async =>
      _session(await _auth('me'), token: settings.shopToken);

  Future<void> renew(String licenseKey) async {
    await _auth('renew', {'license_key': licenseKey.trim().toUpperCase()});
  }

  Future<void> logout() async {
    await _auth('logout');
  }

  /// فقط صاحب آرایشگاه. فیلدها: name, phone, address, city, description,
  /// currency, photo_url (فقط اشتراک ویژه/شخصی), buffer_min, overtime_min,
  /// cancel_before_min, slot_step_min, calendar, timezone
  Future<Map<String, dynamic>> shopUpdate(Map<String, dynamic> fields) async =>
      _map(await _auth('shop_update', fields));

  // ───────────── آرایشگرها ─────────────

  Future<Map<String, dynamic>> staffList() async =>
      _map(await _auth('staff_list'));

  Future<void> staffAdd({
    required String name,
    String specialty = '',
    required String workStart,
    required String workEnd,
    List<String>? serviceIds,
    List<int>? daysOff,
  }) async {
    await _auth('staff_add', {
      'name': name.trim(),
      'specialty': specialty.trim(),
      'work_start': workStart,
      'work_end': workEnd,
      if (serviceIds != null) 'service_ids': serviceIds,
      if (daysOff != null) 'days_off': daysOff,
    });
  }

  /// فقط فیلدهایی که null نیستند ارسال می‌شوند.
  /// serviceIds خالی = این آرایشگر همه‌ی خدمات را انجام می‌دهد.
  /// shifts = «09:00-13:00|16:00-22:00» (تا ۳ شیفت)؛ ذخیره‌ی آن یعنی
  /// آرایشگر ساعتش را تنظیم کرده و مشتری می‌تواند وقت ببیند.
  /// clearOvertime = اضافه‌کار اختصاصی پاک شود و تنظیم آرایشگاه اعمال شود.
  Future<void> staffUpdate({
    required String staffId,
    String? name,
    String? specialty,
    List<String>? serviceIds,
    String? workStart,
    String? workEnd,
    String? shifts,
    List<int>? daysOff,
    int? overtimeMin,
    bool clearOvertime = false,
  }) async {
    await _auth('staff_update', {
      'staff_id': staffId,
      if (name != null) 'name': name.trim(),
      if (specialty != null) 'specialty': specialty.trim(),
      if (serviceIds != null) 'service_ids': serviceIds,
      if (workStart != null) 'work_start': workStart,
      if (workEnd != null) 'work_end': workEnd,
      if (shifts != null) 'shifts': shifts,
      if (daysOff != null) 'days_off': daysOff,
      if (overtimeMin != null) 'overtime_min': overtimeMin,
      if (clearOvertime) 'overtime_min': null,
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

  // ───────────── خدمات ─────────────

  Future<List<Map<String, dynamic>>> serviceList() async =>
      _rows(await _auth('service_list'), 'services');

  /// serviceId خالی = خدمت جدید. خروجی: شناسه‌ی خدمت
  Future<String> serviceSave({
    String? serviceId,
    required String name,
    required int durationMin,
    required int price,
    List<String> combinableWith = const [],
  }) async {
    final d = await _auth('service_save', {
      if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
      'name': name.trim(),
      'duration_min': durationMin,
      'price': price,
      'combinable_with': combinableWith,
    });
    return '${_map(d)['service_id'] ?? ''}';
  }

  Future<void> serviceRemove(String serviceId) async {
    await _auth('service_remove', {'service_id': serviceId});
  }

  // ───────────── مرخصی / تعطیلی ─────────────

  Future<List<Map<String, dynamic>>> timeoffList() async =>
      _rows(await _auth('timeoff_list'), 'blocks');

  /// خروجی: {block_id, conflicts}
  Future<Map<String, dynamic>> timeoffAdd({
    String? staffId,
    required String dateFrom,
    String? dateTo,
    String? startTime,
    String? endTime,
    String reason = '',
  }) async =>
      _map(await _auth('timeoff_add', {
        if (staffId != null && staffId.isNotEmpty) 'staff_id': staffId,
        'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        'reason': reason.trim(),
      }));

  Future<void> timeoffRemove(String blockId) async {
    await _auth('timeoff_remove', {'block_id': blockId});
  }

  // ───────────── نوبت‌ها ─────────────

  /// خروجی: {bookings:[...], now:{date,min}}
  Future<Map<String, dynamic>> bookingsList({
    String? dateFrom,
    String? dateTo,
    String? staffId,
  }) async =>
      _map(await _auth('bookings_list', {
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (staffId != null && staffId.isNotEmpty) 'staff_id': staffId,
      }));

  /// items: [{service_id, staff_id}]
  Future<Map<String, dynamic>> bookingManual({
    required List<Map<String, String>> items,
    required String date,
    required String startTime,
    String customerName = '',
    String customerPhone = '',
  }) async =>
      _map(await _auth('booking_manual', {
        'items': items,
        'date': date,
        'start_time': startTime,
        if (customerName.trim().isNotEmpty)
          'customer_name': customerName.trim(),
        if (customerPhone.trim().isNotEmpty)
          'customer_phone':
              normalizeDigits(customerPhone).replaceAll(RegExp(r'[^0-9+]'), ''),
      }));

  Future<void> bookingCancel({String? bookingId, String? groupId}) async {
    await _auth('booking_cancel', {
      if (bookingId != null) 'booking_id': bookingId,
      if (groupId != null) 'group_id': groupId,
    });
  }

  Future<void> bookingFinish(String bookingId) async {
    await _auth('booking_finish', {'booking_id': bookingId});
  }

  Future<void> bookingNoShow(String bookingId) async {
    await _auth('booking_noshow', {'booking_id': bookingId});
  }

  // ───────────── «دلمون تنگ شده» (پلن ویژه) ─────────────

  Future<List<Map<String, dynamic>>> winbackList() async =>
      _rows(await _auth('winback_list'), 'rules');

  Future<void> winbackSave(List<Map<String, dynamic>> rules) async {
    await _auth('winback_save', {'rules': rules});
  }
}
