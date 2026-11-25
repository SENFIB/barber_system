import 'package:flutter/material.dart';
import '../../app/extra_http.dart';
import '../../app/service_catalog.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'خدمات پیشنهادی',
    'intro': 'خدمت‌هایی که ارائه می‌دهید را تیک بزنید و مدت و قیمت را بنویسید.',
    'minutes': 'مدت (دقیقه)',
    'price': 'قیمت',
    'added': 'اضافه شده',
    'save': 'افزودن به خدمات',
    'ok': 'خدمات اضافه شد ✅',
    'need_price': 'برای خدمت‌های انتخاب‌شده، مدت و قیمت را بنویسید',
    'none': 'خدمتی انتخاب نشده',
    'retry': 'تلاش دوباره',
  },
  'en': {
    'title': 'Suggested services',
    'intro': 'Tick the services you offer and enter duration and price.',
    'minutes': 'Duration (min)',
    'price': 'Price',
    'added': 'Added',
    'save': 'Add to services',
    'ok': 'Services added ✅',
    'need_price': 'Enter duration and price for the selected services',
    'none': 'No service selected',
    'retry': 'Try again',
  },
  'ar': {
    'title': 'خدمات مقترحة',
    'intro': 'حدّد الخدمات التي تقدمها واكتب المدة والسعر.',
    'minutes': 'المدة (دقيقة)',
    'price': 'السعر',
    'added': 'مضافة',
    'save': 'إضافة إلى الخدمات',
    'ok': 'تمت إضافة الخدمات ✅',
    'need_price': 'اكتب المدة والسعر للخدمات المحددة',
    'none': 'لم تُحدَّد أي خدمة',
    'retry': 'حاول مجددًا',
  },
};

class SuggestedServicesPage extends StatefulWidget {
  const SuggestedServicesPage({super.key, required this.settings, required this.gender});
  final AppSettings settings;
  final String gender;

  @override
  State<SuggestedServicesPage> createState() => _SuggestedServicesPageState();
}

class _SuggestedServicesPageState extends State<SuggestedServicesPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Set<String> _have = <String>{};
  late final List<CatalogItem> _items;
  final Map<String, bool> _sel = {};
  final Map<String, TextEditingController> _min = {};
  final Map<String, TextEditingController> _price = {};

  AppSettings get _st => widget.settings;
  String get _lang => _st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _items = catalogFor(widget.gender);
    for (final c in _items) {
      _sel[c.key] = false;
      _min[c.key] = TextEditingController(text: '${c.minutes}');
      _price[c.key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _min.values) {
      c.dispose();
    }
    for (final c in _price.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await extraManager(_st, 'service_list');
      final list = r['services'];
      final have = <String>{};
      if (list is List) {
        for (final s in list) {
          if (s is Map) {
            final c = '${s['cat'] ?? ''}';
            if (c.isNotEmpty) have.add(c);
          }
        }
      }
      _have = have;
    } on ExtraError catch (e) {
      _error = extraErrorText(e, _lang);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    final out = <Map<String, dynamic>>[];
    for (final c in _items) {
      if (_sel[c.key] != true || _have.contains(c.key)) continue;
      final m = _min[c.key]!.text.trim();
      final p = _price[c.key]!.text.trim();
      if (m.isEmpty || p.isEmpty) {
        toast(context, _t('need_price'));
        return;
      }
      out.add({
        'cat': c.key,
        'name': c.name(_lang),
        'duration_min': latinOf(m),
        'price': latinOf(p),
      });
    }
    if (out.isEmpty) {
      toast(context, _t('none'));
      return;
    }
    setState(() => _saving = true);
    try {
      await extraManager(_st, 'service_add_many', {'items': out});
      if (!mounted) return;
      toast(context, _t('ok'));
      Navigator.of(context).pop(true);
    } on ExtraError catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        toast(context, extraErrorText(e, _lang));
      }
    }
  }

  Widget _num(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _row(CatalogItem c) {
    final have = _have.contains(c.key);
    final on = _sel[c.key] == true && !have;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: have ? true : on,
                  onChanged: have ? null : (v) => setState(() => _sel[c.key] = v == true),
                ),
                Expanded(child: Text(c.name(_lang))),
                if (have) Text(_t('added'), style: TextStyle(color: muted(context))),
              ],
            ),
            if (on) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _num(_min[c.key]!, _t('minutes'))),
                  const SizedBox(width: 10),
                  Expanded(child: _num(_price[c.key]!, _t('price'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          GradientButton(label: _t('retry'), icon: Icons.refresh_rounded, onPressed: _load),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(_t('intro'), style: TextStyle(color: muted(context))),
          const SizedBox(height: 12),
          for (final c in _items) _row(c),
          const SizedBox(height: 8),
          GradientButton(
            label: _t('save'),
            icon: Icons.add_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      );
    }
    return GlassScaffold(title: _t('title'), body: body);
  }
}
