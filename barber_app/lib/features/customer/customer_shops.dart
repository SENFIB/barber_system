import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/biz_icons.dart';
import '../../app/business_types.dart';
import '../../app/fmt.dart';
import '../../app/registry.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../manager/booking_common.dart';
import 'customer_api.dart';
import 'customer_filters.dart';
import 'customer_shop_page.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

class ShopsTab extends StatefulWidget {
  const ShopsTab({super.key, required this.api, required this.onBooked});
  final CustomerApi api;
  final VoidCallback onBooked;
  @override
  State<ShopsTab> createState() => _ShopsTabState();
}

class _ShopsTabState extends State<ShopsTab> {
  final _q = TextEditingController();
  Timer? _timer;
  String _last = '';
  int _seq = 0;
  bool _loading = false;
  bool _typeChosen = false;
  Object? _err;
  SearchFilters _f = SearchFilters();
  List<String> _cities = <String>[];
  List<Map<String, dynamic>> _shops = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _q.addListener(_onText);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _q.removeListener(_onText);
    _q.dispose();
    super.dispose();
  }

  void _onText() {
    final v = _q.text.trim();
    if (v == _last) return;
    _last = v;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _load();
    });
  }

  SearchFilters _current() => SearchFilters(
        q: _q.text.trim(),
        city: _f.city,
        gender: _f.gender,
        cat: _f.cat,
        sort: _f.sort,
        group: _f.group,
        type: _f.type,
      );

  void _reset() {
    _seq++;
    _timer?.cancel();
    _q.text = '';
    _last = '';
    setState(() {
      _f = SearchFilters();
      _typeChosen = false;
      _shops = <Map<String, dynamic>>[];
      _cities = <String>[];
      _err = null;
      _loading = false;
    });
  }

  void _pickGroup(String g) {
    setState(() {
      _f = SearchFilters(group: g);
      _typeChosen = false;
    });
  }

  void _pickType(String type) {
    setState(() {
      _f.type = type;
      _typeChosen = true;
    });
    _load();
  }

  Future<void> _load() async {
    if (_f.group.isEmpty || !_typeChosen) return;
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final f = _current();
      final r = await CustomerSearch.run(widget.api.st, f);
      if (!mounted || seq != _seq) return;
      setState(() {
        _shops = [
          for (final e in r.shops) Map<String, dynamic>.from(e as Map),
        ];
        final cs = <String>[for (final c in r.cities) c.toString()];
        if (cs.isNotEmpty || _cities.isEmpty) _cities = cs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }

  Future<void> _open(Map<String, dynamic> shop) async {
    // کسب‌وکارهای سرورهای دیگر با سرور خودشان کار می‌کنند
    final server = bStr(shop['_server']);
    final api = server.isEmpty
        ? widget.api
        : CustomerApi(widget.api.st, baseUrl: server);
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopPage(api: api, card: shop),
      ),
    );
    if (ok == true && mounted) {
      if (server.isNotEmpty) await ServerRegistry.remember(server);
      if (mounted) widget.onBooked();
    }
  }

  // ---------- مرحله ۱: انتخاب دسته ----------
  Widget _groupView(String lang) {
    final sep = lang == 'en' ? ', ' : '، ';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
              _x(lang, 'دنبال چی هستی؟', 'What are you looking for?',
                  'عن ماذا تبحث؟'),
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
              _x(lang, 'اول دسته‌ی مورد نظرت را انتخاب کن',
                  'First, choose a category', 'اختر الفئة أولاً'),
              style: TextStyle(color: muted(context))),
        ),
        for (final g in kBizGroups)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(
              onTap: () => _pickGroup(g.key),
              child: Row(
                children: [
                  GradientIcon(bizGroupIcon(g.key), size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name(lang),
                            style: const TextStyle(
                                fontSize: 16.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                            bizTypesOf(g.key)
                                .take(3)
                                .map((e) => e.name(lang))
                                .join(sep),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: muted(context), fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Icon(chevron(context), color: muted(context)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------- مرحله ۲: انتخاب نوع داخل دسته ----------
  Widget _typeView(String lang) {
    final g = bizGroupByKey(_f.group);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.category_rounded, size: 18),
            label: Text(_x(lang, 'تغییر دسته', 'Change category',
                'تغيير الفئة')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(g?.name(lang) ?? '',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Glass(
            onTap: () => _pickType(''),
            child: Row(
              children: [
                GradientIcon(bizGroupIcon(_f.group), size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                      _x(lang, 'همه‌ی این دسته', 'Everything in this category',
                          'كل هذه الفئة'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                Icon(chevron(context), color: muted(context)),
              ],
            ),
          ),
        ),
        for (final tp in bizTypesOf(_f.group))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(
              onTap: () => _pickType(tp.key),
              child: Row(
                children: [
                  GradientIcon(bizTypeIcon(tp.key), size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(tp.name(lang),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Icon(chevron(context), color: muted(context)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = T6(SettingsScope.of(context).lang);
    if (_f.group.isEmpty) return _groupView(t.lang);
    if (!_typeChosen) return _typeView(t.lang);

    final gName = bizGroupByKey(_f.group)?.name(t.lang) ?? '';
    final tName =
        _f.type.isEmpty ? '' : (bizTypeByKey(_f.type)?.name(t.lang) ?? '');
    final children = <Widget>[
      Row(
        children: [
          Icon(
              _f.type.isEmpty ? bizGroupIcon(_f.group) : bizTypeIcon(_f.type),
              size: 20,
              color: muted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tName.isEmpty ? gName : '$gName • $tName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.category_rounded, size: 18),
            label: Text(_x(t.lang, 'تغییر دسته', 'Change category',
                'تغيير الفئة')),
          ),
        ],
      ),
      const SizedBox(height: 6),
      GlassField(
        controller: _q,
        label: _x(t.lang, 'دنبال چی هستی؟', 'What are you looking for?',
            'عن ماذا تبحث؟'),
        hint: _x(
            t.lang,
            'خدمت، نام کسب‌وکار یا شهر را وارد کن',
            'Type a service, business name or city',
            'اكتب خدمة أو اسم نشاط أو مدينة'),
        icon: Icons.search_rounded,
      ),
      const SizedBox(height: 10),
      SearchFilterBar(
        lang: t.lang,
        filters: _f,
        cities: _cities,
        onChanged: (nf) {
          setState(() => _f = nf);
          _load();
        },
      ),
      const SizedBox(height: 14),
    ];
    if (_loading && _shops.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (_err != null) {
      children.add(Glass(
        child: Column(
          children: [
            Text(t.error(_err!), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GradientButton(
              compact: true,
              icon: Icons.refresh_rounded,
              label: t.t('c_retry'),
              onPressed: () {
                _load();
              },
            ),
          ],
        ),
      ));
    } else if (_shops.isEmpty) {
      children.add(Glass(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              const GradientIcon(Icons.search_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(
                  _x(t.lang, 'موردی پیدا نشد', 'Nothing found',
                      'لم يتم العثور على نتائج'),
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ),
      ));
    } else {
      if (_loading) {
        children.add(const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: LinearProgressIndicator(minHeight: 3),
        ));
      }
      for (final s in _shops) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _card(s, t),
        ));
      }
    }
    children.add(const SizedBox(height: 30));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        children: children,
      ),
    );
  }

  Widget _thumb(Map<String, dynamic> s, String bk) {
    final url = bStr(s['photo_url']);
    if (url.isNotEmpty) {
      return ShopPhoto(url: url, width: 72, height: 72);
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.withOpacity(0.14),
      ),
      child: Center(child: GradientIcon(bizTypeIcon(bk), size: 36)),
    );
  }

  Widget _card(Map<String, dynamic> s, T6 t) {
    final avg = cDouble(s['rating_avg']);
    final count = bInt(s['rating_count']);
    final sep = t.lang == 'en' ? ', ' : '، ';
    final place = [bStr(s['city']), bStr(s['address'])]
        .where((e) => e.isNotEmpty)
        .join(sep);
    final gender = bStr(s['gender']);
    final priceFrom = bInt(s['price_from']);
    final showPrice = _f.cat.isNotEmpty && priceFrom > 0;
    final bk = bizKeyOf(s);
    final typeName = bizTypeByKey(bk)?.name(t.lang) ?? '';
    final isBeauty = bizTypeByKey(bk)?.group == 'beauty';
    return Glass(
      onTap: () => _open(s),
      child: Row(
        children: [
          _thumb(s, bk),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bStr(s['name']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16.5, fontWeight: FontWeight.w800)),
                if (typeName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(bizTypeIcon(bk), size: 15, color: muted(context)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(typeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: muted(context), fontSize: 12.5)),
                      ),
                    ],
                  ),
                ],
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(place,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted(context), fontSize: 12.5)),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (count > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.amber),
                          const SizedBox(width: 3),
                          Text(localDigits(avg.toStringAsFixed(1), t.lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text(
                              t.t('cu_reviews', {'n': fmtNum(count, t.lang)}),
                              style: TextStyle(
                                  color: muted(context), fontSize: 12)),
                        ],
                      )
                    else
                      Pill(t.t('cu_new')),
                    if (isBeauty && gender == 'men')
                      Pill(_x(t.lang, 'مردانه', 'Men', 'رجالي')),
                    if (isBeauty && gender == 'women')
                      Pill(_x(t.lang, 'زنانه', 'Women', 'نسائي')),
                  ],
                ),
                if (showPrice) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_x(t.lang, 'از', 'From', 'من')} ${fmtNum(priceFrom, t.lang)} ${bStr(s['currency'])}'
                        .trim(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Icon(chevron(context), color: muted(context)),
        ],
      ),
    );
  }
}
