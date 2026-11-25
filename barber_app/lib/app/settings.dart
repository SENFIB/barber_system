import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'look.dart';

const _kLang = 'language';
const _kRole = 'role';
const _kTheme = 'theme_mode';
const _kDevice = 'device_id';
const _kApi = 'api_url';
const _kToken = 'shop_token';
const _kLook = 'look';
const _kTime = 'time_mode';
const _kCal = 'calendar_mode';
const _kHdrClock = 'hdr_clock';
const _kHdrLang = 'hdr_lang';
const _kHdrBtns = 'hdr_btns';

String _newDeviceId() {
  final r = Random.secure();
  final b = StringBuffer();
  for (var i = 0; i < 24; i++) {
    b.write(r.nextInt(16).toRadixString(16));
  }
  return b.toString();
}

Future<void> _deleteFile(String path) async {
  if (path.isEmpty) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

class AppSettings extends ChangeNotifier {
  AppSettings._(this._p);
  final SharedPreferences _p;

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    if ((p.getString(_kDevice) ?? '').isEmpty) {
      await p.setString(_kDevice, _newDeviceId());
    }
    return AppSettings._(p);
  }

  String? _get(String k) {
    final v = _p.getString(k);
    return (v == null || v.isEmpty) ? null : v;
  }

  String? get language => _get(_kLang);
  String get lang => language ?? 'fa';
  bool get isRtl => lang == 'fa' || lang == 'ar';

  /// 'customer' | 'shop' | null
  String? get role => _get(_kRole);

  String get themeKey => _get(_kTheme) ?? 'system';
  ThemeMode get themeMode {
    switch (themeKey) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get deviceId => _p.getString(_kDevice) ?? '';
  bool get hasCustomApiUrl => (_get(_kApi) ?? '').trim().isNotEmpty;
  String get apiUrl => hasCustomApiUrl ? _get(_kApi)!.trim() : kDefaultApiUrl;
  String? get shopToken => _get(_kToken);
  bool get hasShopToken => shopToken != null;

  // ---------- ساعت و تقویم ----------

  /// 'shop' = ساعت و تاریخ منطقه‌ی زبان (تهران / مکه / لندن) | 'phone' = ساعت و تاریخ دستگاه
  String get timeMode => _get(_kTime) ?? 'shop';
  bool get usePhoneTime => timeMode == 'phone';

  /// 'auto' | 'jalali' | 'gregorian' | 'hijri'
  String get calendarKey => _get(_kCal) ?? 'auto';

  /// تقویم نهایی: در حالت خودکار از روی زبان
  /// فارسی = شمسی ، انگلیسی = میلادی ، عربی = هجری
  String get calendar {
    final k = calendarKey;
    if (k != 'auto') return k;
    if (lang == 'fa') return 'jalali';
    if (lang == 'ar') return 'hijri';
    return 'gregorian';
  }

  // ---------- نمایش هدر ----------
  bool get showHdrClock => _get(_kHdrClock) != '0';
  bool get showHdrLang => _get(_kHdrLang) != '0';
  bool get showHdrBtns => _get(_kHdrBtns) != '0';

  // ---------- ظاهر ----------
  String? _lookRaw;
  AppLook _lookVal = const AppLook();
  AppLook get look {
    final raw = _get(_kLook);
    if (raw != _lookRaw) {
      _lookRaw = raw;
      _lookVal = AppLook.fromJsonString(raw);
    }
    return _lookVal;
  }

  Future<void> _set(String k, String? v) async {
    if (v == null || v.isEmpty) {
      await _p.remove(k);
    } else {
      await _p.setString(k, v);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String v) => _set(_kLang, v);
  Future<void> setRole(String? v) => _set(_kRole, v);
  Future<void> setThemeKey(String v) => _set(_kTheme, v);
  Future<void> setApiUrl(String? v) => _set(_kApi, v?.trim());
  Future<void> setShopToken(String? v) => _set(_kToken, v);
  Future<void> setLook(AppLook l) => _set(_kLook, jsonEncode(l.toJson()));
  Future<void> setTimeMode(String v) => _set(_kTime, v);
  Future<void> setCalendarKey(String v) => _set(_kCal, v);
  Future<void> setHdrClock(bool v) => _set(_kHdrClock, v ? '1' : '0');
  Future<void> setHdrLang(bool v) => _set(_kHdrLang, v ? '1' : '0');
  Future<void> setHdrBtns(bool v) => _set(_kHdrBtns, v ? '1' : '0');

  /// عکس انتخابی را در حافظه‌ی خصوصی برنامه کپی می‌کند و به‌عنوان پس‌زمینه می‌گذارد
  Future<void> setBackgroundImage(String sourcePath) async {
    final dir = await getApplicationSupportDirectory();
    var ext = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'jpg';
    if (!RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) ext = 'jpg';
    final dest =
        '${dir.path}${Platform.pathSeparator}bg_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(dest);
    final old = look.bgImage;
    await setLook(look.copyWith(bgMode: 'image', bgImage: dest));
    if (old != dest) await _deleteFile(old);
  }

  Future<void> clearBackgroundImage() async {
    final cur = look;
    final old = cur.bgImage;
    await setLook(cur.copyWith(
      bgImage: '',
      bgMode: cur.bgMode == 'image' ? 'blobs' : cur.bgMode,
    ));
    await _deleteFile(old);
  }

  /// همه‌ی تنظیمات ظاهر (و عکس پس‌زمینه) را به حالت اول برمی‌گرداند
  Future<void> resetLook() async {
    final old = look.bgImage;
    await _p.remove(_kLook);
    notifyListeners();
    await _deleteFile(old);
  }

  /// همه‌ی اطلاعات ذخیره‌شده را پاک می‌کند. شناسه دستگاه به‌صورت پیش‌فرض می‌ماند.
  Future<void> clearAll({bool resetDeviceId = false}) async {
    final img = look.bgImage;
    for (final k in _p.getKeys().toList()) {
      if (k != _kDevice) await _p.remove(k);
    }
    if (resetDeviceId) await _p.setString(_kDevice, _newDeviceId());
    await _deleteFile(img);
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  /// با گوش دادن به تغییرات (برای build)
  static AppSettings of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// بدون گوش دادن (برای initState و دکمه‌ها)
  static AppSettings read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
