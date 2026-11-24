import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/registry.dart';

/// باکس «ارسال پیام به توسعه‌دهنده».
/// فقط وقتی kRegistryUrl پر باشد نمایش داده می‌شود (ارسال از طریق پروژهٔ Registry).
class ContactBox extends StatefulWidget {
  final String lang;
  const ContactBox({super.key, required this.lang});

  @override
  State<ContactBox> createState() => _ContactBoxState();
}

class _ContactBoxState extends State<ContactBox> {
  final _email = TextEditingController();
  final _msg = TextEditingController();
  bool _busy = false;
  bool _ok = false;
  String? _result;

  String _p(String fa, String en, String ar) =>
      widget.lang == 'ar' ? ar : (widget.lang == 'en' ? en : fa);

  @override
  void dispose() {
    _email.dispose();
    _msg.dispose();
    super.dispose();
  }

  bool _validEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s) && s.length <= 120;

  /// POST به اسکریپت گوگل؛ ریدایرکت ۳۰۲ را دستی دنبال می‌کند.
  Future<Map<String, dynamic>?> _post(Map<String, dynamic> body) async {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await c.postUrl(Uri.parse(kRegistryUrl.trim()));
      req.followRedirects = false;
      req.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      req.add(utf8.encode(jsonEncode(body)));
      var res = await req.close().timeout(const Duration(seconds: 25));
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
        final r2 = await c.getUrl(Uri.parse(loc));
        r2.followRedirects = false;
        res = await r2.close().timeout(const Duration(seconds: 25));
        hops++;
      }
      final text = await res.transform(utf8.decoder).join();
      final j = jsonDecode(text);
      if (j is Map<String, dynamic>) return j;
      return null;
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    final msg = _msg.text.trim();
    if (!_validEmail(email)) {
      setState(() {
        _ok = false;
        _result = _p('ایمیل را درست وارد کنید.', 'Please enter a valid email.',
            'يرجى إدخال بريد إلكتروني صحيح.');
      });
      return;
    }
    if (msg.length < 5) {
      setState(() {
        _ok = false;
        _result = _p('متن پیام را بنویسید.', 'Please write your message.',
            'يرجى كتابة الرسالة.');
      });
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    final j = await _post({
      'action': 'contact_send',
      'email': email,
      'message': msg,
      'lang': widget.lang,
    });
    if (!mounted) return;
    if (j != null && j['ok'] == true) {
      _msg.clear();
      setState(() {
        _busy = false;
        _ok = true;
        _result = _p('پیام شما ارسال شد. با ایمیلی که نوشتید پاسخ می‌دهیم.',
            'Your message was sent. We will reply to the email you entered.',
            'تم إرسال رسالتك. سنرد على البريد الذي أدخلته.');
      });
    } else {
      final code = j == null ? '' : '${j['code'] ?? ''}';
      setState(() {
        _busy = false;
        _ok = false;
        _result = code == 'TOO_MANY'
            ? _p('تعداد پیام‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.',
                'Too many messages; please try again later.',
                'عدد الرسائل كبير؛ حاول مجددًا لاحقًا.')
            : _p('ارسال نشد. اینترنت را بررسی کنید و دوباره تلاش کنید.',
                'Could not send. Check your connection and try again.',
                'تعذّر الإرسال. تحقق من الاتصال وحاول مجددًا.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kRegistryUrl.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              _p('ارسال پیام به توسعه‌دهنده', 'Message the developer',
                  'مراسلة المطوّر'),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: cs.primary)),
          const SizedBox(height: 4),
          Text(
              _p('ایمیل خودتان و متن پیام را بنویسید؛ پاسخ به ایمیل شما می‌آید.',
                  'Enter your email and message; the reply will come to your email.',
                  'اكتب بريدك ورسالتك؛ سيصلك الرد على بريدك.'),
              style: TextStyle(
                  fontSize: 12.5, color: cs.onSurface.withOpacity(0.65))),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: _p('ایمیل شما', 'Your email', 'بريدك الإلكتروني'),
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _msg,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: _p('متن پیام', 'Your message', 'نص الرسالة'),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_p('ارسال', 'Send', 'إرسال')),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            Text(_result!,
                style: TextStyle(
                    fontSize: 13, color: _ok ? Colors.green : cs.error)),
          ],
        ],
      ),
    );
  }
}
