import 'notify.dart';

/// پوشش امن روی Notify: هیچ‌وقت خطا نمی‌دهد و روی ویندوز کاری نمی‌کند.
class Reminders {
  static const String _tz = 'Asia/Tehran';

  static Future<void> init() async {
    try {
      if (!Notify.supported) return;
      await Notify.init().timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  static Future<void> ask() async {
    try {
      if (Notify.supported) await Notify.requestPermission();
    } catch (_) {}
  }

  static Future<void> booking({
    required String id,
    required String shop,
    required String date,
    required String time,
    required String tz,
    required String lang,
  }) async {
    try {
      if (!Notify.supported) return;
      await Notify.scheduleBooking(
        bookingId: id,
        shopName: shop,
        date: date,
        time: time,
        tzName: tz.isEmpty ? _tz : tz,
        lang: lang,
      );
    } catch (_) {}
  }

  static Future<void> cancelBooking(String id) async {
    try {
      if (Notify.supported) await Notify.cancelBooking(id);
    } catch (_) {}
  }

  static Future<void> winback({
    required String key,
    required String date,
    required String tz,
    required int days,
    required String title,
    required String body,
  }) async {
    try {
      if (!Notify.supported) return;
      final dynamic base = await Future<dynamic>.value(
          Notify.shopInstant(date, '11:00', tz.isEmpty ? _tz : tz));
      final at = (base as DateTime).add(Duration(days: days));
      await Notify.scheduleWinback(key: key, at: at, title: title, body: body);
    } catch (_) {}
  }

  static Future<void> expiry(String expiresAt, String lang) async {
    try {
      if (!Notify.supported) return;
      await Notify.scheduleExpiry(expiresAt: expiresAt, lang: lang);
    } catch (_) {}
  }

  static Future<void> cancelExpiry() async {
    try {
      if (Notify.supported) await Notify.cancelExpiry();
    } catch (_) {}
  }
}
