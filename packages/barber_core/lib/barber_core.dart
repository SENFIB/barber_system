library barber_core;

export 'src/api_client.dart';
export 'src/models.dart';
```

### `packages/barber_core/lib/src/api_client.dart`
```dart
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

class ApiClient {
  ApiClient(this.baseUrl, {this.timeout = const Duration(seconds: 40)});

  final String baseUrl;
  final Duration timeout;

  /// فراخوانی یک action روی Apps Script. data را برمی‌گرداند یا ApiException می‌اندازد.
  Future<dynamic> call(String action, [Map<String, dynamic>? params]) async {
    if (baseUrl.trim().isEmpty) throw ApiException('NO_URL');
    final body = jsonEncode({...?params, 'action': action});

    String text;
    try {
      text = await _post(Uri.parse(baseUrl.trim()), body).timeout(timeout);
    } catch (e) {
      throw ApiException('NETWORK', e.toString());
    }

    dynamic j;
    try {
      j = jsonDecode(text);
    } catch (_) {
      throw ApiException('BAD_RESPONSE');
    }
    if (j is! Map) throw ApiException('BAD_RESPONSE');
    if (j['ok'] == true) return j['data'];
    throw ApiException(
      (j['error'] ?? 'SERVER_ERROR').toString(),
      (j['message'] ?? '').toString(),
    );
  }

  // گوگل به POST جواب 302 می‌دهد؛ ریدایرکت را دستی با GET دنبال می‌کنیم.
  Future<String> _post(Uri url, String body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final bytes = utf8.encode(body);
      final req = await client.postUrl(url);
      req.followRedirects = false;
      req.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      req.contentLength = bytes.length;
      req.add(bytes);
      var res = await req.close();

      var hops = 0;
      while ({301, 302, 303, 307, 308}.contains(res.statusCode) && hops < 5) {
        final loc = res.headers.value('location');
        if (loc == null) break;
        await res.drain<void>();
        url = url.resolve(loc);
        final r2 = await client.getUrl(url);
        r2.followRedirects = false;
        res = await r2.close();
        hops++;
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
