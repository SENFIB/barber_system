import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';
import 'manager_home.dart';
import 'renew_page.dart';
import 'shop_api.dart';
import 'shop_auth.dart';

enum _Phase { loading, auth, error, ready }

class ManagerEntry extends StatefulWidget {
  const ManagerEntry({super.key});

  @override
  State<ManagerEntry> createState() => _ManagerEntryState();
}

class _ManagerEntryState extends State<ManagerEntry> {
  late final ShopApi _api;
  _Phase _phase = _Phase.loading;
  ManagerSession? _session;
  String _errMsg = '';

  @override
  void initState() {
    super.initState();
    _api = ShopApi(SettingsScope.read(context));
    _load();
  }

  Future<void> _load() async {
    final st = SettingsScope.read(context);
    if (!st.hasShopToken) {
      setState(() => _phase = _Phase.auth);
      return;
    }
    if (_session == null) setState(() => _phase = _Phase.loading);
    try {
      final sess = await _api.me();
      if (!mounted) return;
      setState(() {
        _session = sess;
        _phase = _Phase.ready;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'UNAUTHORIZED' || e.code == 'DEVICE_MISMATCH') {
        await st.setShopToken(null);
        if (!mounted) return;
        setState(() {
          _session = null;
          _phase = _Phase.auth;
        });
        return;
      }
      setState(() {
        _errMsg = S(st.lang).error(e);
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _onSession(ManagerSession sess) async {
    await SettingsScope.read(context).setShopToken(sess.token);
    if (!mounted) return;
    setState(() {
      _session = sess;
      _phase = _Phase.ready;
    });
  }

  Future<void> _logout() async {
    final st = SettingsScope.read(context);
    try {
      await _api.logout().timeout(const Duration(seconds: 8));
    } catch (_) {}
    await st.setShopToken(null);
    if (!mounted) return;
    setState(() {
      _session = null;
      _phase = _Phase.auth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);

    switch (_phase) {
      case _Phase.loading:
        return const GlassScaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case _Phase.auth:
        return ShopAuthPage(api: _api, onSession: _onSession);

      case _Phase.error:
        return GlassScaffold(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => st.setRole(null),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Glass(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 54, color: AppColors.amber),
                    const SizedBox(height: 14),
                    Text(_errMsg, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: s.t('retry'),
                      icon: Icons.refresh_rounded,
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case _Phase.ready:
        final sess = _session!;
        final sub = sess.subscription;
        if (sub.isExpired || sub.isDeactive) {
          return _BlockedView(
            session: sess,
            api: _api,
            onRenewed: _load,
            onLogout: _logout,
          );
        }
        return ManagerHome(
          ctx: ShopCtx(
            api: _api,
            session: sess,
            reload: _load,
            logout: _logout,
          ),
        );
    }
  }
}

class _BlockedView extends StatelessWidget {
  const _BlockedView({
    required this.session,
    required this.api,
    required this.onRenewed,
    required this.onLogout,
  });

  final ManagerSession session;
  final ShopApi api;
  final Future<void> Function() onRenewed;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final s = S(SettingsScope.of(context).lang);
    final deactive = session.subscription.isDeactive;
    return GlassScaffold(
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Glass(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientIcon(
                  deactive ? Icons.block_rounded : Icons.lock_clock_rounded,
                  size: 70,
                  gradient: AppColors.dangerGradient,
                ),
                const SizedBox(height: 16),
                Text(
                  s.t(deactive ? 'deactive_title' : 'expired_title'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  deactive
                      ? s.t('deactive_msg')
                      : s.t(session.isOwner ? 'expired_owner' : 'expired_staff'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted(context), height: 1.6),
                ),
                const SizedBox(height: 22),
                if (!deactive && session.isOwner) ...[
                  GradientButton(
                    label: s.t('renew'),
                    icon: Icons.autorenew_rounded,
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => RenewPage(api: api)),
                      );
                      if (ok == true) await onRenewed();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                GradientButton(
                  outlined: true,
                  label: s.t('logout'),
                  icon: Icons.logout_rounded,
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
