import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import 'shop_api.dart';

typedef LoggedIn = Future<void> Function(ManagerSession session);

/// سه گزینه‌ی ورود آرایشگاه
class ShopAuthOptions extends StatelessWidget {
  const ShopAuthOptions({
    super.key,
    required this.settings,
    required this.api,
    required this.onLoggedIn,
  });

  final AppSettings settings;
  final ShopApi api;
  final LoggedIn onLoggedIn;

  @override
  Widget build(BuildContext context) {
    final s = S(settings.lang);

    void open(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.storefront, size: 64),
            const SizedBox(height: 16),
            Text(
              s.t('shop_auth_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _OptionCard(
              icon: Icons.add_business,
              title: s.t('opt_new_owner'),
              subtitle: s.t('opt_new_owner_desc'),
              onTap: () => open(RegisterPage(
                  settings: settings, api: api, onLoggedIn: onLoggedIn)),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.login,
              title: s.t('opt_login'),
              subtitle: s.t('opt_login_desc'),
              onTap: () => open(LoginPage(
                  settings: settings, api: api, onLoggedIn: onLoggedIn)),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.content_cut,
              title: s.t('opt_staff'),
              subtitle: s.t('opt_staff_desc'),
              onTap: () => open(JoinPage(
                  settings: settings, api: api, onLoggedIn: onLoggedIn)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ابزارهای مشترک فرم‌ها
// ---------------------------------------------------------------------------

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.formKey,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.s,
    required this.controller,
    required this.label,
    this.helper,
    this.ltr = false,
    this.obscure = false,
    this.optional = false,
    this.keyboard,
    this.minLen = 0,
  });

  final S s;
  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool ltr;
  final bool obscure;
  final bool optional;
  final TextInputType? keyboard;
  final int minLen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        textDirection: ltr ? TextDirection.ltr : null,
        textAlign: ltr ? TextAlign.left : TextAlign.start,
        autocorrect: !ltr && !obscure,
        enableSuggestions: !ltr && !obscure,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final t = (v ?? '').trim();
          if (!optional && t.isEmpty) return s.t('required');
          if (minLen > 0 && (v ?? '').length < minLen) {
            return s.t('password_hint');
          }
          return null;
        },
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text!, style: TextStyle(color: cs.onErrorContainer)),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ثبت‌نام صاحب آرایشگاه جدید
// ---------------------------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.settings,
    required this.api,
    required this.onLoggedIn,
  });

  final AppSettings settings;
  final ShopApi api;
  final LoggedIn onLoggedIn;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _license = TextEditingController();
  final _shopName = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _ownerName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isBarber = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _license.dispose();
    _shopName.dispose();
    _phone.dispose();
    _city.dispose();
    _ownerName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = S(widget.settings.lang);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.api.register(
        licenseKey: _license.text,
        shopName: _shopName.text,
        phone: _phone.text,
        username: _username.text,
        password: _password.text,
        city: _city.text,
        ownerName: _ownerName.text,
        ownerIsBarber: _isBarber,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      await widget.onLoggedIn(session);
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = s.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.settings.lang);
    return _FormShell(
      title: s.t('opt_new_owner'),
      formKey: _form,
      children: [
        _Field(
          s: s,
          controller: _license,
          label: s.t('license_key'),
          helper: 'XXXX-XXXX-XXXX-XXXX',
          ltr: true,
        ),
        _Field(s: s, controller: _shopName, label: s.t('shop_name')),
        _Field(
          s: s,
          controller: _phone,
          label: s.t('phone'),
          ltr: true,
          keyboard: TextInputType.phone,
        ),
        _Field(s: s, controller: _city, label: s.t('city'), optional: true),
        _Field(
          s: s,
          controller: _ownerName,
          label: s.t('owner_name'),
          optional: true,
        ),
        _Field(
          s: s,
          controller: _username,
          label: s.t('username'),
          helper: s.t('username_hint'),
          ltr: true,
        ),
        _Field(
          s: s,
          controller: _password,
          label: s.t('password'),
          helper: s.t('password_hint'),
          ltr: true,
          obscure: true,
          minLen: 6,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.t('owner_is_barber')),
          value: _isBarber,
          onChanged: (v) => setState(() => _isBarber = v),
        ),
        const SizedBox(height: 8),
        _ErrorBox(_error),
        _SubmitButton(
          label: s.t('register_btn'),
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ورود با نام کاربری و رمز
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.settings,
    required this.api,
    required this.onLoggedIn,
  });

  final AppSettings settings;
  final ShopApi api;
  final LoggedIn onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = S(widget.settings.lang);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.api.login(_username.text, _password.text);
      if (!mounted) return;
      final nav = Navigator.of(context);
      await widget.onLoggedIn(session);
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = s.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.settings.lang);
    return _FormShell(
      title: s.t('opt_login'),
      formKey: _form,
      children: [
        _Field(
          s: s,
          controller: _username,
          label: s.t('username'),
          ltr: true,
        ),
        _Field(
          s: s,
          controller: _password,
          label: s.t('password'),
          ltr: true,
          obscure: true,
        ),
        const SizedBox(height: 8),
        _ErrorBox(_error),
        _SubmitButton(
          label: s.t('login_btn'),
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// پیوستن آرایشگر با کد دعوت
// ---------------------------------------------------------------------------

class JoinPage extends StatefulWidget {
  const JoinPage({
    super.key,
    required this.settings,
    required this.api,
    required this.onLoggedIn,
  });

  final AppSettings settings;
  final ShopApi api;
  final LoggedIn onLoggedIn;

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = S(widget.settings.lang);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.api.join(
        inviteCode: _code.text,
        username: _username.text,
        password: _password.text,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      await widget.onLoggedIn(session);
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = s.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.settings.lang);
    return _FormShell(
      title: s.t('opt_staff'),
      formKey: _form,
      children: [
        _Field(
          s: s,
          controller: _code,
          label: s.t('invite_code'),
          helper: 'XXXX-XXXX',
          ltr: true,
        ),
        _Field(
          s: s,
          controller: _username,
          label: s.t('username'),
          helper: s.t('username_hint'),
          ltr: true,
        ),
        _Field(
          s: s,
          controller: _password,
          label: s.t('password'),
          helper: s.t('password_hint'),
          ltr: true,
          obscure: true,
          minLen: 6,
        ),
        const SizedBox(height: 8),
        _ErrorBox(_error),
        _SubmitButton(
          label: s.t('join_btn'),
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

