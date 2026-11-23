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
  final String baseUrl;
  final Duration timeout;

  ApiClient(this.baseUrl, {this.timeout = const Duration(seconds: 40)});

  /// یک action رو صدا می‌زنه و `data` رو برمی‌گردونه.
  /// در صورت خطا ApiException پرتاب می‌کنه.
  Future<dynamic> call(String action, [Map<String, dynamic>? params]) async {
    final url = baseUrl.trim();
    if (url.isEmpty) {
      throw ApiException('NO_URL', 'server url is empty');
    }

    final body = jsonEncode(<String, dynamic>{...?params, 'action': action});
    final client = HttpClient();
    client.connectionTimeout = timeout;

    String text;
    try {
      text = await _run(client, url, body).timeout(timeout);
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
    } finally {
      client.close(force: true);
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

  Future<String> _run(HttpClient client, String url, String body) async {
    var uri = Uri.parse(url);
    final req = await client.postUrl(uri);
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
      final r = await client.getUrl(uri);
      r.followRedirects = false;
      res = await r.close();
      hops++;
    }

    return await res.transform(utf8.decoder).join();
  }
}
