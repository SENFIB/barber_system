import 'package:flutter/material.dart';
import '../../app/business_types.dart';
import '../../app/service_catalog.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'shop_raw.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

class ServicePresetsPage extends StatefulWidget {
  const ServicePresetsPage({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<ServicePresetsPage> createState() => _ServicePresetsPageState();
}

class _ServicePresetsPageState extends State<ServicePresetsPage> {
  bool _loading = true;
  bool _saving = false;
  List<CatalogItem> _items = [];
  final Set<String> _on = {};
  final Map<String, TextEditingController> _dur = {};
  final Map<String, TextEditingController> _price = {};

  String get _lang => widget.settings.lang;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _dur.values) {
      c.dispose();
    }
    for (final c in _price.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    var g = 'both';
    var group = 'beauty';
    try {
      final me = await ShopRaw(widget.settings).call('me');
      final shop = me['shop'];
      if (shop is Map) {
        final bz = bizTypeByKey('${shop['biz_type'] ?? ''}');
        if (bz != null) group = bz.group;
        final v = '${shop['gender'] ?? ''}';
        if (group == 'beauty' && (v == 'men' || v == 'women')) g = v;
      }
    } catch (_) {}
    final list = catalogForGroup(group, g);
    for (final it in list) {
      _dur[it.key] = TextEditingController(text: '${it.minutes}');
      _price[it.key] = TextEditingController();
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  int? _num(String t) {
    final d = normalizeDigits(t).replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? null : int.tryParse(d);
  }

  bool get _allOn => _items.isNotEmpty && _on.length == _items.length;

  void _toggleAll() {
    setState(() {
      if (_allOn) {
        _on.clear();
      } else {
        _on.addAll(_items.map((e) => e.key));
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final lang = _lang;
    final items = <Map<String, dynamic>>[];
    for (final it in _items) {
      if (!_on.contains(it.key)) continue;
      final d = _num(_dur[it.key]!.text);
      if (d == null || d < 5 || d > 480) {
        toast(
            context,
            _x(lang, 'مدت خدمت باید بین ۵ تا ۴۸۰ دقیقه باشد',
                'Duration must be 5 to 480 minutes',
                'يجب أن تكون المدة بين 5 و480 دقيقة'));
        return;
      }
      items.add(<String, dynamic>{
        'cat': it.key,
        'name': catalogName(it.key, lang),
        'duration_min': d,
        'price': _num(_price[it.key]!.text) ?? 0,
      });
    }
    if (items.isEmpty) {
      toast(
          context,
          _x(lang, 'حداقل یک خدمت را تیک بزنید',
              'Tick at least one service', 'اختر خدمة واحدة على الأقل'));
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ShopRaw(widget.settings)
          .call('service_add_many', <String, dynamic>{'items': items});
      if (!mounted) return;
      final added = '${r['added'] ?? items.length}';
      final skipped = '${r['skipped'] ?? 0}';
      toast(
          context,
          _x(
              lang,
              '$added خدمت اضافه شد ($skipped تکراری رد شد)',
              '$added services added ($skipped duplicates skipped)',
              'تمت إضافة $added خدمة (تم تخطي $skipped مكررة)'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, T6(lang).error(e));
    }
  }

  Widget _row(CatalogItem it) {
    final lang = _lang;
    final on = _on.contains(it.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: on,
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                        if (v == true) {
                          _on.add(it.key);
                        } else {
                          _on.remove(it.key);
                        }
                      }),
              title: Text(catalogName(it.key, lang),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (on)
              Row(
                children: [
                  Expanded(
                    child: GlassField(
                      controller: _dur[it.key]!,
                      label: _x(lang, 'مدت (دقیقه)', 'Minutes', 'الدقائق'),
                      icon: Icons.timer_outlined,
                      keyboard: TextInputType.number,
                      ltr: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassField(
                      controller: _price[it.key]!,
                      label: _x(lang, 'قیمت', 'Price', 'السعر'),
                      icon: Icons.payments_outlined,
                      keyboard: TextInputType.number,
                      ltr: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          _x(
              lang,
              'خدمت‌هایی را که دارید تیک بزنید، مدت و قیمت را بنویسید و ذخیره کنید. یا با یک دکمه همه را اضافه کنید. خدمتی که هم‌نام آن را دارید دوباره اضافه نمی‌شود.',
              'Tick the services you offer, set duration and price, then save, or add them all with one button. A service with the same name is not added twice.',
              'اختر الخدمات التي تقدمها واكتب المدة والسعر ثم احفظ، أو أضفها كلها بزر واحد. لا تُضاف خدمة بنفس الاسم مرتين.'),
          style: TextStyle(color: muted(context), height: 1.6),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          _x(
              lang,
              'اگر قیمت را ننویسید صفر ثبت می‌شود و بعداً در «خدمات» قابل تغییر است.',
              'If you leave the price empty it is saved as 0; you can change it later in “Services”.',
              'إذا تركت السعر فارغًا يُحفظ 0 ويمكن تعديله لاحقًا من «الخدمات».'),
          style: TextStyle(color: muted(context), fontSize: 12),
        ),
      ),
      GradientButton(
        outlined: true,
        label: _allOn
            ? _x(lang, 'برداشتن همه', 'Clear all', 'إلغاء تحديد الكل')
            : _x(lang, 'افزودن همه‌ی موارد', 'Add all items',
                'إضافة كل العناصر'),
        icon: _allOn ? Icons.remove_done_rounded : Icons.done_all_rounded,
        onPressed: _toggleAll,
      ),
      const SizedBox(height: 14),
    ];
    for (final it in _items) {
      children.add(_row(it));
    }
    children.add(const SizedBox(height: 8));
    children.add(GradientButton(
      label: _x(lang, 'ذخیره', 'Save', 'حفظ'),
      icon: Icons.check_circle_outline_rounded,
      loading: _saving,
      onPressed: _save,
    ));
    return GlassScaffold(
      title: _x(lang, 'خدمات پیشنهادی', 'Suggested services', 'خدمات مقترحة'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: children,
            ),
    );
  }
}
