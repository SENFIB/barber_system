String _s(dynamic v) => v == null ? '' : v.toString();

int? _i(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _b(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final t = _s(v).toLowerCase();
  return t == 'true' || t == '1' || t == 'yes';
}

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class Subscription {
  final String state;
  final bool free;
  final String? expiresAt;
  final int? daysLeft;
  final bool expiringSoon;
  final int warnDays;

  const Subscription({
    this.state = 'active',
    this.free = false,
    this.expiresAt,
    this.daysLeft,
    this.expiringSoon = false,
    this.warnDays = 3,
  });

  factory Subscription.fromJson(dynamic raw) {
    final j = _m(raw);
    final exp = _s(j['expires_at']);
    return Subscription(
      state: _s(j['state']).isEmpty ? 'active' : _s(j['state']),
      free: _b(j['free']),
      expiresAt: exp.isEmpty ? null : exp,
      daysLeft: _i(j['days_left']),
      expiringSoon: _b(j['expiring_soon']),
      warnDays: _i(j['warn_days']) ?? 3,
    );
  }

  bool get isExpired => state == 'expired';
  bool get isDeactive =>
      state == 'deactive' || state == 'deactivated' || state == 'revoked';
  bool get isActive => !isExpired && !isDeactive;
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
    this.shopId = '',
    this.name = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.plan = '',
    this.language = '',
    this.calendar = '',
    this.timezone = '',
    this.bufferMin = 0,
    this.slotStepMin = 10,
    this.overtimeMin = 0,
    this.currency = '',
    this.cancelBeforeMin = 120,
    this.description = '',
    this.photoUrl = '',
  });

  factory ShopInfo.fromJson(dynamic raw) {
    final j = _m(raw);
    return ShopInfo(
      shopId: _s(j['shop_id']),
      name: _s(j['name']),
      phone: _s(j['phone']),
      address: _s(j['address']),
      city: _s(j['city']),
      plan: _s(j['plan']),
      language: _s(j['language']),
      calendar: _s(j['calendar']),
      timezone: _s(j['timezone']),
      bufferMin: _i(j['buffer_min']) ?? 0,
      slotStepMin: _i(j['slot_step_min']) ?? 10,
      overtimeMin: _i(j['overtime_min']) ?? 0,
      currency: _s(j['currency']),
      cancelBeforeMin: _i(j['cancel_before_min']) ?? 120,
      description: _s(j['description']),
      photoUrl: _s(j['photo_url']),
    );
  }
}

class ManagerSession {
  final String token;
  final String managerId;
  final String role;
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

  factory ManagerSession.fromJson(Map<String, dynamic> j, {String? token}) {
    final t = _s(j['token']);
    return ManagerSession(
      token: t.isNotEmpty ? t : (token ?? ''),
      managerId: _s(j['manager_id']),
      role: _s(j['role']),
      staffId: _s(j['staff_id']),
      username: _s(j['username']),
      shop: ShopInfo.fromJson(j['shop']),
      subscription: Subscription.fromJson(j['subscription']),
      maxStaff: _i(_m(j['limits'])['max_staff']) ?? 0,
    );
  }

  bool get isOwner => role == 'owner';
}
