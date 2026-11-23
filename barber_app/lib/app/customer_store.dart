import 'package:shared_preferences/shared_preferences.dart';

class CustomerInfo {
  const CustomerInfo(this.name, this.phone);
  final String name, phone;
}

/// نام و شماره‌ی مشتری فقط روی همین گوشی. به شناسه‌ی دستگاه وصل است؛
/// با «حذف داده‌ها» شناسه عوض می‌شود و این اطلاعات هم خودکار پاک می‌شوند.
class CustomerStore {
  static const _kName = 'cust_name';
  static const _kPhone = 'cust_phone';
  static const _kDev = 'cust_dev';

  static Future<CustomerInfo> load(String deviceId) async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kDev) != deviceId) {
      await wipe();
      return const CustomerInfo('', '');
    }
    return CustomerInfo(p.getString(_kName) ?? '', p.getString(_kPhone) ?? '');
  }

  static Future<void> save(String deviceId, String name, String phone) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDev, deviceId);
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
  }

  static Future<void> wipe() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kName);
    await p.remove(_kPhone);
    await p.remove(_kDev);
  }
}
