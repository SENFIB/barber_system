String _s(dynamic v, [String d = '']) => v == null ? d : v.toString();

int _i(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? d;
}

int? _iOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _b(dynamic v) => v == true || v == 'true' || v == 'TRUE' || v == 1;

Map<String, dynamic> _m(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

class Subscription {
  final String state; // active | expired | deactive
  final bool free;
  final String? expiresAt;
  final int? daysLeft;
  final bool expiringSoon;
  final int warnDays;

  const Subscription({
    required this.state,
    required this.free,
    this.expiresAt,
    this.daysLeft,
    this.expiringSoon = false,
    this.warnDays = 3,
  });

  bool get isActive => state == 'active';
  bool get isExpired => state == 'expired';
  bool get isDeactive => state == 'deactive';

  factory Subscription.fromJson(dynamic json) {
    final j = _m(json);
    final exp = _s(j['expires_at']);
    return Subscription(
      state: _s(j['state'], 'active'),
      free: _b(j['free']),
      expiresAt: exp.isEmpty ? null : exp,
      daysLeft: _iOrNull(j['days_left']),
      expiringSoon: _b(j['expiring_soon']),
      warnDays: _i(j['warn_days'], 3),
    );
  }
}

class ShopInfo {
  final String shopId;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String plan;
  final String language;
  final String calendar;
  final String timezone;
  final int bufferMin;
  final int slotStepMin;
  final int overtimeMin;
  final String currency;
  final int cancelBeforeMin;
  final String description;
  final String photoUrl;

  const ShopInfo({
    required this.shopId,
    required this.name,
    this.phone = '',
    this.address = '',
    this.city = '',
    this.plan = 'basic',
    this.language = 'fa',
    this.calendar = 'jalali',
    this.timezone = 'Asia/Tehran',
    this.bufferMin = 0,
    this.slotStepMin = 10,
    this.overtimeMin = 0,
    this.currency = '',
    this.cancelBeforeMin = 120,
    this.description = '',
    this.photoUrl = '',
  });

  factory ShopInfo.fromJson(dynamic json) {
    final j = _m(json);
    return ShopInfo(
      shopId: _s(j['shop_id']),
      name: _s(j['name']),
      phone: _s(j['phone']),
      address: _s(j['address']),
      city: _s(j['city']),
      plan: _s(j['plan'], 'basic'),
      language: _s(j['language'], 'fa'),
      calendar: _s(j['calendar'], 'jalali'),
      timezone: _s(j['timezone'], 'Asia/Tehran'),
      bufferMin: _i(j['buffer_min'], 0),
      slotStepMin: _i(j['slot_step_min'], 10),
      overtimeMin: _i(j['overtime_min'], 0),
      currency: _s(j['currency']),
      cancelBeforeMin: _i(j['cancel_before_min'], 120),
      description: _s(j['description']),
      photoUrl: _s(j['photo_url']),
    );
  }
}

class ManagerSession {
  final String token;
  final String managerId;
  final String role; // owner | staff
  final String staffId;
  final String username;
  final ShopInfo shop;
  final Subscription subscription;
  final int maxStaff;

  const ManagerSession({
    required this.token,
    required this.managerId,
    required this.role,
    required this.staffId,
    required this.username,
    required this.shop,
    required this.subscription,
    required this.maxStaff,
  });

  bool get isOwner => role == 'owner';

  /// پاسخ `me` توکن ندارد؛ پس توکن فعلی از بیرون داده می‌شود.
  factory ManagerSession.fromJson(dynamic json, {String? token}) {
    final j = _m(json);
    final limits = _m(j['limits']);
    return ManagerSession(
      token: token ?? _s(j['token']),
      managerId: _s(j['manager_id']),
      role: _s(j['role'], 'owner'),
      staffId: _s(j['staff_id']),
      username: _s(j['username']),
      shop: ShopInfo.fromJson(j['shop']),
      subscription: Subscription.fromJson(j['subscription']),
      maxStaff: _i(limits['max_staff'], 0),
    );
  }
}
