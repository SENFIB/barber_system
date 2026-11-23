import 'package:barber_core/barber_core.dart';

import '../../app/settings.dart';

/// تبدیل‌های کوچک برای خواندن پاسخ سرور
String jStr(dynamic v) => v == null ? '' : '$v';

int? jInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse('$v'.trim());
}

bool jBool(dynamic v) => v == true || '$v'.toLowerCase() == 'true';

List<Map<String, dynamic>> jRows(dynamic v) {
  if (v is! List) return <Map<String, dynamic>>[];
  return [
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

const _lostCodes = [
  'UNAUTHORIZED',
  'DEVICE_MISMATCH',
  'SUBSCRIPTION_EXPIRED',
  'SHOP_DEACTIVATED',
];

/// یعنی نشست تمام شده یا اشتراک مشکل دارد و باید به صفحه‌ی اصلی برگشت
bool isSessionLost(Object e) => e is ApiException && _lostCodes.contains(e.code);

/// تماس مستقیم با سرور برای کارهای آرایشگاه (توکن و شناسه‌ی دستگاه خودکار اضافه می‌شود)
class ShopRaw {
  ShopRaw(this.st);
  final AppSettings st;

  Future<Map<String, dynamic>> call(String action,
      [Map<String, dynamic>? p]) async {
    final Map<String, dynamic> params = {
      ...?p,
      'token': st.shopToken,
      'device_id': st.deviceId,
    };
    final dynamic data = await ApiClient(st.apiUrl).call(action, params);
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
