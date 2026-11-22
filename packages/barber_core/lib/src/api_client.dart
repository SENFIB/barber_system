import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// خطای برگشتی از سرور یا شبکه
class ApiException implements Exception {
  ApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// کلاینت API گوگل اپس‌اسکریپت.
/// گوگل به POST با ریدایرکت ۳۰۲ جواب می‌دهد و پکیج http آن را خودکار دنبال
/// نمی‌کند، پس اینجا دستی دنبال می‌شود.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.token,
    this.timeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final String? token;
  final Duration timeout;

  /// یک اکشن را صدا می‌زند و فقط بخش data را برمی‌گرداند.
  /// در صورت خطا ApiException پرتاب می‌شود.
  Future<dynamic> call(
    String action, [
    Map<String, dynamic> params = const {},
  ]) async {
    if (baseUrl.trim().isEmpty) {
      throw ApiException('NO_URL', 'API url is empty');
    }

    final payload = <String, dynamic>{
      'action': action,
      if (token != null && token!.isNotEmpty) 'token': token,
      ...params,
    };

    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(baseUrl.trim()))
        ..followRedirects = false
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = jsonEncode(payload);

      var res = await http.Response.fromStream(
        await client.send(req).timeout(timeout),
      );

      var hops = 0;
      while (res.statusCode >= 300 && res.statusCode < 400 && hops < 5) {
        final loc = res.headers['location'];
        if (loc == null || loc.isEmpty) break;
        final next = http.Request('GET', Uri.parse(loc))
          ..followRedirects = false;
        res = await http.Response.fromStream(
          await client.send(next).timeout(timeout),
        );
        hops++;
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        throw ApiException(
          'BAD_RESPONSE',
          'Invalid server response (HTTP ${res.statusCode})',
        );
      }

      if (decoded is! Map) {
        throw ApiException('BAD_RESPONSE', 'Invalid server response');
      }
      if (decoded['ok'] == true) {
        return decoded['data'];
      }
      throw ApiException(
        (decoded['error'] ?? 'ERROR').toString(),
        (decoded['message'] ?? 'Unknown error').toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('NETWORK', 'Network error: $e');
    } finally {
      client.close();
    }
  }
}
