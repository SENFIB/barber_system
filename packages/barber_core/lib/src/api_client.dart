import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, [this.message = '']);

  @override
  String toString() => 'ApiException($code): $message';
}

class _Hit {
  _Hit(this.data, this.at);
  final dynamic data;
  final DateTime at;
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  ApiClient(this.baseUrl, {this.timeout = const Duration(seconds: 40)});

  // یک اتصال مشترک: اتصال امن بین درخواست‌ها زنده می‌ماند و سریع‌تر می‌شود
  static final HttpClient _shared = HttpClient()
    ..idleTimeout = const Duration(seconds: 60);

  static final Map<String, _Hit> _cache = {};
  static final Map<String, Future<dynamic>> _flying = {};
  static const Duration _ttl = Duration(seconds: 8);

  // خواندنی‌هایی که چند ثانیه کش می‌شوند
  static const Set<String> _cacheable = {
    'me',
    'service_list',
    'staff_list',
    'popular',
    'ads_list',
  };

  // خواندنی‌هایی که کش نمی‌شوند ولی کش را هم پاک نمی‌کنند
  static const Set<String> _readOnly = {
    'bookings_list',
    'slots',
    'shop_search',
    'shop_detail',
    'my_bookings',
    'cal_month',
    'cal_parts',
    'app_version',
    'winback_list',
    'timeoff_list',
    'ad_get',
    'store_get',
  };

  /// یک action رو صدا می‌زنه و `data` رو برمی‌گردونه.
  /// در صورت خطا ApiException پرتاب می‌کنه.
  Future<dynamic> call(String action, [Map<String, dynamic>? params]) async {
    final url = baseUrl.trim();
    if (url.isEmpty) {
      throw ApiException('NO_URL', 'server url is empty');
    }
    final body = jsonEncode(<String, dynamic>{...?params, 'action': action});

    if (_cacheable.contains(action)) {
      final key = '$url|$body';
      final hit = _cache[key];
      if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
        return hit.data;
      }
      final fl = _flying[key];
      if (fl != null) return fl;
      final f = _fetch(url, action, body);
      _flying[key] = f;
      try {
        final d = await f;
        if (_cache.length > 60) _cache.clear();
        _cache[key] = _Hit(d, DateTime.now());
        return d;
      } finally {
        _flying.remove(key);
      }
    }

    if (_readOnly.contains(action)) {
      return _fetch(url, action, body);
    }

    // عملیات نوشتنی: کش قبل و بعد پاک می‌شود
    _cache.clear();
    try {
      return await _fetch(url, action, body);
    } finally {
      _cache.clear();
    }
  }

  Future<dynamic> _fetch(String url, String action, String body) async {
    final retry = _cacheable.contains(action) || _readOnly.contains(action);
    String text;
    try {
      text = await _send(url, body, retry);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('NETWORK', 'timeout');
    } on SocketException catch (e) {
      throw ApiException('NETWORK', e.message);
    } on HandshakeException catch (e) {
      throw ApiException('NETWORK', e.message);
    } on HttpException catch (e) {
      throw ApiException('NETWORK', e.message);
    } catch (e) {
      throw ApiException('NETWORK', e.toString());
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw ApiException('BAD_RESPONSE', 'invalid response');
    }
    if (decoded is! Map) {
      throw ApiException('BAD_RESPONSE', 'invalid response');
    }
    if (decoded['ok'] == true) {
      return decoded['data'];
    }
    throw ApiException(
      (decoded['error'] ?? 'SERVER_ERROR').toString(),
      (decoded['message'] ?? '').toString(),
    );
  }

  // فقط خواندنی‌ها یک بار دوباره امتحان می‌شوند (اتصال کهنه‌ی بسته‌شده)
  Future<String> _send(String url, String body, bool retry) async {
    try {
      return await _run(url, body).timeout(timeout);
    } on TimeoutException {
      rethrow;
    } catch (_) {
      if (!retry) rethrow;
      return await _run(url, body).timeout(timeout);
    }
  }

  Future<String> _run(String url, String body) async {
    _shared.connectionTimeout = timeout;
    var uri = Uri.parse(url);
    final req = await _shared.postUrl(uri);
    req.followRedirects = false;
    req.headers.set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8');
    req.add(utf8.encode(body));
    var res = await req.close();
    // گوگل بعد از POST یک ریدایرکت 302 می‌ده؛ باید با GET دنبالش کنیم.
    var hops = 0;
    while (res.statusCode >= 300 && res.statusCode < 400 && hops < 5) {
      final loc = res.headers.value(HttpHeaders.locationHeader);
      await res.drain<void>();
      if (loc == null || loc.isEmpty) break;
      uri = uri.resolve(loc);
      final r = await _shared.getUrl(uri);
      r.followRedirects = false;
      res = await r.close();
      hops++;
    }
    return await res.transform(utf8.decoder).join();
  }
}
