import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/settings.dart';
import '../../app/widgets.dart';

String _x(String lang, String fa, String en, String ar) =>
    lang == 'fa' ? fa : (lang == 'ar' ? ar : en);

/// کد یا لینک سرور را به آدرس کامل تبدیل می‌کند. اگر درست نبود null.
String? normalizeServerCode(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return null;
  final q = s.indexOf('?');
  if (q > 0) s = s.substring(0, q);
  final full = RegExp(
      r'^https://script\.google\.com/macros/s/[A-Za-z0-9_\-]+/exec$');
  if (full.hasMatch(s)) return s;
  if (RegExp(r'^[A-Za-z0-9_\-]{20,}$').hasMatch(s)) {
    return 'https://script.google.com/macros/s/$s/exec';
  }
  return null;
}

/// با یک درخواست آزمایشی بررسی می‌کند که سرور جواب می‌دهد
Future<bool> verifyServer(String url) async {
  try {
    final dynamic d = await ApiClient(url).call(
        'app_version', <String, dynamic>{'app': 'manager', 'version': '0.0.0'});
    return d is Map && d.containsKey('v');
  } catch (_) {
    return false;
  }
}

class ServerCodePage extends StatefulWidget {
  const ServerCodePage({super.key});

  @override
  State<ServerCodePage> createState() => _ServerCodePageState();
}

class _ServerCodePageState extends State<ServerCodePage> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = (d?.text ?? '').trim();
    if (t.isNotEmpty && mounted) setState(() => _c.text = t);
  }

  /// بخش آرایشگاه را از نو می‌سازد تا سرور جدید برداشته شود
  Future<void> _restart(AppSettings st, NavigatorState nav) async {
    nav.popUntil((r) => r.isFirst);
    await st.setRole(null);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await st.setRole('shop');
  }

  Future<void> _save() async {
    final st = SettingsScope.read(context);
    final lang = st.lang;
    final url = normalizeServerCode(_c.text);
    if (url == null) {
      toast(
          context,
          _x(lang, 'کد سرور درست نیست', 'The server code is not valid',
              'رمز الخادم غير صحيح'));
      return;
    }
    setState(() => _busy = true);
    final ok = await verifyServer(url);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      toast(
          context,
          _x(
              lang,
              'به این سرور وصل نشد. کد و اینترنت را بررسی کنید',
              'Could not connect to this server. Check the code and your internet',
              'تعذّر الاتصال بهذا الخادم. تحقّق من الرمز والإنترنت'));
      return;
    }
    final nav = Navigator.of(context);
    toast(context, _x(lang, 'ذخیره شد', 'Saved', 'تم الحفظ'));
    await st.setShopToken(null);
    await st.setApiUrl(url);
    await _restart(st, nav);
  }

  Future<void> _remove() async {
    final st = SettingsScope.read(context);
    final nav = Navigator.of(context);
    await st.setShopToken(null);
    await st.setApiUrl(null);
    await _restart(st, nav);
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final lang = st.lang;
    final active = st.hasCustomApiUrl;
    final url = st.apiUrl;
    final tail = url.length > 14 ? url.substring(url.length - 14) : url;

    return GlassScaffold(
      title: _x(lang, 'کد سرور اختصاصی', 'Dedicated server code',
          'رمز الخادم الخاص'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(18),
            child: Text(
              _x(
                  lang,
                  'اگر آرایشگاه شما پلن ویژه، پرو یا شخصی دارد، کدی را که از توسعه‌دهنده گرفته‌اید اینجا وارد کنید. بعد از ذخیره، ورود و ثبت‌نام روی سرور اختصاصی شما انجام می‌شود. آرایشگران شما هم باید قبل از ورود با کد دعوت، همین کد را روی دستگاه خودشان وارد کنند.',
                  'If your shop is on the Special, Pro or Personal plan, enter the code you received from the developer here. After saving, sign-in and sign-up happen on your dedicated server. Your barbers must also enter this same code on their own device before joining with an invite code.',
                  'إذا كان صالونك على باقة مميزة أو برو أو شخصية، فأدخل هنا الرمز الذي استلمته من المطوّر. بعد الحفظ يتم تسجيل الدخول وإنشاء الحساب على خادمك الخاص. وعلى حلاقيك أيضًا إدخال الرمز نفسه على أجهزتهم قبل الانضمام برمز الدعوة.'),
              style: TextStyle(color: muted(context), height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          if (active) ...[
            Glass(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _x(lang, 'کد سرور اختصاصی روی این دستگاه فعال است',
                          'A dedicated server code is active on this device',
                          'رمز الخادم الخاص مفعّل على هذا الجهاز'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('…$tail',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _c,
                  label: _x(lang, 'کد سرور', 'Server code', 'رمز الخادم'),
                  icon: Icons.dns_rounded,
                  ltr: true,
                  suffix: IconButton(
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: _paste,
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: _x(lang, 'ذخیره و بررسی', 'Save and check',
                      'حفظ وتحقق'),
                  icon: Icons.check_circle_outline_rounded,
                  loading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(height: 16),
            GradientButton(
              outlined: true,
              danger: true,
              icon: Icons.link_off_rounded,
              label: _x(lang, 'حذف کد و برگشت به سرور عمومی',
                  'Remove code and use the public server',
                  'حذف الرمز والعودة للخادم العام'),
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
