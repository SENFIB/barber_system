import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ابزار حذف کامل اطلاعات محلی.
class LocalWipe {
  /// لغو همه‌ی یادآورهای زمان‌بندی‌شده (اندروید / iOS)
  static Future<void> cancelReminders() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await FlutterLocalNotificationsPlugin().cancelAll();
    } catch (_) {}
  }

  /// ویندوز: پوشه‌ی %APPDATA%\com.barberapp حذف می‌شود و برنامه بسته می‌شود.
  /// باید بعد از پاک کردن تنظیمات صدا زده شود.
  static Future<void> deleteWindowsFolder() async {
    if (!Platform.isWindows) return;
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      final dir = Directory('$appData\\com.barberapp');
      for (var i = 0; i < 5; i++) {
        try {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    exit(0);
  }
}
