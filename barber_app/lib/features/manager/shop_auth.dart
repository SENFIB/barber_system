import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';
import 'shop_api.dart';

typedef SessionCallback = Future<void> Function(ManagerSession session);

// ───────────────────────── صفحه‌ی ورود (اول) ─────────────────────────
class ShopAuthPage extends StatefulWidget {
  const ShopAuthPage({super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  State<ShopAuthPage> createState() => _ShopAuthPageState();
}

class _ShopAuthPageState extends State<ShopAuthPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final s = S(SettingsScope.read(context).lang);
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    if (!usernameOk(_user.text)) {
      toast(context, s.t('v_username'));
      return;
    }
    setState(() => _loading = true);
    try {
      final sess = await widget.api.login(_user.text, _pass.text);
      await widget.onSession(sess);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    return GlassScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Center(child: AppLogo()),
          const SizedBox(height: 18),
          Center(
            child: Text(s.t('shop_panel'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(s.t('shop_panel_sub'),
                style: TextStyle(color: muted(context))),
          ),
          const SizedBox(height: 24),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  onSubmitted: (_) => _login(),
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('login_btn'),
                  icon: Icons.login_rounded,
                  loading: _loading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(s.t('no_account'),
                    style: TextStyle(color: muted(context))),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            outlined: true,
            icon: Icons.person_add_alt_1_rounded,
            label: s.t('signup'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SignupChoicePage(
                  api: widget.api, onSession: widget.onSession),
            )),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── انتخاب نوع ثبت‌نام ─────────────────────────
class SignupChoicePage extends StatelessWidget {
  const SignupChoicePage(
      {super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  Widget build(BuildContext context) {
    final s = S(SettingsScope.of(context).lang);

    Widget card(IconData icon, String title, String desc, VoidCallback onTap) {
      return Glass(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GradientIcon(icon, size: 58),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(color: muted(context), height: 1.5)),
                ],
              ),
            ),
            Icon(chevron(context), color: muted(context)),
          ],
        ),
      );
    }

    return GlassScaffold(
      title: s.t('signup_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          card(
            Icons.storefront_rounded,
            s.t('signup_owner'),
            s.t('signup_owner_desc'),
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OwnerSignupPage(api: api, onSession: onSession),
            )),
          ),
          const SizedBox(height: 14),
          card(
            Icons.content_cut_rounded,
            s.t('signup_staff'),
            s.t('signup_staff_desc'),
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StaffJoinPage(api: api, onSession: onSession),
            )),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── ثبت‌نام صاحب آرایشگاه ─────────────────────────
class OwnerSignupPage extends StatefulWidget {
  const OwnerSignupPage(
      {super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  State<OwnerSignupPage> createState() => _OwnerSignupPageState();
}

class _OwnerSignupPageState extends State<OwnerSignupPage> {
  final _license = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _ownerName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _barber = true;
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _license, _shop, _phone, _ownerName, _address, _city, _user, _pass
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(S s) {
    if (_license.text.trim().isEmpty ||
        _shop.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _user.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      return s.t('v_required');
    }
    final digits = normalizeDigits(_phone.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) return s.t('v_phone');
    if (!usernameOk(_user.text)) return s.t('v_username');
    if (_pass.text.length < 6) return s.t('v_password');
    return null;
  }

  Future<void> _submit() async {
    final s = S(SettingsScope.read(context).lang);
    final err = _validate(s);
    if (err != null) {
      toast(context, err);
      return;
    }
    setState(() => _loading = true);
    try {
      final sess = await widget.api.register(
        licenseKey: _license.text,
        shopName: _shop.text,
        phone: _phone.text,
        username: _user.text,
        password: _pass.text,
        address: _address.text,
        city: _city.text,
        ownerName: _ownerName.text,
        ownerIsBarber: _barber,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      await widget.onSession(sess);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _gap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    final s = S(SettingsScope.of(context).lang);
    return GlassScaffold(
      title: s.t('signup_owner'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _license,
                  label: s.t('license_key'),
                  icon: Icons.vpn_key_rounded,
                  ltr: true,
                ),
                _gap(),
                GlassField(
                  controller: _shop,
                  label: s.t('shop_name'),
                  icon: Icons.storefront_rounded,
                ),
                _gap(),
                GlassField(
                  controller: _phone,
                  label: s.t('phone'),
                  icon: Icons.phone_rounded,
                  keyboard: TextInputType.phone,
                  ltr: true,
                ),
                _gap(),
                GlassField(
                  controller: _city,
                  label: s.t('city'),
                  icon: Icons.location_city_rounded,
                ),
                _gap(),
                GlassField(
                  controller: _address,
                  label: s.t('address'),
                  icon: Icons.place_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _ownerName,
                  label: s.t('owner_name'),
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _barber,
                  onChanged: (v) => setState(() => _barber = v),
                  title: Text(s.t('i_am_barber')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                _gap(),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: s.t('create_shop'),
            icon: Icons.check_circle_outline_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── ورود آرایشگر با کد دعوت ─────────────────────────
class StaffJoinPage extends StatefulWidget {
  const StaffJoinPage({super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  State<StaffJoinPage> createState() => _StaffJoinPageState();
}

class _StaffJoinPageState extends State<StaffJoinPage> {
  final _code = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S(SettingsScope.read(context).lang);
    if (_code.text.trim().isEmpty ||
        _user.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    if (!usernameOk(_user.text)) {
      toast(context, s.t('v_username'));
      return;
    }
    if (_pass.text.length < 6) {
      toast(context, s.t('v_password'));
      return;
    }
    setState(() => _loading = true);
    try {
      final sess = await widget.api.join(_code.text, _user.text, _pass.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      await widget.onSession(sess);
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
      title: s.t('join_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _code,
                  label: s.t('invite_code'),
                  icon: Icons.confirmation_number_outlined,
                  ltr: true,
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('join_btn'),
                  icon: Icons.login_rounded,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
