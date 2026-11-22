import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../settings/settings_page.dart';
import 'manager_home.dart';
import 'renew_page.dart';
import 'shop_api.dart';
import 'shop_auth.dart';

enum _Phase { loading, auth, error, ready }

/// ورودی بخش آرایشگاه: بررسی توکن ذخیره‌شده، ورود، صفحه‌ی اصلی یا صفحه‌ی قفل
class ManagerEntry extends StatefulWidget {
  const ManagerEntry({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<ManagerEntry> createState() => _ManagerEntryState();
}

class _ManagerEntryState extends State<ManagerEntry> {
  late final ShopApi _api = ShopApi(widget.settings);
  _Phase _phase = _Phase.loading;
  ManagerSession? _session;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final st = widget.settings;
    if (!st.hasShopToken) {
      setState(() => _phase = _Phase.auth);
      return;
    }
    setState(() => _phase = _Phase.loading);
    try {
      final session = await _api.me();
      if (!mounted) return;
      setState(() {
        _session = session;
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
      } else {
        setState(() {
          _error = S(st.lang).error(e);
          _phase = _Phase.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _onLoggedIn(ManagerSession session) async {
    await widget.settings.setShopToken(session.token);
    if (!mounted) return;
    setState(() {
      _session = session;
      _phase = _Phase.ready;
    });
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // خروج حتی بدون اینترنت انجام می‌شود
    }
    await widget.settings.setShopToken(null);
    if (!mounted) return;
    setState(() {
      _session = null;
      _phase = _Phase.auth;
    });
  }

  Future<void> _openRenew() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RenewPage(settings: widget.settings, api: _api),
      ),
    );
    if (ok == true) _boot();
  }

  Widget _body(S s) {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56),
                const SizedBox(height: 12),
                Text(_error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _boot,
                  child: Text(s.t('retry')),
                ),
              ],
            ),
          ),
        );
      case _Phase.auth:
        return ShopAuthOptions(
          settings: widget.settings,
          api: _api,
          onLoggedIn: _onLoggedIn,
        );
      case _Phase.ready:
        final session = _session!;
        if (!session.subscription.isActive) {
          return _BlockedView(
            s: s,
            session: session,
            onRenew: _openRenew,
            onLogout: _logout,
          );
        }
        return ManagerHome(
          settings: widget.settings,
          session: session,
          onRenew: _openRenew,
          onLogout: _logout,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.settings.lang);
    final name = _session?.shop.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase == _Phase.ready && name.isNotEmpty
            ? name
            : s.t('shop')),
        actions: [
          if (_phase == _Phase.ready)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: s.t('refresh'),
              onPressed: _boot,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: s.t('settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsPage(settings: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: _body(s),
    );
  }
}

/// صفحه‌ی قفل: اشتراک تمام شده یا غیرفعال است
class _BlockedView extends StatelessWidget {
  const _BlockedView({
    required this.s,
    required this.session,
    required this.onRenew,
    required this.onLogout,
  });

  final S s;
  final ManagerSession session;
  final VoidCallback onRenew;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final expired = session.subscription.isExpired;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.lock_clock, size: 72),
            const SizedBox(height: 16),
            Text(
              s.t(expired ? 'expired_title' : 'deactive_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              s.t(expired
                  ? (session.isOwner
                      ? 'expired_owner_desc'
                      : 'expired_staff_desc')
                  : 'deactive_desc'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (expired && session.isOwner) ...[
              FilledButton.icon(
                onPressed: onRenew,
                icon: const Icon(Icons.vpn_key),
                label: Text(s.t('renew')),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: Text(s.t('logout')),
            ),
          ],
        ),
      ),
    );
  }
}
