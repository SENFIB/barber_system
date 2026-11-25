import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'settings.dart';

class ExtraError implements Exception {
  final String code;
  final String message;
  ExtraError(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

Future<Map<String, dynamic>> extraPost(String url, Map<String, dynamic> body,
    {int timeoutSec = 60}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    var uri = Uri.parse(url);
    final req = await client.postUrl(uri);
    req.followRedirects = false;
    req.headers.set('Content-Type', 'text/plain;charset=utf-8');
    req.add(utf8.encode(jsonEncode(body)));
    var res = await req.close().timeout(Duration(seconds: timeoutSec));
    var hops = 0;
    while ((res.statusCode == 301 ||
            res.statusCode == 302 ||
            res.statusCode == 303 ||
            res.statusCode == 307 ||
            res.statusCode == 308) &&
        hops < 5) {
      final loc = res.headers.value('location');
      await res.drain<void>();
      if (loc == null) break;
      uri = uri.resolve(loc);
      final r2 = await client.getUrl(uri);
      r2.followRedirects = false;
      res = await r2.close().timeout(Duration(seconds: timeoutSec));
      hops++;
    }
    final text = await res.transform(utf8.decoder).join();
    final dynamic j = jsonDecode(text);
    if (j is! Map) throw ExtraError('NETWORK', 'bad response');
    if (j['ok'] == true) {
      final d = j['data'];
      if (d is Map) return Map<String, dynamic>.from(d);
      return <String, dynamic>{};
    }
    throw ExtraError('${j['error'] ?? 'SERVER_ERROR'}', '${j['message'] ?? ''}');
  } on ExtraError {
    rethrow;
  } on TimeoutException {
    throw ExtraError('NETWORK', 'timeout');
  } on IOException {
    throw ExtraError('NETWORK', 'io');
  } on FormatException {
    throw ExtraError('NETWORK', 'format');
  } finally {
    client.close(force: true);
  }
}

/// درخواست مدیر (با توکن و شناسه‌ی دستگاه) به سرور فعلی آرایشگاه
Future<Map<String, dynamic>> extraManager(AppSettings st, String action,
    [Map<String, dynamic>? params]) {
  final body = <String, dynamic>{};
  if (params != null) body.addAll(params);
  body['action'] = action;
  body['token'] = st.shopToken ?? '';
  body['device_id'] = st.deviceId;
  return extraPost(st.apiUrl, body);
}

/// درخواست بدون ورود
Future<Map<String, dynamic>> extraPublic(String url, String action,
    [Map<String, dynamic>? params]) {
  final body = <String, dynamic>{};
  if (params != null) body.addAll(params);
  body['action'] = action;
  return extraPost(url, body);
}

String latinOf(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x06F0 && r <= 0x06F9) {
      sb.writeCharCode(0x30 + r - 0x06F0);
    } else if (r >= 0x0660 && r <= 0x0669) {
      sb.writeCharCode(0x30 + r - 0x0660);
    } else {
      sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

const Map<String, Map<String, String>> _errTx = {
  'fa': {
    'NETWORK': 'اتصال برقرار نشد. اینترنت را بررسی کنید',
    'UNAUTHORIZED': 'دوباره وارد شوید',
    'DEVICE_MISMATCH': 'این حساب به دستگاه دیگری وصل است',
    'FORBIDDEN': 'این کار فقط برای صاحب آرایشگاه است',
    'SUBSCRIPTION_EXPIRED': 'اشتراک تمام شده است',
    'SHOP_DEACTIVATED': 'این اشتراک غیرفعال شده است',
    'BAD_NUMBER': 'عدد واردشده معتبر نیست',
    'SERVICE_LIMIT': 'سقف تعداد خدمات پر شده است',
    'TOO_MANY': 'تلاش زیاد بود، کمی بعد دوباره امتحان کنید',
    'BUSY': 'سرور شلوغ است، دوباره تلاش کنید',
    'UNKNOWN_ACTION': 'سرویس هنوز به‌روز نشده است',
    'CAL_UNAVAILABLE': 'تقویم در دسترس نیست',
    'BAD_DATE': 'تاریخ معتبر نیست',
    'BAD_REQUEST': 'درخواست نامعتبر است',
    'BAD_MESSAGE': 'توضیح را بنویسید',
    'other': 'خطا؛ دوباره تلاش کنید',
  },
  'en': {
    'NETWORK': 'Could not connect. Check your internet',
    'UNAUTHORIZED': 'Please sign in again',
    'DEVICE_MISMATCH': 'This account is linked to another device',
    'FORBIDDEN': 'Only the shop owner can do this',
    'SUBSCRIPTION_EXPIRED': 'The subscription has ended',
    'SHOP_DEACTIVATED': 'This subscription is deactivated',
    'BAD_NUMBER': 'The number is not valid',
    'SERVICE_LIMIT': 'The service limit is reached',
    'TOO_MANY': 'Too many attempts, try again later',
    'BUSY': 'Server is busy, try again',
    'UNKNOWN_ACTION': 'The service is not updated yet',
    'CAL_UNAVAILABLE': 'Calendar is not available',
    'BAD_DATE': 'The date is not valid',
    'BAD_REQUEST': 'Invalid request',
    'BAD_MESSAGE': 'Please write a description',
    'other': 'Error; please try again',
  },
  'ar': {
    'NETWORK': 'تعذر الاتصال. تحقق من الإنترنت',
    'UNAUTHORIZED': 'سجّل الدخول من جديد',
    'DEVICE_MISMATCH': 'هذا الحساب مرتبط بجهاز آخر',
    'FORBIDDEN': 'هذا الإجراء لمالك الصالون فقط',
    'SUBSCRIPTION_EXPIRED': 'انتهى الاشتراك',
    'SHOP_DEACTIVATED': 'هذا الاشتراك معطّل',
    'BAD_NUMBER': 'الرقم غير صحيح',
    'SERVICE_LIMIT': 'تم الوصول إلى حد الخدمات',
    'TOO_MANY': 'محاولات كثيرة، حاول لاحقًا',
    'BUSY': 'الخادم مشغول، حاول مجددًا',
    'UNKNOWN_ACTION': 'الخدمة لم تُحدَّث بعد',
    'CAL_UNAVAILABLE': 'التقويم غير متاح',
    'BAD_DATE': 'التاريخ غير صحيح',
    'BAD_REQUEST': 'طلب غير صالح',
    'BAD_MESSAGE': 'اكتب وصفًا',
    'other': 'خطأ، حاول مجددًا',
  },
};

String extraErrorText(ExtraError e, String lang) {
  final m = _errTx[lang] ?? _errTx['fa']!;
  return m[e.code] ?? m['other']!;
}
