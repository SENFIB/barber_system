import 'package:shared_preferences/shared_preferences.dart';

class SavedCustomer {
  const SavedCustomer(this.name, this.phone);
  final String name;
  final String phone;
}

class CustomerStore {
  static const String _kName = 'cust_name';
  static const String _kPhone = 'cust_phone';

  static Future<SavedCustomer> load() async {
    final p = await SharedPreferences.getInstance();
    return SavedCustomer(p.getString(_kName) ?? '', p.getString(_kPhone) ?? '');
  }

  static Future<void> save(String name, String phone) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
  }

  static Future<bool> hasData() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_kName) ?? '').isNotEmpty ||
        (p.getString(_kPhone) ?? '').isNotEmpty;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kName);
    await p.remove(_kPhone);
  }
}
