import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// تنظیمات ذخیره‌شده روی دستگاه: زبان، نقش، تم، آدرس سرور و شناسه‌ی دستگاه
class AppSettings extends ChangeNotifier {
  AppSettings._(this._p);

  final SharedPreferences _p;

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    if ((p.getString('device_id') ?? '').isEmpty) {
      final r = Random.secure();
      final id =
          List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
      await p.setString('device_id', id);
    }
    return AppSettings._(p);
  }

  /// null یعنی هنوز زبان انتخاب نشده
  String? get language => _p.getString('language');
  String get lang => language ?? 'fa';

  /// null | 'customer' | 'shop'
  String? get role => _p.getString('role');

  ThemeMode get themeMode {
    switch (_p.getString('theme')) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get deviceId => _p.getString('device_id') ?? '';

  String get apiUrl {
    final v = _p.getString('api_url');
    return (v == null || v.trim().isEmpty) ? kDefaultApiUrl : v.trim();
  }

  Future<void> setLanguage(String v) async {
    await _p.setString('language', v);
    notifyListeners();
  }

  Future<void> setRole(String? v) async {
    if (v == null) {
      await _p.remove('role');
    } else {
      await _p.setString('role', v);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    final v = m == ThemeMode.light
        ? 'light'
        : m == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _p.setString('theme', v);
    notifyListeners();
  }

  Future<void> setApiUrl(String v) async {
    final t = v.trim();
    if (t.isEmpty) {
      await _p.remove('api_url');
    } else {
      await _p.setString('api_url', t);
    }
    notifyListeners();
  }
}
