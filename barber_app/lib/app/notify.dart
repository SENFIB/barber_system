// اعلان‌های محلی: یادآوری نوبت، هشدار پایان اشتراک، پیام آرایشگاه به مشتری.
// فقط اندروید و iOS. روی ویندوز هیچ کاری نمی‌کند.
//
// نیازمند پکیج‌های: flutter_local_notifications (17.2.4) و timezone
// (در مرحلهٔ وصل‌کردن به pubspec اضافه می‌شوند)

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'cal_conv.dart';

class Notify {
  Notify._();

  static final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _tzReady = false;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void _initTz() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  static Future<void> init() async {
    if (!supported || _ready) return;
    _initTz();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _p.initialize(settings);
    _ready = true;
  }

  /// اجازهٔ نمایش اعلان را می‌پرسد (اندروید ۱۳+ و iOS). نتیجه: true اگر مجاز است.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    if (Platform.isAndroid) {
      final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return (await a?.requestNotificationsPermission()) ?? true;
    }
    final i = _p.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return (await i?.requestPermissions(alert: true, badge: true, sound: true)) ?? false;
  }

  // ------------------------------------------------------------- helpers
  static int _id(String key) {
    var h = 0x811C9DC5;
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h & 0x7FFFFFFF;
  }

  static NotificationDetails _details(String channel, String name) => NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

  /// تاریخ و ساعتِ «به وقت آرایشگاه» را به لحظهٔ دقیق (UTC) تبدیل می‌کند.
  static DateTime? shopInstant(String isoDate, String hhmm, String tzName) {
    final d = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(isoDate.trim());
    final t = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm.trim());
    if (d == null || t == null) return null;
    final y = int.parse(d.group(1)!), mo = int.parse(d.group(2)!), da = int.parse(d.group(3)!);
    final h = int.parse(t.group(1)!), mi = int.parse(t.group(2)!);
    try {
      _initTz();
      final loc = tz.getLocation(tzName.trim().isEmpty ? 'Asia/Tehran' : tzName.trim());
      return tz.TZDateTime(loc, y, mo, da, h, mi).toUtc();
    } catch (_) {
      return DateTime(y, mo, da, h, mi).toUtc();
    }
  }

  // ------------------------------------------------------------- core
  static Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String channel = 'esm_booking',
    String channelName = 'ESMAIRO',
  }) async {
    if (!supported) return;
    await init();
    if (!at.isAfter(DateTime.now().add(const Duration(seconds: 5)))) return;
    final when = tz.TZDateTime.from(at, tz.UTC);
    try {
      await _p.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(channel, channelName),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _p.zonedSchedule(
          id,
          title,
          body,
          when,
          _details(channel, channelName),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  static Future<void> cancelKey(String key) async {
    if (!supported) return;
    await init();
    await _p.cancel(_id(key));
  }

  static Future<void> cancelAll() async {
    if (!supported) return;
    await init();
    await _p.cancelAll();
  }

  // ------------------------------------------------------------- booking
  static const List<int> defaultReminderMinutes = [120, 10];

  static Future<void> scheduleBooking({
    required String bookingId,
    required String shopName,
    required String date,
    required String time,
    required String tzName,
    required String lang,
    List<int> minutes = defaultReminderMinutes,
  }) async {
    final start = shopInstant(date, time, tzName);
    if (start == null) return;
    for (final m in minutes) {
      await scheduleAt(
        id: _id('bk:$bookingId:$m'),
        at: start.subtract(Duration(minutes: m)),
        title: _bookingTitle(lang),
        body: _bookingBody(lang, shopName, time, m),
      );
    }
  }

  static Future<void> cancelBooking(String bookingId,
      {List<int> minutes = defaultReminderMinutes}) async {
    for (final m in minutes) {
      await cancelKey('bk:$bookingId:$m');
    }
  }

  // ------------------------------------------------------------- subscription
  /// expiresAt: لحظهٔ پایان اشتراک. اعلان‌ها ساعت ۱۰ صبحِ ۳ و ۱ روز مانده نمایش داده می‌شوند.
  static Future<void> scheduleExpiry({
    required DateTime expiresAt,
    required String lang,
    List<int> days = const [3, 1],
  }) async {
    await cancelExpiry(days: days);
    for (final n in days) {
      final base = expiresAt.toLocal().subtract(Duration(days: n));
      final at = DateTime(base.year, base.month, base.day, 10, 0);
      await scheduleAt(
        id: _id('sub:$n'),
        at: at,
        title: _expiryTitle(lang),
        body: _expiryBody(lang, n),
        channel: 'esm_sub',
        channelName: 'Subscription',
      );
    }
  }

  static Future<void> cancelExpiry({List<int> days = const [3, 1]}) async {
    for (final n in days) {
      await cancelKey('sub:$n');
    }
  }

  // ------------------------------------------------------------- winback
  static Future<void> scheduleWinback({
    required String key,
    required DateTime at,
    required String title,
    required String body,
  }) =>
      scheduleAt(
        id: _id('wb:$key'),
        at: at,
        title: title,
        body: body,
        channel: 'esm_winback',
        channelName: 'Messages',
      );

  static Future<void> cancelWinback(String key) => cancelKey('wb:$key');

  // ------------------------------------------------------------- texts
  static String _bookingTitle(String l) =>
      l == 'ar' ? 'تذكير بالموعد' : (l == 'en' ? 'Booking reminder' : 'یادآوری نوبت');

  static String _bookingBody(String l, String shop, String time, int m) {
    final t = CalConv.digits(time, l);
    if (l == 'en') {
      final w = m % 60 == 0
          ? '${m ~/ 60} ${m ~/ 60 == 1 ? 'hour' : 'hours'}'
          : '$m minutes';
      return 'You have an appointment in $w: $shop at $time';
    }
    if (l == 'ar') {
      return 'لديك موعد بعد ${_arDur(m)}: $shop الساعة $t';
    }
    final w = m % 60 == 0 ? '${m ~/ 60} ساعت' : '$m دقیقه';
    return '${CalConv.digits(w, 'fa')} دیگر نوبت دارید: $shop، ساعت $t';
  }

  static String _arDur(int m) {
    String unit(int n, String one, String two, String few, String many) {
      if (n == 1) return one;
      if (n == 2) return two;
      if (n >= 3 && n <= 10) return '${CalConv.digits('$n', 'ar')} $few';
      return '${CalConv.digits('$n', 'ar')} $many';
    }

    if (m % 60 == 0) {
      return unit(m ~/ 60, 'ساعة', 'ساعتين', 'ساعات', 'ساعة');
    }
    return unit(m, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة');
  }

  static String _expiryTitle(String l) => l == 'ar'
      ? 'اشتراكك على وشك الانتهاء'
      : (l == 'en' ? 'Your subscription is ending' : 'اشتراک رو به پایان است');

  static String _expiryBody(String l, int n) {
    if (l == 'en') {
      return n == 1
          ? 'Your shop subscription ends tomorrow. Enter a new license code to renew.'
          : 'Your shop subscription ends in $n days. Enter a new license code to renew.';
    }
    if (l == 'ar') {
      if (n == 1) return 'ينتهي اشتراك صالونك غدًا. أدخل رمز ترخيص جديدًا للتجديد.';
      final d = n >= 3 && n <= 10 ? 'أيام' : 'يومًا';
      return 'ينتهي اشتراك صالونك بعد ${CalConv.digits('$n', 'ar')} $d. أدخل رمز ترخيص جديدًا للتجديد.';
    }
    return n == 1
        ? 'اشتراک آرایشگاه شما تا فردا تمام می‌شود. برای تمدید، کد لایسنس جدید وارد کنید.'
        : 'اشتراک آرایشگاه شما ${CalConv.digits('$n', 'fa')} روز دیگر تمام می‌شود. برای تمدید، کد لایسنس جدید وارد کنید.';
  }
}
