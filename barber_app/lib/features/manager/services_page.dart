import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/biz_panel.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_m.dart';
import '../../app/theme.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'service_presets_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.ctx});
  final ShopCtx ctx;
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  bool _loading = true;
  bool _busy = false;
  String? _err;
  List<Map<String, dynamic>> _list = [];
  late BizPanel _panel;

  M get _m => M(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    _panel = BizPanel.of(widget.ctx.session.shop.bizType);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _lost(ApiException e) => const {
        'UNAUTHORIZED',
        'DEVICE_MISMATCH',
        'SUBSCRIPTION_EXPIRED',
        'SHOP_DEACTIVATED',
      }.contains(e.code);

  Future<void> _load() async {
    final raw = ShopRaw(SettingsScope.read(context));
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      try {
        final me = await raw.call('me');
        final sh = me['shop'];
        if (sh is Map && '${sh['biz_type'] ?? ''}'.isNotEmpty) {
          _panel = BizPanel.of('${sh['biz_type']}');
        }
      } catch (_) {}
      final l = await widget.ctx.api.serviceList();
      if (!mounted) return;
      setState(() {
        _list = l;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_lost(e)) {
        Navigator.of(context).pop();
        widget.ctx.reload();
        return;
      }
      setState(() {
        _err = _m.error(e);
        _loading = false;
      });
    }
  }

  Future<void> _act(Future<void> Function() fn, String okMsg) async {
    final m = _m;
    setState(() => _busy = true);
    try {
      await fn();
      if (!mounted) return;
      toast(context, okMsg);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_lost(e)) {
        Navigator.of(context).pop();
        widget.ctx.reload();
        return;
      }
      toast(context, m.error(e));
    }
    if (mounted) {
      setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _presets() async {
    final st = SettingsScope.read(context);
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ServicePresetsPage(settings: st)),
    );
    if (ok == true && mounted) await _load();
  }

  Future<void> _edit([Map<String, dynamic>? ex]) async {
    final m = _m;
    final exId = ex == null ? '' : '${ex['service_id']}';
    final r = await showDialog<_SvcResult>(
      context: context,
      builder: (_) => _ServiceDialog(
        m: m,
        icon: _panel.icon,
        existing: ex,
        others:
            _list.where((e) => '${e['service_id']}' != exId).toList(),
      ),
    );
    if (r == null) return;
    await _act(
      () => widget.ctx.api
          .serviceSave(
            serviceId: exId.isEmpty ? null : exId,
            name: r.name,
            durationMin: r.duration,
            price: r.price,
            combinableWith: r.combinable,
          )
          .then((_) {}),
      m.t('svc_saved'),
    );
  }

  Future<void> _remove(String id) async {
    final m = _m;
    final ok = await confirmDialog(
      context,
      title: m.t('remove'),
      message: m.t('svc_remove_confirm'),
      okLabel: m.t('remove'),
      cancelLabel: m.t('cancel'),
      danger: true,
    );
    if (!ok) return;
    await _act(() => widget.ctx.api.serviceRemove(id), m.t('svc_removed'));
  }

  List<String> _ids(dynamic v) {
    if (v is List) return v.map((e) => '$e').toList();
    return const [];
  }

  Widget _card(Map<String, dynamic> sv, M m) {
    final id = '${sv['service_id'] ?? ''}';
    final name = '${sv['name'] ?? ''}';
    final dur = int.tryParse('${sv['duration_min']}') ?? 0;
    final price = num.tryParse('${sv['price']}') ?? 0;
    final names = {for (final e in _list) '${e['service_id']}': '${e['name']}'};
    final comb = _ids(sv['combinable_with'])
        .map((c) => names[c] ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        onTap: _busy ? null : () => _edit(sv),
        child: Row(
          children: [
            GradientIcon(_panel.icon, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Pill('$dur ${m.t('min_unit')}', color: AppColors.blue),
                      Pill(
                        '${fmtNum(price)} ${m.t('cur_default')}'.trim(),
                        color: AppColors.green,
                      ),
                    ],
                  ),
                  if (comb.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${m.t('svc_combinable')}: ${comb.join('، ')}',
                      style: TextStyle(color: muted(context), fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: m.t('remove'),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red),
              onPressed: _busy ? null : () => _remove(id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final m = M(lang);
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Glass(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_err!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                GradientButton(
                  compact: true,
                  label: m.t('retry'),
                  icon: Icons.refresh_rounded,
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GradientButton(
                outlined: true,
                compact: true,
                icon: Icons.playlist_add_check_rounded,
                label: _x(lang, 'افزودن از خدمات پیشنهادی',
                    'Add from suggested services', 'إضافة من الخدمات المقترحة'),
                onPressed: _busy ? null : _presets,
              ),
            ),
            if (_list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                  child: Text(m.t('svc_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted(context), height: 1.6)),
                ),
              ),
            for (final sv in _list) _card(sv, m),
          ],
        ),
      );
    }
    return GlassScaffold(
      title: m.t('svc_title'),
      floatingActionButton: !_loading && _err == null
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : () => _edit(),
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(m.t('svc_add')),
            )
          : null,
      body: content,
    );
  }
}

class _SvcResult {
  const _SvcResult(this.name, this.duration, this.price, this.combinable);
  final String name;
  final int duration;
  final int price;
  final List<String> combinable;
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({
    required this.m,
    required this.icon,
    required this.others,
    this.existing,
  });
  final M m;
  final IconData icon;
  final List<Map<String, dynamic>> others;
  final Map<String, dynamic>? existing;
  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name =
      TextEditingController(text: '${widget.existing?['name'] ?? ''}');
  late final TextEditingController _dur = TextEditingController(
      text: '${widget.existing?['duration_min'] ?? 30}');
  late final TextEditingController _price = TextEditingController(
      text: widget.existing == null ? '' : '${widget.existing!['price'] ?? 0}');
  final Set<String> _comb = {};

  @override
  void initState() {
    super.initState();
    final valid = widget.others.map((e) => '${e['service_id']}').toSet();
    final raw = widget.existing?['combinable_with'];
    if (raw is List) {
      for (final e in raw) {
        if (valid.contains('$e')) _comb.add('$e');
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dur.dispose();
    _price.dispose();
    super.dispose();
  }

  int? _num(String t) {
    final d = normalizeDigits(t).replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? null : int.tryParse(d);
  }

  void _ok() {
    final m = widget.m;
    if (_name.text.trim().length < 2) {
      toast(context, m.t('v_required'));
      return;
    }
    final d = _num(_dur.text);
    if (d == null || d < 5 || d > 480) {
      toast(context, m.t('svc_bad_duration'));
      return;
    }
    Navigator.pop(
      context,
      _SvcResult(_name.text.trim(), d, _num(_price.text) ?? 0, _comb.toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(m.t(widget.existing == null ? 'svc_add' : 'svc_edit')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              GlassField(
                controller: _name,
                label: m.t('svc_name'),
                icon: widget.icon,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassField(
                      controller: _dur,
                      label: m.t('svc_duration'),
                      icon: Icons.timer_outlined,
                      keyboard: TextInputType.number,
                      ltr: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassField(
                      controller: _price,
                      label: m.t('svc_price'),
                      icon: Icons.payments_outlined,
                      keyboard: TextInputType.number,
                      ltr: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final v in const [10, 15, 20, 30, 45, 60])
                    ActionChip(
                      label: Text('$v'),
                      onPressed: () => setState(() => _dur.text = '$v'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(m.t('svc_combinable'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(m.t('svc_combinable_hint'),
                  style: TextStyle(color: muted(context), fontSize: 12)),
              const SizedBox(height: 8),
              if (widget.others.isEmpty)
                Text(m.t('svc_no_others'),
                    style: TextStyle(color: muted(context)))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final o in widget.others)
                      FilterChip(
                        label: Text('${o['name']}'),
                        selected: _comb.contains('${o['service_id']}'),
                        onSelected: (v) => setState(() {
                          final id = '${o['service_id']}';
                          v ? _comb.add(id) : _comb.remove(id);
                        }),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(m.t('cancel'))),
        TextButton(onPressed: _ok, child: Text(m.t('save'))),
      ],
    );
  }
}
