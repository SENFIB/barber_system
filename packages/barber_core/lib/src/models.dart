String _s(dynamic v) => v == null ? '' : v.toString();

int _i(dynamic v, [int d = 0]) =>
    v is num ? v.toInt() : (int.tryParse(_s(v)) ?? d);

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// وضعیت اشتراک آرایشگاه (همان subscription سرور)
class Subscription {
  const Subscription({
    required this.state,
    required this.free,
    required this.expiresAt,
    required this.daysLeft,
    required this.expiringSoon,
    required this.warnDays,
  });

  /// active | expired | deactive
  final String state;
  final bool free;
  final String expiresAt;
  final int? daysLeft;
  final bool expiringSoon;
  final int warnDays;

  bool get isActive => state == 'active';
  bool get isExpired => state == 'expired';
  bool get isDeactive => state == 'deactive';

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        state: _s(j['state']),
        free: j['free'] == true,
        expiresAt: _s(j['expires_at']),
        daysLeft:
            j['days_left'] is num ? (j['days_left'] as num).toInt() : null,
        expiringSoon: j['expiring_soon'] == true,
        warnDays: _i(j['warn_days'], 3),
      );
}

/// اطلاعات عمومی آرایشگاه
class ShopInfo {
  const ShopInfo({
    required this.shopId,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.plan,
    required this.language,
    required this.calendar,
    required this.timezone,
    required this.bufferMin,
    required this.slotStepMin,
    required this.overtimeMin,
    required this.currency,
    required this.cancelBeforeMin,
    required this.description,
    required this.photoUrl,
  });

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

  factory ShopInfo.fromJson(Map<String, dynamic> j) => ShopInfo(
        shopId: _s(j['shop_id']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        address: _s(j['address']),
        city: _s(j['city']),
        plan: _s(j['plan']),
        language: _s(j['language']),
        calendar: _s(j['calendar']),
        timezone: _s(j['timezone']),
        bufferMin: _i(j['buffer_min']),
        slotStepMin: _i(j['slot_step_min'], 10),
        overtimeMin: _i(j['overtime_min']),
        currency: _s(j['currency']),
        cancelBeforeMin: _i(j['cancel_before_min']),
        description: _s(j['description']),
        photoUrl: _s(j['photo_url']),
      );
}

/// نشست ورود صاحب آرایشگاه یا آرایشگر
class ManagerSession {
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

  final String token;
  final String managerId;

  /// owner | staff
  final String role;
  final String staffId;
  final String username;
  final ShopInfo shop;
  final Subscription subscription;
  final int maxStaff;

  bool get isOwner => role == 'owner';

  /// پاسخ me توکن ندارد، پس توکن فعلی جداگانه داده می‌شود.
  factory ManagerSession.fromJson(Map<String, dynamic> j, {String? token}) {
    return ManagerSession(
      token: token ?? _s(j['token']),
      managerId: _s(j['manager_id']),
      role: _s(j['role']),
      staffId: _s(j['staff_id']),
      username: _s(j['username']),
      shop: ShopInfo.fromJson(_m(j['shop'])),
      subscription: Subscription.fromJson(_m(j['subscription'])),
      maxStaff: _i(_m(j['limits'])['max_staff']),
    );
  }
}
