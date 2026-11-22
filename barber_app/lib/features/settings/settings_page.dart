import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/platform.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../onboarding/language_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _url =
      TextEditingController(text: widget.settings.apiUrl);
  String _version = '...';
  bool _testing = false;

  // بخش سرور مخفی است؛ با ۷ بار زدن روی نسخه باز می‌شود (برای پلن شخصی)
  int _taps = 0;
  bool _showServer = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String _langName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'فارسی';
    }
  }

  void _onVersionTap() {
    if (_showServer) return;
    _taps++;
    if (_taps >= 7) {
      setState(() => _showServer = true);
    }
  }

  Future<void> _test() async {
    final st = widget.settings;
    final s = S(st.lang);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _testing = true);
    await st.setApiUrl(_url.text);

    String msg;
    try {
      final data = await ApiClient(baseUrl: st.apiUrl).call('app_version');
      final latest = data is Map ? (data['latest'] ?? '') : '';
      msg = '${s.t('connection_ok')}  $latest';
    } on ApiException catch (e) {
      final m = e.code == 'NO_URL' ? s.t('no_url') : '${e.code}: ${e.message}';
      msg = '${s.t('connection_fail')}\n$m';
    }

    if (!mounted) return;
    _url.text = st.apiUrl;
    setState(() => _testing = false);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.settings;
    return ListenableBuilder(
      listenable: st,
      builder: (context, _) {
        final s = S(st.lang);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('settings'))),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(s.t('language')),
                    subtitle: Text(_langName(st.lang)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LanguagePage(settings: st, fromSettings: true),
                      ),
                    ),
                  ),
                  // تغییر نقش فقط در موبایل (ویندوز فقط آرایشگاه است)
                  if (!isWindowsApp)
                    ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: Text(s.t('change_role')),
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await st.setRole(null);
                        nav.popUntil((r) => r.isFirst);
                      },
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(s.t('theme'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(s.t('theme_system')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(s.t('theme_light')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(s.t('theme_dark')),
                      ),
                    ],
                    selected: {st.themeMode},
                    onSelectionChanged: (v) => st.setThemeMode(v.first),
                  ),
                  if (_showServer) ...[
                    const Divider(height: 32),
                    Text(s.t('server'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _url,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: s.t('api_url'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: Text(s.t('test_connection')),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onVersionTap,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${s.t('version')}: $_version',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
