import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import 'shop_api.dart';

/// وارد کردن لایسنس جدید برای تمدید. در صورت موفقیت true برمی‌گرداند.
class RenewPage extends StatefulWidget {
  const RenewPage({super.key, required this.settings, required this.api});

  final AppSettings settings;
  final ShopApi api;

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage> {
  final _form = GlobalKey<FormState>();
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
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
      await widget.api.renew(_key.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t('renew_done'))));
      Navigator.of(context).pop(true);
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('renew'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.vpn_key, size: 56),
                const SizedBox(height: 12),
                Text(
                  s.t('renew_hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _key,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: s.t('license_key'),
                    helperText: 'XXXX-XXXX-XXXX-XXXX',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? s.t('required')
                      : null,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.t('renew_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
