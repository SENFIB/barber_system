import 'package:shared_preferences/shared_preferences.dart';

class CustomerInfo {
  const CustomerInfo(this.name, this.phone);
  final String name, phone;
  bool get isEmpty => name.isEmpty && phone.isEmpty;
}

/// نام و شماره‌ی مشتری فقط روی همین گوشی ذخیره می‌شود.
class CustomerStore {
  static const _kName = 'cust_name';
  static const _kPhone = 'cust_phone';
  static const _kDev = 'cust_dev';

  /// پارامتر deviceId فقط برای سازگاری با کدهای قدیمی است.
  static Future<CustomerInfo> load([String? deviceId]) async {
    final p = await SharedPreferences.getInstance();
    return CustomerInfo(p.getString(_kName) ?? '', p.getString(_kPhone) ?? '');
  }

  /// save(name, phone) یا شکل قدیمی save(deviceId, name, phone)
  static Future<void> save(String a, String b, [String? c]) async {
    final name = c == null ? a : b;
    final phone = c == null ? b : c;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
  }

  static Future<bool> hasData() async {
    final i = await load();
    return !i.isEmpty;
  }

  static Future<void> wipe() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kName);
    await p.remove(_kPhone);
    await p.remove(_kDev);
  }

  static Future<void> clear() => wipe();
}
