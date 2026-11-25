import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/biz_icons.dart';
import '../../app/biz_text.dart';
import '../../app/business_types.dart';
import '../../app/config.dart';
import '../../app/extra_http.dart';
import '../../app/registry.dart' show kRegistryUrl;
import '../../app/service_catalog.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';

class SearchFilters {
  String q;
  String city;
  String gender; // '' | men | women
  String cat; // '' یا کلید خدمت
  String sort; // rating | most | price_asc | price_desc
  String group; // '' یا گروه کسب‌وکار
  String type; // '' یا نوع کسب‌وکار
  SearchFilters({
    this.q = '',
    this.city = '',
    this.gender = '',
    this.cat = '',
    this.sort = 'rating',
    this.group = '',
    this.type = '',
  });
  SearchFilters copy() => SearchFilters(
      q: q,
      city: city,
      gender: gender,
      cat: cat,
      sort: sort,
      group: group,
      type: type);
}

class SearchResult {
  final List<Map<String, dynamic>> shops;
  final List<String> cities;
  SearchResult(this.shops, this.cities);
}

class _Part {
  final String url;
  final Map<String, dynamic>? data;
  final Object? error;
  _Part(this.url, this.data, this.error);
}

double? _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}');
}

class CustomerSearch {
  static List<String>? _reg;
  static DateTime? _regAt;

  static Future<List<String>> _registryServers() async {
    if (kRegistryUrl.isEmpty) return <String>[];
    final at = _regAt;
    if (_reg != null &&
        at != null &&
        DateTime.now().difference(at).inMinutes < 10) {
      return _reg!;
    }
    try {
      final d = await extraPublic(kRegistryUrl, 'registry_list');
      final l = d['servers'];
      final out = <String>[];
      if (l is List) {
        for (final x in l) {
          if (x is String) {
            out.add(x);
          } else if (x is Map && x['url'] is String) {
            out.add(x['url'] as String);
          }
        }
      }
      _reg = out;
      _regAt = DateTime.now();
      return out;
    } catch (_) {
      return _reg ?? <String>[];
    }
  }

  /// فهرست همه‌ی سرورهایی که اپ باید از آن‌ها بخواند (جستجو و تبلیغ)
  static Future<List<String>> servers(AppSettings st) async {
    final urls = <String>[];
    void add(String u) {
      if (u.startsWith('https://') && !urls.contains(u)) urls.add(u);
    }

    add(kDefaultApiUrl);
    add(kProApiUrl);
    if (st.hasCustomApiUrl) add(st.apiUrl);
    for (final u in await _registryServers()) {
      add(u);
    }
    return urls;
  }

  static Future<SearchResult> run(AppSettings st, SearchFilters f) async {
    final urls = await servers(st);
    final body = <String, dynamic>{
      'q': f.q.trim(),
      'city': f.city,
      'gender': f.gender,
      'cat': f.cat,
      'sort': f.sort,
      'biz_group': f.group,
      'biz_type': f.type,
    };
    final parts = await Future.wait(urls.map((u) async {
      try {
        final d = await extraPublic(u, 'shop_search', body)
            .timeout(const Duration(seconds: 25));
        return _Part(u, d, null);
      } catch (e) {
        return _Part(u, null, e);
      }
    }));
    final okParts = parts.where((p) => p.data != null).toList();
    if (okParts.isEmpty) {
      final e = parts.isNotEmpty ? parts.first.error : null;
      if (e is ExtraError) throw e;
      throw ExtraError('NETWORK', 'no server');
    }
    final all = <Map<String, dynamic>>[];
    final seen = <String>{};
    final cities = <String>{};
    for (final p in okParts) {
      final d = p.data!;
      final cl = d['cities'];
      if (cl is List) {
        for (final c in cl) {
          final s = '$c'.trim();
          if (s.isNotEmpty) cities.add(s);
        }
      }
      final sl = d['shops'];
      if (sl is! List) continue;
      for (final s in sl) {
        if (s is! Map) continue;
        final m = Map<String, dynamic>.from(s);
        final id = '${p.url}|${m['shop_id']}';
        if (!seen.add(id)) continue;
        if (p.url != kDefaultApiUrl) m['_server'] = p.url;
        // اگر سرور هنوز فیلترها را نمی‌شناسد، سمت اپ هم فیلتر می‌کنیم
        if (f.city.isNotEmpty &&
            '${m['city'] ?? ''}'.trim().toLowerCase() !=
                f.city.trim().toLowerCase()) {
          continue;
        }
        final g = '${m['gender'] ?? ''}';
        if (f.gender.isNotEmpty &&
            g.isNotEmpty &&
            g != 'both' &&
            g != f.gender) {
          continue;
        }
        final bk = bizKeyOf(m);
        if (f.type.isNotEmpty && bk != f.type) continue;
        if (f.group.isNotEmpty && bizTypeByKey(bk)?.group != f.group) {
          continue;
        }
        if (f.cat.isNotEmpty && _num(m['price_from']) == null) continue;
        all.add(m);
      }
    }
    final rnd = Random();
    final keyed = [for (final s in all) MapEntry(s, rnd.nextDouble())];
    double rating(Map<String, dynamic> m) => _num(m['rating_avg']) ?? 0;
    double count(Map<String, dynamic> m) =>
        _num(f.cat.isNotEmpty ? m['cat_count'] : m['svc_count']) ?? 0;
    int cmpPrice(Map<String, dynamic> a, Map<String, dynamic> b, bool asc) {
      final pa = _num(a['price_from']);
      final pb = _num(b['price_from']);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return asc ? pa.compareTo(pb) : pb.compareTo(pa);
    }

    keyed.sort((a, b) {
      var c = 0;
      if (f.cat.isNotEmpty && f.sort == 'price_asc') {
        c = cmpPrice(a.key, b.key, true);
      } else if (f.cat.isNotEmpty && f.sort == 'price_desc') {
        c = cmpPrice(a.key, b.key, false);
      } else if (f.sort == 'most') {
        c = count(b.key).compareTo(count(a.key));
      }
      if (c == 0) c = rating(b.key).compareTo(rating(a.key));
      if (c != 0) return c;
      return a.value.compareTo(b.value);
    });
    final list = cities.toList()..sort();
    return SearchResult([for (final e in keyed.take(80)) e.key], list);
  }
}

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'svc': 'دنبال چه خدمتی هستی؟',
    'all_svc': 'همه‌ی خدمات',
    'city': 'شهر',
    'all_city': 'همه‌ی شهرها',
    'gender': 'مناسب برای',
    'all': 'همه',
    'men': 'مردانه',
    'women': 'زنانه',
    's_rating': 'بیشترین رضایت',
    's_low': 'کمترین قیمت',
    's_high': 'بیشترین قیمت',
    'price_hint': 'برای مرتب‌سازی بر اساس قیمت، اول یک خدمت انتخاب کن',
  },
  'en': {
    'svc': 'Which service are you looking for?',
    'all_svc': 'All services',
    'city': 'City',
    'all_city': 'All cities',
    'gender': 'Suitable for',
    'all': 'All',
    'men': 'Men',
    'women': 'Women',
    's_rating': 'Top rated',
    's_low': 'Lowest price',
    's_high': 'Highest price',
    'price_hint': 'To sort by price, choose a service first',
  },
  'ar': {
    'svc': 'ما الخدمة التي تبحث عنها؟',
    'all_svc': 'كل الخدمات',
    'city': 'المدينة',
    'all_city': 'كل المدن',
    'gender': 'مناسب لـ',
    'all': 'الكل',
    'men': 'رجالي',
    'women': 'نسائي',
    's_rating': 'الأعلى تقييمًا',
    's_low': 'الأقل سعرًا',
    's_high': 'الأعلى سعرًا',
    'price_hint': 'للترتيب حسب السعر اختر خدمة أولًا',
  },
};

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.lang,
    required this.filters,
    required this.cities,
    required this.onChanged,
  });
  final String lang;
  final SearchFilters filters;
  final List<String> cities;
  final ValueChanged<SearchFilters> onChanged;

  String _t(String k) => (_tx[lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  void _set({
    String? city,
    String? gender,
    String? cat,
    String? sort,
    String? group,
    String? type,
  }) {
    final f = filters.copy();
    if (city != null) f.city = city;
    if (gender != null) f.gender = gender;
    if (cat != null) f.cat = cat;
    if (sort != null) f.sort = sort;
    if (group != null) {
      f.group = group;
      f.type = '';
    }
    if (type != null) f.type = type;
    if (f.group.isNotEmpty && f.type.isNotEmpty) {
      final bt = bizTypeByKey(f.type);
      if (bt == null || bt.group != f.group) f.type = '';
    }
    // جنسیت فقط برای گروه آرایش و زیبایی معنی دارد
    if (f.group.isNotEmpty && f.group != 'beauty') {
      f.gender = '';
    }
    final items = catalogForGroup(f.group, f.gender);
    if (f.cat.isNotEmpty && !items.any((c) => c.key == f.cat)) f.cat = '';
    if (f.cat.isEmpty && (f.sort == 'price_asc' || f.sort == 'price_desc')) {
      f.sort = 'rating';
    }
    onChanged(f);
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      );

  Widget _iconText(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      );

  List<DropdownMenuItem<String>> _serviceItems(List<CatalogItem> items) {
    final out = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(value: '', child: Text(_t('all_svc'))),
    ];
    if (filters.group.isNotEmpty) {
      for (final c in items) {
        out.add(DropdownMenuItem<String>(
            value: c.key, child: Text(c.name(lang))));
      }
      return out;
    }
    for (final g in kBizGroups) {
      final gi = items.where((c) => c.group == g.key).toList();
      if (gi.isEmpty) continue;
      out.add(DropdownMenuItem<String>(
        value: '__g_${g.key}',
        enabled: false,
        child: Text(g.name(lang),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ));
      for (final c in gi) {
        out.add(DropdownMenuItem<String>(
            value: c.key, child: Text(c.name(lang))));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bt = BT(lang);
    final items = catalogForGroup(filters.group, filters.gender);
    final catValue = items.any((c) => c.key == filters.cat) ? filters.cat : '';
    final cityValue =
        (filters.city.isEmpty || cities.contains(filters.city))
            ? filters.city
            : '';
    final hasCat = catValue.isNotEmpty;
    final group = filters.group;
    final beauty = group.isEmpty || group == 'beauty';
    final types = group.isEmpty ? <BizType>[] : bizTypesOf(group);
    final typeValue =
        types.any((t) => t.key == filters.type) ? filters.type : '';
    final cityBox = DropdownButtonFormField<String>(
      value: cityValue,
      isExpanded: true,
      decoration: _dec(_t('city')),
      items: [
        DropdownMenuItem<String>(value: '', child: Text(_t('all_city'))),
        for (final c in cities)
          DropdownMenuItem<String>(value: c, child: Text(c)),
      ],
      onChanged: (v) => _set(city: v ?? ''),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: group,
          isExpanded: true,
          decoration: _dec(bt.t('f_group')),
          items: [
            DropdownMenuItem<String>(
                value: '',
                child: _iconText(Icons.apps_rounded, bt.t('f_all'))),
            for (final g in kBizGroups)
              DropdownMenuItem<String>(
                  value: g.key,
                  child: _iconText(bizGroupIcon(g.key), g.name(lang))),
          ],
          onChanged: (v) => _set(group: v ?? ''),
        ),
        if (group.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: typeValue,
            isExpanded: true,
            decoration: _dec(bt.t('f_type')),
            items: [
              DropdownMenuItem<String>(
                  value: '', child: Text(bt.t('f_all_types'))),
              for (final tp in types)
                DropdownMenuItem<String>(
                    value: tp.key,
                    child: _iconText(bizTypeIcon(tp.key), tp.name(lang))),
            ],
            onChanged: (v) => _set(type: v ?? ''),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: catValue,
          isExpanded: true,
          decoration: _dec(_t('svc')),
          items: _serviceItems(items),
          onChanged: (v) => _set(cat: v ?? ''),
        ),
        const SizedBox(height: 10),
        if (beauty)
          Row(
            children: [
              Expanded(child: cityBox),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filters.gender,
                  isExpanded: true,
                  decoration: _dec(_t('gender')),
                  items: [
                    DropdownMenuItem<String>(
                        value: '', child: Text(_t('all'))),
                    DropdownMenuItem<String>(
                        value: 'men', child: Text(_t('men'))),
                    DropdownMenuItem<String>(
                        value: 'women', child: Text(_t('women'))),
                  ],
                  onChanged: (v) => _set(gender: v ?? ''),
                ),
              ),
            ],
          )
        else
          cityBox,
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(_t('s_rating')),
              selected: filters.sort == 'rating',
              onSelected: (_) => _set(sort: 'rating'),
            ),
            ChoiceChip(
              label: Text(bt.t('s_most')),
              selected: filters.sort == 'most',
              onSelected: (_) => _set(sort: 'most'),
            ),
            ChoiceChip(
              label: Text(_t('s_low')),
              selected: filters.sort == 'price_asc',
              onSelected: hasCat ? (_) => _set(sort: 'price_asc') : null,
            ),
            ChoiceChip(
              label: Text(_t('s_high')),
              selected: filters.sort == 'price_desc',
              onSelected: hasCat ? (_) => _set(sort: 'price_desc') : null,
            ),
          ],
        ),
        if (!hasCat)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_t('price_hint'), style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
