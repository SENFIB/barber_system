import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../app/config.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_ex.dart';
import '../../app/widgets.dart';
import '../manager/shop_api.dart';
import 'appearance_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';
  int _taps = 0;
  bool _showServer = false;
  bool _testing = false;
  final _urlC = TextEditingController();

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      // فقط شماره‌ی نسخه؛ بدون شماره‌ی build
      if (mounted) setState(() => _version = p.version);
    });
  }

  @override
  void dispose() {
    _urlC.dispose();
    super.dispose();
  }

  void _tapVersion() {
    _taps++;
    if (_taps >= 7 && !_showServer) {
      final st = SettingsScope.read(context);
      setState(() {
        _showServer = true;
        _urlC.text = st.hasCustomApiUrl ? st.apiUrl : '';
      });
    }
  }

  Future<void> _saveUrl() async {
    final st = SettingsScope.read(context);
    final s = S(st.lang);
    final newUrl = _urlC.text.trim();
    final changed = newUrl != (st.hasCustomApiUrl ? st.apiUrl : '');
    await st.setApiUrl(newUrl.isEmpty ? null : newUrl);
    if (changed) await st.setShopToken(null); // توکن مال سرور قبلی بود
    if (mounted) toast(context, s.t('saved'));
  }

  Future<void> _test() async {
    final st = SettingsScope.read(context);
    final s = S(st.lang);
    final url = _urlC.text.trim().isEmpty ? kDefaultApiUrl : _urlC.text.trim();
    setState(() => _testing = true);
    try {
      await ApiClient(url, timeout: const Duration(seconds: 25))
          .call('app_version', {'app': 'manager', 'version': '1.0.0'});
      if (mounted) toast(context, s.t('conn_ok'));
    } on ApiException catch (e) {
      if (mounted) toast(context, '${s.t('conn_fail')}: ${s.error(e)}');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _deleteData() async {
    final st = SettingsScope.read(context);
    final s = S(st.lang);
    var resetId = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(s.t('delete_data_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('delete_data_msg')),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: resetId,
                onChanged: (v) => setD(() => resetId = v ?? false),
                title: Text(s.t('delete_device_id')),
                subtitle: Text(s.t('delete_device_id_desc')),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(s.t('cancel'))),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(s.t('delete'),
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final msg = s.t('data_deleted');
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (st.hasShopToken) {
      try {
        await ShopApi(st).logout().timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    await st.clearAll(resetDeviceId: resetId);
    nav.popUntil((r) => r.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _row(String k, String v, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: TextStyle(color: muted(context))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    final x = X(st.lang);
    final roleText = st.role == 'shop'
        ? s.t('role_shop')
        : st.role == 'customer'
            ? s.t('role_customer')
            : s.t('sd_none');
    final themeText = st.themeKey == 'light'
        ? s.t('theme_light')
        : st.themeKey == 'dark'
            ? s.t('theme_dark')
            : s.t('theme_system');
    final langText = st.lang == 'fa'
        ? 'فارسی'
        : st.lang == 'ar'
            ? 'العربية'
            : 'English';
    final dev = st.deviceId;
    final devShort = dev.length > 8 ? '${dev.substring(0, 8)}…' : dev;

    return GlassScaffold(
      title: s.t('settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          SectionLabel(s.t('language')),
          Glass(
            child: SegmentPicker<String>(
              options: [
                MapEntry('fa', 'فارسی'),
                MapEntry('en', 'English'),
                MapEntry('ar', 'العربية'),
              ],
              value: st.lang,
              onChanged: st.setLanguage,
            ),
          ),
          SectionLabel(s.t('theme')),
          Glass(
            child: SegmentPicker<String>(
              options: [
                MapEntry('system', s.t('theme_system')),
                MapEntry('light', s.t('theme_light')),
                MapEntry('dark', s.t('theme_dark')),
              ],
              value: st.themeKey,
              onChanged: st.setThemeKey,
            ),
          ),
          const SizedBox(height: 18),
          Glass(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            ),
            child: Row(
              children: [
                const GradientIcon(Icons.palette_rounded, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(x.t('appearance'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(x.t('appearance_desc'),
                          style: TextStyle(
                              color: muted(context), fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(chevron(context), color: muted(context)),
              ],
            ),
          ),
          if (st.role != null) ...[
            const SizedBox(height: 14),
            Glass(
              onTap: () async {
                final nav = Navigator.of(context);
                await st.setRole(null);
                nav.popUntil((r) => r.isFirst);
              },
              child: Row(
                children: [
                  const GradientIcon(Icons.swap_horiz_rounded, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.t('change_role'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(s.t('change_role_desc'),
                            style: TextStyle(
                                color: muted(context), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Icon(chevron(context), color: muted(context)),
                ],
              ),
            ),
          ],
          SectionLabel(s.t('saved_data')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('saved_data_desc'),
                    style: TextStyle(
                        color: muted(context), fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 10),
                _row(s.t('sd_language'), langText),
                _row(s.t('sd_role'), roleText),
                _row(s.t('sd_theme'), themeText),
                _row(
                    x.t('sd_look'),
                    st.look.isCustom
                        ? x.t('sd_look_custom')
                        : x.t('sd_look_default')),
                _row(s.t('sd_device'), devShort, ltr: true),
                _row(s.t('sd_session'),
                    st.hasShopToken ? s.t('sd_yes') : s.t('sd_no')),
                _row(s.t('sd_server'),
                    st.hasCustomApiUrl ? s.t('sd_custom') : s.t('sd_builtin')),
                const SizedBox(height: 14),
                GradientButton(
                  danger: true,
                  icon: Icons.delete_outline_rounded,
                  label: s.t('delete_data'),
                  onPressed: _deleteData,
                ),
              ],
            ),
          ),
          if (_showServer) ...[
            SectionLabel(s.t('server_section')),
            Glass(
              child: Column(
                children: [
                  GlassField(
                    controller: _urlC,
                    label: s.t('server_url'),
                    icon: Icons.link_rounded,
                    ltr: true,
                    keyboard: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(s.t('server_hint'),
                        style:
                            TextStyle(color: muted(context), fontSize: 12.5)),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                      label: s.t('save'),
                      icon: Icons.save_rounded,
                      compact: true,
                      onPressed: _saveUrl),
                  const SizedBox(height: 10),
                  GradientButton(
                    label: s.t('test_conn'),
                    icon: Icons.wifi_tethering_rounded,
                    outlined: true,
                    compact: true,
                    loading: _testing,
                    onPressed: _test,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tapVersion,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${x.t('version')} $_version',
                  style: TextStyle(color: muted(context), fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
