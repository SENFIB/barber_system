import 'package:flutter/material.dart';
import '../../app/biz_icons.dart';
import '../../app/business_types.dart';
import '../../app/currency.dart';
import '../../app/extra_http.dart';
import '../../app/service_catalog.dart';
import '../../app/settings.dart';
import '../../app/type_services.dart';
import '../../app/widgets.dart';
const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'خدمات پیشنهادی',
    'intro': 'خدمت‌هایی که ارائه می‌دهید را تیک بزنید و مدت و قیمت را بنویسید. یا با یک دکمه همه را اضافه کنید.',
    'price_hint': 'اگر قیمت را ننویسید صفر ثبت می‌شود و بعداً در «خدمات» قابل تغییر است.',
    'minutes': 'مدت (دقیقه)',
    'price': 'قیمت',
    'added': 'اضافه شده',
    'save': 'افزودن به خدمات',
    'ok': 'خدمات اضافه شد ✅',
    'need_price': 'برای خدمت‌های انتخاب‌شده، مدت را بنویسید',
    'none': 'خدمتی انتخاب نشده',
    'retry': 'تلاش دوباره',
    'all_on': 'افزودن همه‌ی موارد',
    'all_off': 'برداشتن همه',
  },
  'en': {
    'title': 'Suggested services',
    'intro': 'Tick the services you offer and enter duration and price, or add them all with one button.',
    'price_hint': 'If you leave the price empty it is saved as 0; you can change it later in “Services”.',
    'minutes': 'Duration (min)',
    'price': 'Price',
    'added': 'Added',
    'save': 'Add to services',
    'ok': 'Services added ✅',
    'need_price': 'Enter the duration for the selected services',
    'none': 'No service selected',
    'retry': 'Try again',
    'all_on': 'Add all items',
    'all_off': 'Clear all',
  },
  'ar': {
    'title': 'خدمات مقترحة',
    'intro': 'حدّد الخدمات التي تقدمها واكتب المدة والسعر، أو أضفها كلها بزر واحد.',
    'price_hint': 'إذا تركت السعر فارغًا يُحفظ 0 ويمكن تعديله لاحقًا من «الخدمات».',
    'minutes': 'المدة (دقيقة)',
    'price': 'السعر',
    'added': 'مضافة',
    'save': 'إضافة إلى الخدمات',
    'ok': 'تمت إضافة الخدمات ✅',
    'need_price': 'اكتب المدة للخدمات المحددة',
    'none': 'لم تُحدَّد أي خدمة',
    'retry': 'حاول مجددًا',
    'all_on': 'إضافة كل العناصر',
    'all_off': 'إلغاء تحديد الكل',
  },
};
const Map<String, Map<String, String>> _groupNames = {
  'beauty': {'fa': 'زیبایی و آرایش', 'en': 'Beauty & grooming', 'ar': 'التجميل والعناية'},
  'wellness': {'fa': 'سلامت و آرامش', 'en': 'Wellness & relaxation', 'ar': 'الصحة والاسترخاء'},
  'auto': {'fa': 'خودرو', 'en': 'Cars', 'ar': 'السيارات'},
  'pro': {'fa': 'خدمات حرفه‌ای', 'en': 'Professional services', 'ar': 'خدمات مهنية'},
  'edu': {'fa': 'آموزش و ورزش', 'en': 'Training & sports', 'ar': 'التعليم والرياضة'},
  'pets': {'fa': 'حیوانات خانگی', 'en': 'Pets', 'ar': 'الحيوانات الأليفة'},
};
/// فقط خدمات پیشنهادیِ همین «نوع» کسب‌وکار نشان داده می‌شود
/// (گروه زیبایی بر اساس مردانه/زنانه)
class SuggestedServicesPage extends StatefulWidget {
  const SuggestedServicesPage({
    super.key,
    required this.settings,
    required this.gender,
    this.initialGroup = 'beauty',
  });
  final AppSettings settings;
  final String gender;
  final String initialGroup;
  @override
  State<SuggestedServicesPage> createState() => _SuggestedServicesPageState();
}
class _SuggestedServicesPageState extends State<SuggestedServicesPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Set<String> _have = <String>{};
  List<CatalogItem> _items = [];
  final Map<String, bool> _sel = {};
  final Map<String, DigitController> _min = {};
  final Map<String, MoneyController> _price = {};
  String _group = 'beauty';
  String _type = '';
  String _gender = 'both';
  String _cur = '';
  AppSettings get _st => widget.settings;
  String get _lang => _st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;
  String _gName(String g) =>
      (_groupNames[g] ?? const <String, String>{})[_lang] ?? g;
  @override
  void initState() {
    super.initState();
    _group = _groupNames.containsKey(widget.initialGroup)
        ? widget.initialGroup
        : 'beauty';
    _gender = widget.gender;
    _build();
    _load();
  }
  void _disposeCtrls() {
    for (final c in _min.values) {
      c.dispose();
    }
    for (final c in _price.values) {
      c.dispose();
    }
    _min.clear();
    _price.clear();
  }
  void _build() {
    _disposeCtrls();
    _sel.clear();
    final gender = _group == 'beauty' ? _gender : 'both';
    _items = catalogForType(_group, _type, gender);
    for (final c in _items) {
      _sel[c.key] = false;
      _min[c.key] = DigitController(lang: _lang, text: '${c.minutes}');
      _price[c.key] = MoneyController(lang: _lang);
    }
  }
  @override
  void dispose() {
    _disposeCtrls();
    super.dispose();
  }
  bool get _allOn {
    final avail = _items.where((c) => !_have.contains(c.key)).toList();
    return avail.isNotEmpty && avail.every((c) => _sel[c.key] == true);
  }
  void _toggleAll() {
    final v = !_allOn;
    setState(() {
      for (final c in _items) {
        if (!_have.contains(c.key)) _sel[c.key] = v;
      }
    });
  }
  Future<dynamic> _me() async {
    try {
      return await extraManager(_st, 'me');
    } catch (_) {
      return null;
    }
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meF = _me();
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
      final me = await meF;
      final sh = me is Map ? me['shop'] : null;
      if (sh is Map) {
        final bz = bizTypeByKey('${sh['biz_type'] ?? ''}');
        if (bz != null) {
          _group = bz.group;
          _type = bz.key;
        }
        _cur = '${sh['currency'] ?? ''}';
        final v = '${sh['gender'] ?? ''}';
        if (v == 'men' || v == 'women') _gender = v;
        _build();
      }
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
      final m = _min[c.key]!.number;
      if (m == null) {
        toast(context, _t('need_price'));
        return;
      }
      out.add({
        'cat': c.key,
        'name': c.name(_lang),
        'duration_min': m,
        'price': _price[c.key]!.number ?? 0,
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
      textDirection: TextDirection.ltr,
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
    final curName = currencyName(_cur, _lang);
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
                  Expanded(
                      child: _num(
                          _price[c.key]!, '${_t('price')} ($curName)')),
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
          Row(
            children: [
              Icon(bizGroupIcon(_group)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_gName(_group),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_t('intro'), style: TextStyle(color: muted(context))),
          const SizedBox(height: 4),
          Text(_t('price_hint'),
              style: TextStyle(color: muted(context), fontSize: 12)),
          const SizedBox(height: 12),
          GradientButton(
            outlined: true,
            label: _allOn ? _t('all_off') : _t('all_on'),
            icon: _allOn
                ? Icons.remove_done_rounded
                : Icons.done_all_rounded,
            onPressed: _toggleAll,
          ),
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
