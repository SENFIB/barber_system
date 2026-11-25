import 'dart:math';
import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/biz_text.dart';
import '../../app/biz_words.dart';
import '../../app/business_types.dart';
import '../../app/cal_conv.dart';
import '../../app/config.dart';
import '../../app/fmt.dart';
import '../../app/look.dart';
import '../../app/reminders.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../legal/privacy_gate.dart';
import '../manager/booking_common.dart';
import 'customer_api.dart';
import 'customer_store.dart';
import 'report_sheet.dart';
import 'shop_ads.dart';
import 'store_page.dart';
String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);
bool _truthy(dynamic v) => v == true || '$v' == 'true' || '$v' == '1';

/// اسمی که شبیه شناسه/کد/شماره است (نام واقعی نیست)
bool _looksId(String s) {
  final v = s.trim();
  if (v.isEmpty) return false;
  if (RegExp(r'^[0-9\s+\-]+$').hasMatch(v)) return true;
  return !v.contains(' ') && RegExp(r'^[A-Za-z0-9_\-]{14,}$').hasMatch(v);
}
class ShopPhoto extends StatelessWidget {
  const ShopPhoto({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 14,
  });
  final String url;
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) {
    Widget ph() => Container(
          width: width,
          height: height,
          color: lk(context).primary.withOpacity(0.12),
          child: const Center(
              child: GradientIcon(Icons.storefront_rounded, size: 40)),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.trim().isEmpty
          ? ph()
          : Image.network(
              url.trim(),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ph(),
              loadingBuilder: (c, child, p) => p == null ? child : ph(),
            ),
    );
  }
}
/// پوسته‌ی صفحه: ظاهر اختصاصی کسب‌وکار (فقط پلن ویژه) را با یک دکمه روشن/خاموش می‌کند
class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.api, required this.card});
  final CustomerApi api;
  final Map<String, dynamic> card;
  @override
  State<ShopPage> createState() => _ShopPageState();
}
class _ShopPageState extends State<ShopPage> {
  AppLook? _look;
  bool _on = false;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final look = _look;
    final on = _on && look != null;
    final mq = MediaQuery.of(context);
    final mine = SettingsScope.of(context).look.fontScale;
    final k = on ? look.fontScale / mine : 1.0;
    return Theme(
      data: on ? buildTheme(base.brightness, look) : base,
      child: MediaQuery(
        data: mq.copyWith(
            textScaler: TextScaler.linear(mq.textScaler.scale(1.0) * k)),
        child: _ShopBody(
          api: widget.api,
          card: widget.card,
          hasTheme: look != null,
          themeOn: on,
          onLook: (l) {
            if (!mounted) return;
            setState(() {
              _look = l;
              if (l == null) _on = false;
            });
          },
          onToggle: () => setState(() => _on = !_on),
        ),
      ),
    );
  }
}
class _ShopBody extends StatefulWidget {
  const _ShopBody({
    required this.api,
    required this.card,
    required this.hasTheme,
    required this.themeOn,
    required this.onLook,
    required this.onToggle,
  });
  final CustomerApi api;
  final Map<String, dynamic> card;
  final bool hasTheme;
  final bool themeOn;
  final void Function(AppLook? look) onLook;
  final VoidCallback onToggle;
  @override
  State<_ShopBody> createState() => _ShopBodyState();
}
class _ShopBodyState extends State<_ShopBody> {
  bool _loading = true;
  bool _busy = false;
  bool _slotsBusy = false;
  Object? _err;
  late Map<String, dynamic> _shop;
  List<Map<String, dynamic>> _services = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _staff = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _winback = <Map<String, dynamic>>[];
  int _maxServices = 3;
  int _maxAdvance = 30;
  Set<int> _offDays = <int>{};
  final List<String> _picked = <String>[];
  final Map<String, String> _choice = <String, String>{};
  late DateTime _day;
  List<Map<String, dynamic>>? _slots;
  int _slotIdx = -1;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  AppSettings? _stRef;
  String get _shopId => bStr(widget.card['shop_id']);
  T6 _tr() => T6(SettingsScope.read(context).lang);
  @override
  void initState() {
    super.initState();
    _shop = Map<String, dynamic>.from(widget.card);
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    // تقویمِ این کسب‌وکار فقط تا وقتی در این صفحه‌ایم اعمال می‌شود
    final s = _stRef;
    if (s != null) kCalKind = CalConv.kindOf(s.calendarKey, s.lang);
    super.dispose();
  }
  /// اگر کاربر تقویم دلخواه نزده باشد، تاریخ‌ها با تقویم همین کسب‌وکار نمایش داده می‌شوند
  void _applyShopCal(AppSettings st) {
    _stRef = st;
    if (st.calendarKey != 'auto') return;
    final c = bStr(_shop['calendar']);
    if (c.isNotEmpty) kCalKind = CalConv.kindOf(c, st.lang);
  }
  /// ظاهر اختصاصی (فقط ویژه/شخصی؛ عکس پس‌زمینه‌ی دستگاهِ صاحب‌کار اینجا معنی ندارد)
  AppLook? _parseTheme(Map<String, dynamic> shop) {
    final plan = bStr(shop['plan']);
    if (plan != 'special' && plan != 'personal') return null;
    final raw = bStr(shop['theme']).trim();
    if (raw.isEmpty) return null;
    final l = AppLook.fromJsonString(raw);
    return l.copyWith(
        bgImage: '', bgMode: l.bgMode == 'image' ? 'blobs' : l.bgMode);
  }
  /// روزهای تعطیل هفتگی کل کسب‌وکار (۰ = یکشنبه)
  Set<int> _parseOff(Map<String, dynamic> shop) {
    final out = <int>{};
    void add(dynamic v) {
      final n = int.tryParse('$v'.trim());
      if (n != null && n >= 0 && n <= 6) out.add(n);
    }
    final l = shop['weekly_off_list'];
    if (l is List) {
      for (final e in l) {
        add(e);
      }
    }
    if (out.isEmpty) {
      final raw = bStr(shop['weekly_off']);
      if (raw.isNotEmpty) {
        for (final p in raw.split(RegExp(r'[|,]'))) {
          add(p);
        }
      }
    }
    return out;
  }
  bool _isOff(DateTime d) => _offDays.contains(d.weekday % 7);
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.api.shopDetail(_shopId);
      final saved = await CustomerStore.load();
      if (!mounted) return;
      final sh = r['shop'];
      setState(() {
        if (sh is Map) {
          _shop = <String, dynamic>{..._shop, ...Map<String, dynamic>.from(sh)};
        }
        _services = bRows(r['services']);
        _staff = bRows(r['staff']);
        _winback = bRows(r['winback']);
        final ms = bInt(r['max_services'], 3);
        _maxServices = ms < 1 ? 1 : ms;
        // بازهٔ رزرو را خود کسب‌وکار تعیین می‌کند (۰ = فقط امروز)
        final ma = bInt(r['max_advance_days'], 30);
        _maxAdvance = ma < 0 ? 0 : (ma > 60 ? 60 : ma);
        _offDays = _parseOff(_shop);
        // اگر امروز تعطیل است، اولین روز باز را انتخاب کن
        final n = DateTime.now();
        for (var i = 0; i <= _maxAdvance; i++) {
          final d = DateTime(n.year, n.month, n.day + i);
          if (!_isOff(d)) {
            _day = d;
            break;
          }
        }
        if (_name.text.isEmpty && !_looksId(saved.name)) {
          _name.text = saved.name;
        }
        if (_phone.text.isEmpty) _phone.text = saved.phone;
        _loading = false;
      });
      widget.onLook(_parseTheme(_shop));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }
  List<Map<String, dynamic>> _eligible(String sid) {
    return _staff.where((s) {
      final ids = bIds(s['service_ids']);
      return ids.isEmpty || ids.contains(sid);
    }).toList();
  }
  Map<String, dynamic> _svc(String id) => _services.firstWhere(
        (s) => bStr(s['service_id']) == id,
        orElse: () => <String, dynamic>{},
      );
  String _staffName(String id) {
    for (final s in _staff) {
      if (bStr(s['staff_id']) == id) return bStr(s['name']);
    }
    return id;
  }
  void _resetSlots() {
    _slots = null;
    _slotIdx = -1;
  }
  void _toggle(String id) {
    if (_picked.contains(id)) {
      setState(() {
        _picked.remove(id);
        _choice.remove(id);
        _resetSlots();
      });
      return;
    }
    if (_picked.length >= _maxServices) {
      final t = _tr();
      bSnack(context, t.t('m_max', {'n': fmtNum(_maxServices, t.lang)}));
      return;
    }
    setState(() {
      _picked.add(id);
      _resetSlots();
    });
  }
  void _setDay(DateTime d) {
    setState(() {
      _day = d;
      _resetSlots();
    });
    if (_picked.isNotEmpty) _loadSlots();
  }
  Future<void> _loadSlots() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('cu_pick'));
      return;
    }
    setState(() {
      _slotsBusy = true;
      _slotIdx = -1;
    });
    try {
      final choice = <String, String>{};
      for (final sid in _picked) {
        final c = _choice[sid] ?? '';
        if (c.isNotEmpty) choice[sid] = c;
      }
      final r = await widget.api.slots(
        shopId: _shopId,
        date: bIso(_day),
        serviceIds: List<String>.from(_picked),
        staffChoice: choice,
      );
      if (!mounted) return;
      setState(() => _slots = bFirstList(r, ['slots']));
    } catch (e) {
      if (!mounted) return;
      bSnack(context, t.error(e));
    } finally {
      if (mounted) setState(() => _slotsBusy = false);
    }
  }
  /// یادآوری‌های محلی (۲ ساعت و ۱۰ دقیقه قبل) + «پیام اختصاصی».
  /// پیام اختصاصی: یک بازهٔ مشترک برای همهٔ متن‌ها؛ اگر چند متن باشد یکی تصادفی انتخاب می‌شود.
  Future<void> _remind(Map<String, dynamic> slot, Map<String, String> choice,
      String lang) async {
    try {
      final date = bIso(_day);
      final start = bStr(slot['start']);
      final name = bStr(_shop['name']);
      final tz = bStr(_shop['timezone']);
      await Reminders.ask();
      await Reminders.booking(
          id: '$name|$date|$start',
          shop: name,
          date: date,
          time: start,
          tz: tz,
          lang: lang);
      var days = 0;
      final msgs = <String>[];
      for (final w in _winback) {
        final d = bInt(w['days_after']);
        final m = bStr(w['message']).trim();
        if (d < 1 || m.isEmpty) continue;
        if (days == 0) days = d;
        msgs.add(m);
      }
      if (days >= 1 && msgs.isNotEmpty) {
        final body =
            msgs.length == 1 ? msgs.first : msgs[Random().nextInt(msgs.length)];
        await Reminders.winback(
            key: 'wb|$_shopId',
            date: date,
            tz: tz,
            days: days,
            title: name,
            body: body);
      }
    } catch (_) {}
  }
  Future<void> _book() async {
    final t = _tr();
    if (_picked.isEmpty) {
      bSnack(context, t.t('cu_pick'));
      return;
    }
    final slots = _slots;
    if (slots == null || _slotIdx < 0 || _slotIdx >= slots.length) {
      bSnack(context, t.t('m_pick_slot'));
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      bSnack(context, t.t('cu_need_name'));
      return;
    }
    if (name.length < 2 || _looksId(name)) {
      bSnack(
          context,
          _x(
              t.lang,
              'نام واقعی خود را بنویسید (نه شماره یا کد)',
              'Please enter your real name (not a number or code)',
              'اكتب اسمك الحقيقي (وليس رقمًا أو رمزًا)'));
      return;
    }
    final phone = bDigits(_phone.text);
    if (phone.isEmpty) {
      bSnack(context, t.t('cu_need_phone'));
      return;
    }
    final slot = slots[_slotIdx];
    final choice = <String, String>{};
    for (final a in bRows(slot['assign'])) {
      choice[bStr(a['service_id'])] = bStr(a['staff_id']);
    }
    setState(() => _busy = true);
    try {
      await widget.api.book(
        shopId: _shopId,
        name: name,
        phone: phone,
        date: bIso(_day),
        startTime: bStr(slot['start']),
        serviceIds: List<String>.from(_picked),
        staffChoice: choice,
      );
      await CustomerStore.save(name, phone);
      await _remind(slot, choice, t.lang);
      if (!mounted) return;
      bSnack(context, t.t('cu_booked_ok'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      bSnack(context, t.error(e));
      if (e is ApiException && e.code == 'SLOT_TAKEN') {
        _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  String _policy(T6 t) {
    final m = bInt(_shop['cancel_before_min'], 120);
    final txt = (m >= 60 && m % 60 == 0)
        ? t.t('cu_h', {'n': fmtNum(m ~/ 60, t.lang)})
        : t.t('cu_m', {'n': fmtNum(m, t.lang)});
    return t.t('cu_policy', {'t': txt});
  }
  void _openRules(String lang) {
    openShopRules(context, lang, bStr(_shop['name']), bStr(_shop['rules']));
  }
  /// باز کردن صفحه‌ی کسب‌وکاری که تبلیغش دیده شده
  void _openAd(Map<String, dynamic> ad) {
    final server = bStr(ad['_server']);
    final api = CustomerApi(SettingsScope.read(context),
        baseUrl: server.isEmpty ? kDefaultApiUrl : server);
    final card = Map<String, dynamic>.from(ad);
    if (server.isNotEmpty && server != kDefaultApiUrl) {
      card['_server'] = server;
    } else {
      card.remove('_server');
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopPage(api: api, card: card)),
    );
  }
  /// برچسب روز: «نام روز + روز/ماه» در تقویم انتخاب‌شده
  String _dayLabel(DateTime d, T6 t) {
    final n = CalConv.numeric(bIso(d), kCalKind, t.lang);
    final p = n.split('/');
    final dm = p.length == 3 ? '${p[1]}/${p[2]}' : n;
    return '${t.t('d_${d.weekday % 7}')} $dm';
  }
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
      );
  @override
  Widget build(BuildContext context) {
    final st0 = SettingsScope.of(context);
    _applyShopCal(st0);
    final t = T6(st0.lang);
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Glass(
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
          ),
        ],
      );
    } else {
      body = _content(t);
    }
    return GlassScaffold(
      title: bStr(_shop['name']),
      maxWidth: 720,
      body: body,
    );
  }
  Widget _header(T6 t) {
    final avg = cDouble(_shop['rating_avg']);
    final count = bInt(_shop['rating_count']);
    final phone = bStr(_shop['phone']);
    final sep = t.lang == 'en' ? ', ' : '، ';
    final address = [bStr(_shop['city']), bStr(_shop['address'])]
        .where((e) => e.isNotEmpty)
        .join(sep);
    final desc = bStr(_shop['description']);
    final hasRules = bStr(_shop['rules']).trim().isNotEmpty;
    final gender = bStr(_shop['gender']);
    final bizT = bizTypeByKey(bStr(_shop['biz_type']));
    final beauty = bwBeauty(bizKeyOf(_shop));
    final showGender = beauty && (gender == 'men' || gender == 'women');
    final sw = bwShop(bizKeyOf(_shop), t.lang);
    return Glass(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bStr(_shop['photo_url']).isNotEmpty)
            ShopPhoto(
              url: bStr(_shop['photo_url']),
              width: double.infinity,
              height: 180,
              radius: 20,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(bStr(_shop['name']),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                    if (count > 0) ...[
                      const Icon(Icons.star_rounded,
                          size: 20, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(localDigits(avg.toStringAsFixed(1), t.lang),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Text('(${fmtNum(count, t.lang)})',
                          style: TextStyle(color: muted(context))),
                    ] else
                      Pill(t.t('cu_new')),
                  ],
                ),
                if (bizT != null || showGender) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (bizT != null) Pill(bizT.name(t.lang)),
                    if (showGender)
                      Pill(gender == 'men'
                          ? _x(t.lang, 'مردانه', 'Men', 'رجالي')
                          : _x(t.lang, 'زنانه', 'Women', 'نسائي')),
                  ]),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_rounded,
                          size: 18, color: muted(context)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(localDigits(address, t.lang))),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      bSnack(context, t.t('b_copied'));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 18, color: muted(context)),
                          const SizedBox(width: 6),
                          Text(localDigits(phone, t.lang),
                              textDirection: TextDirection.ltr),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded,
                              size: 14, color: muted(context)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(desc, style: TextStyle(color: muted(context))),
                ],
                const SizedBox(height: 10),
                Text(_policy(t),
                    style: TextStyle(color: muted(context), fontSize: 12)),
                if (hasRules) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openRules(t.lang),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rule_rounded,
                              size: 18, color: lk(context).primary),
                          const SizedBox(width: 6),
                          Text(
                            _x(t.lang, 'قوانین این $sw',
                                'This $sw’s rules', 'قوانين هذا $sw'),
                            style: TextStyle(
                                color: lk(context).primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _content(T6 t) {
    final bt = BT(t.lang);
    final type = bizKeyOf(_shop);
    final sw = bwShop(type, t.lang);
    final cur = bStr(_shop['currency']);
    var total = 0;
    var totalDur = 0;
    for (final id in _picked) {
      final s = _svc(id);
      total += bInt(s['price']);
      totalDur += bInt(s['duration_min']);
    }
    final slots = _slots;
    final now = DateTime.now();
    final days = <DateTime>[
      for (var i = 0; i <= _maxAdvance; i++)
        if (!_isOff(DateTime(now.year, now.month, now.day + i)))
          DateTime(now.year, now.month, now.day + i),
    ];
    final hasRules = bStr(_shop['rules']).trim().isNotEmpty;
    final noAds = _truthy(_shop['no_ads']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _header(t),
        if (widget.hasTheme) ...[
          const SizedBox(height: 10),
          GradientButton(
            outlined: true,
            compact: true,
            icon: Icons.palette_rounded,
            label: widget.themeOn ? bt.t('th_btn_off') : bt.t('th_btn_on'),
            onPressed: widget.onToggle,
          ),
        ],
        StoreButton(
          store: _shop['store'],
          plan: bStr(_shop['plan']),
          lang: t.lang,
        ),
        _label(t.t('cu_services')),
        if (_services.isEmpty)
          Glass(
            child: Text(t.t('cu_no_services'),
                style: TextStyle(color: muted(context))),
          )
        else ...[
          Text(t.t('cu_pick'),
              style: TextStyle(color: muted(context), fontSize: 12.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _services)
                FilterChip(
                  label: Text([
                    bStr(s['name']),
                    '${fmtNum(bInt(s['duration_min']), t.lang)} ${t.t('b_min')}',
                    if (bInt(s['price']) > 0)
                      '${fmtNum(bInt(s['price']), t.lang)} $cur'.trim(),
                  ].join(' · ')),
                  selected: _picked.contains(bStr(s['service_id'])),
                  onSelected: (_) => _toggle(bStr(s['service_id'])),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.t('m_max', {'n': fmtNum(_maxServices, t.lang)}),
              style: TextStyle(color: muted(context), fontSize: 12)),
        ],
        if (_picked.isNotEmpty) ...[
          _label(bwStaff(type, t.lang)),
          for (final sid in _picked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _choiceRow(sid, t),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${t.t('cu_total')}: ',
                  style: TextStyle(color: muted(context))),
              Text('${fmtNum(total, t.lang)} $cur'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Text('· ${fmtNum(totalDur, t.lang)} ${t.t('b_min')}',
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ],
        _label(t.t('m_date')),
        if (days.isEmpty)
          Glass(
            child: Text(t.t('m_no_slots'),
                style: TextStyle(color: muted(context))),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in days)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(_dayLabel(d, t)),
                      selected: bIso(d) == bIso(_day),
                      onSelected: (_) => _setDay(d),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(localDigits(bIso(_day), t.lang),
            textDirection: TextDirection.ltr,
            style: TextStyle(color: muted(context), fontSize: 12)),
        const SizedBox(height: 12),
        GradientButton(
          outlined: true,
          loading: _slotsBusy,
          icon: Icons.schedule_rounded,
          label: t.t('m_show_slots'),
          onPressed: () {
            if (!_slotsBusy) _loadSlots();
          },
        ),
        if (slots != null) ...[
          _label(t.t('m_slots')),
          if (slots.isEmpty)
            Glass(
              child: Text(t.t('m_no_slots'),
                  style: TextStyle(color: muted(context))),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < slots.length; i++)
                  ChoiceChip(
                    label: Text(localDigits(bStr(slots[i]['start']), t.lang),
                        textDirection: TextDirection.ltr),
                    selected: i == _slotIdx,
                    onSelected: (_) => setState(() => _slotIdx = i),
                  ),
              ],
            ),
        ],
        if (slots != null && _slotIdx >= 0 && _slotIdx < slots.length) ...[
          _label(t.t('cu_summary')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in bRows(slots[_slotIdx]['assign']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${bStr(_svc(bStr(a['service_id']))['name'])} · ${_staffName(bStr(a['staff_id']))}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(
                            localDigits(
                                '${bStr(a['start'])} – ${bStr(a['end'])}',
                                t.lang),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: muted(context))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        GlassField(
          controller: _name,
          label: t.t('cu_your_name'),
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 4),
        Text(
          _x(
              t.lang,
              'نام واقعی خود را بنویسید تا کسب‌وکار شما را بشناسد.',
              'Enter your real name so the business knows who you are.',
              'اكتب اسمك الحقيقي ليعرفك النشاط التجاري.'),
          style: TextStyle(color: muted(context), fontSize: 12),
        ),
        const SizedBox(height: 12),
        GlassField(
          controller: _phone,
          label: t.t('cu_your_phone'),
          icon: Icons.phone_rounded,
          keyboard: TextInputType.phone,
          ltr: true,
        ),
        const SizedBox(height: 6),
        Text(t.t('cu_saved_note'),
            style: TextStyle(color: muted(context), fontSize: 12)),
        if (hasRules) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _openRules(t.lang),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _x(
                    t.lang,
                    'با ثبت نوبت، قوانین این $sw را می‌پذیرید. (مشاهده‌ی قوانین)',
                    'By booking you accept this $sw’s rules. (View rules)',
                    'بالحجز توافق على قوانين هذا $sw. (عرض القوانين)'),
                style: TextStyle(
                    color: lk(context).primary,
                    fontSize: 12.5,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        GradientButton(
          loading: _busy,
          icon: Icons.check_rounded,
          label: t.t('cu_book'),
          onPressed: () {
            if (!_busy) _book();
          },
        ),
        const SizedBox(height: 14),
        Center(
          child: ReportButton(
            st: widget.api.st,
            shopId: _shopId,
            shopName: bStr(_shop['name']),
            plan: bStr(_shop['plan']),
            city: bStr(_shop['city']),
            server: bStr(widget.card['_server']),
          ),
        ),
        if (!noAds) ...[
          const SizedBox(height: 22),
          AdsBox(
            st: widget.api.st,
            type: bizKeyOf(_shop),
            excludeShopId: _shopId,
            excludeServer: bStr(widget.card['_server']),
            onOpen: _openAd,
          ),
        ],
      ],
    );
  }
  Widget _choiceRow(String sid, T6 t) {
    final svc = _svc(sid);
    final el = _eligible(sid);
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bStr(svc['name']),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (el.isEmpty)
            Text(t.t('m_staff_none'),
                style: TextStyle(color: lk(context).danger))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.t('m_any')),
                  selected: (_choice[sid] ?? '').isEmpty,
                  onSelected: (_) => setState(() {
                    _choice[sid] = '';
                    _resetSlots();
                  }),
                ),
                for (final s in el)
                  ChoiceChip(
                    label: Text(
                      bInt(s['rating_count']) > 0
                          ? '${bStr(s['name'])} ★ ${localDigits(cDouble(s['rating_avg']).toStringAsFixed(1), t.lang)}'
                          : bStr(s['name']),
                    ),
                    selected: _choice[sid] == bStr(s['staff_id']),
                    onSelected: (_) => setState(() {
                      _choice[sid] = bStr(s['staff_id']);
                      _resetSlots();
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
