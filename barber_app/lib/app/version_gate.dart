import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'config.dart';
import 'settings.dart';
import 'widgets.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

List<int> _parts(String v) => v
    .split(RegExp(r'[.+\-]'))
    .map((e) => int.tryParse(e.trim()) ?? 0)
    .toList();

int _cmp(String a, String b) {
  final x = _parts(a), y = _parts(b);
  for (var i = 0; i < 3; i++) {
    final p = i < x.length ? x[i] : 0;
    final q = i < y.length ? y[i] : 0;
    if (p != q) return p < q ? -1 : 1;
  }
  return 0;
}

/// چک نسخه با سرور (`app_version`). اگر سرور چیزی نگوید یا اینترنت نباشد، برنامه عادی کار می‌کند.
/// app: 'manager' یا 'customer'
class VersionGate extends StatefulWidget {
  const VersionGate({super.key, required this.app, required this.child});
  final String app;
  final Widget child;

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  static bool _softShown = false;
  bool _force = false;
  String _url = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final st = SettingsScope.read(context);
      final lang = st.lang;
      final info = await PackageInfo.fromPlatform();
      final cur = info.version;
      final url = st.hasCustomApiUrl ? st.apiUrl : kDefaultApiUrl;
      final r = await ApiClient(url, timeout: const Duration(seconds: 12))
          .call('app_version', {'app': widget.app, 'version': cur});
      if (!mounted || r is! Map) return;
      String g(String k) => (r[k] ?? '').toString().trim();
      final minV = g('min_version');
      final latest = g('latest_version');
      final u = g('update_url');
      final forced = minV.isNotEmpty && _cmp(cur, minV) < 0;
      if (forced) {
        setState(() {
          _force = true;
          _url = u;
        });
        return;
      }
      if (_force) setState(() => _force = false);
      if (latest.isNotEmpty && _cmp(cur, latest) < 0 && !_softShown) {
        _softShown = true;
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(_x(lang, 'نسخهٔ جدید آمده', 'New version available',
                'إصدار جديد متاح')),
            content: Text(_x(
                lang,
                'نسخهٔ $latest منتشر شده. برای بهترین تجربه برنامه را به‌روز کنید.',
                'Version $latest is out. Please update for the best experience.',
                'صدر الإصدار $latest. حدّث التطبيق لأفضل تجربة.')),
            actions: [
              if (u.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: u));
                    Navigator.of(c).pop();
                  },
                  child: Text(_x(lang, 'کپی لینک دانلود', 'Copy download link',
                      'نسخ رابط التنزيل')),
                ),
              FilledButton(
                onPressed: () => Navigator.of(c).pop(),
                child: Text(_x(lang, 'بعداً', 'Later', 'لاحقاً')),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_force) return widget.child;
    final lang = SettingsScope.of(context).lang;
    return GlassScaffold(
      title: _x(lang, 'نیاز به به‌روزرسانی', 'Update required',
          'التحديث مطلوب'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Center(child: GradientIcon(Icons.system_update_rounded, size: 80)),
          const SizedBox(height: 22),
          Text(
            _x(
                lang,
                'این نسخه از برنامه دیگر پشتیبانی نمی‌شود. لطفاً نسخهٔ جدید را نصب کنید.',
                'This version is no longer supported. Please install the new version.',
                'هذا الإصدار لم يعد مدعومًا. يرجى تثبيت الإصدار الجديد.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.7),
          ),
          if (_url.isNotEmpty) ...[
            const SizedBox(height: 14),
            Center(
              child: SelectableText(_url,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: muted(context), fontSize: 12.5)),
            ),
            const SizedBox(height: 14),
            GradientButton(
              icon: Icons.copy_rounded,
              label: _x(lang, 'کپی لینک دانلود', 'Copy download link',
                  'نسخ رابط التنزيل'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _url));
                toast(context,
                    _x(lang, 'لینک کپی شد', 'Link copied', 'تم نسخ الرابط'));
              },
            ),
          ],
          const SizedBox(height: 12),
          GradientButton(
            outlined: true,
            icon: Icons.refresh_rounded,
            label: _x(lang, 'بررسی دوباره', 'Check again', 'تحقق مرة أخرى'),
            onPressed: _check,
          ),
        ],
      ),
    );
  }
}
