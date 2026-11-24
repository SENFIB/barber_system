import 'notify.dart';

/// Thin safe wrapper over [Notify]. Never throws, no-op when unsupported.
class Reminders {
  static const String _defaultTz = 'Asia/Tehran';

  static String _tz(String? tz) =>
      (tz == null || tz.trim().isEmpty) ? _defaultTz : tz.trim();

  static Future<void> init() async {
    try {
      if (!Notify.supported) return;
      await Notify.init();
    } catch (_) {}
  }

  static Future<void> ask() async {
    try {
      if (!Notify.supported) return;
      await Notify.requestPermission();
    } catch (_) {}
  }

  static Future<void> booking({
    required String id,
    required String shop,
    required String date,
    required String time,
    String? tz,
    String lang = 'fa',
  }) async {
    try {
      if (!Notify.supported) return;
      await Notify.scheduleBooking(
        bookingId: id,
        shopName: shop,
        date: date,
        time: time,
        tzName: _tz(tz),
        lang: lang,
      );
    } catch (_) {}
  }

  static Future<void> cancelBooking(String id) async {
    try {
      if (!Notify.supported) return;
      await Notify.cancelBooking(id);
    } catch (_) {}
  }

  /// Custom shop message: shown [days] days after [date] at 11:00 shop-local.
  static Future<void> winback({
    required String key,
    required String date,
    String? tz,
    required int days,
    required String title,
    required String body,
  }) async {
    try {
      if (!Notify.supported) return;
      if (days < 1 || body.trim().isEmpty) return;
      final base = DateTime.tryParse(date);
      if (base == null) return;
      final d = DateTime.utc(base.year, base.month, base.day)
          .add(Duration(days: days));
      String two(int n) => n.toString().padLeft(2, '0');
      final iso = '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
      final dynamic at = await (Notify.shopInstant(iso, '11:00', _tz(tz)) as dynamic);
      if (at is! DateTime) return;
      await Notify.scheduleWinback(
        key: key,
        at: at,
        title: title,
        body: body,
      );
    } catch (_) {}
  }

  /// [expiresAt] comes from the server as text (ISO date or date-time).
  static Future<void> expiry(String expiresAt, String lang) async {
    try {
      if (!Notify.supported) return;
      final dt = DateTime.tryParse(expiresAt.trim());
      if (dt == null) return;
      await Notify.scheduleExpiry(expiresAt: dt, lang: lang);
    } catch (_) {}
  }

  static Future<void> cancelExpiry() async {
    try {
      if (!Notify.supported) return;
      await Notify.cancelExpiry();
    } catch (_) {}
  }
}
