import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/widgets.dart';
import 'shop_api.dart';

/// با موفقیت که تمام شد `true` برمی‌گرداند.
class RenewPage extends StatefulWidget {
  const RenewPage({super.key, required this.api});
  final ShopApi api;

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage> {
  final _key = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _renew() async {
    final s = S(SettingsScope.read(context).lang);
    if (_key.text.trim().isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.api.renew(_key.text);
      if (!mounted) return;
      toast(context, s.t('renew_ok'));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(SettingsScope.of(context).lang);
    return GlassScaffold(
      title: s.t('renew_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const GradientIcon(Icons.vpn_key_rounded, size: 64),
                const SizedBox(height: 14),
                Text(s.t('renew_desc'),
                    style: TextStyle(color: muted(context))),
                const SizedBox(height: 18),
                GlassField(
                  controller: _key,
                  label: s.t('license_key'),
                  icon: Icons.vpn_key_outlined,
                  ltr: true,
                  onSubmitted: (_) => _renew(),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('renew_btn'),
                  icon: Icons.autorenew_rounded,
                  loading: _loading,
                  onPressed: _renew,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
