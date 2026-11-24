import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/strings_s2.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'plans_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

/// تنظیمات آرایشگاه (فقط مدیر)
class ShopSettingsPage extends StatefulWidget {
  const ShopSettingsPage(this.ctx, {super.key});
  final ShopCtx ctx;

  @override
  State<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends State<ShopSettingsPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _desc = TextEditingController();
  final _photo = TextEditingController();
  final _currency = TextEditingController();
  final _tz = TextEditingController();
  final _step = TextEditingController();
  final _buffer = TextEditingController();
  final _ot = TextEditingController();
  final _cancel = TextEditingController();
  String _cal = 'jalali';
  String _plan = '';
  bool _loading = true;
  bool _busy = false;
  String? _err;

  String get _lang => SettingsScope.read(context).lang;

  /// عکس آرایشگاه فقط برای پلن ویژه و شخصی
  bool get _photoOk => _plan == 'special' || _plan == 'personal';

  /// متن‌های کوچکِ همین صفحه (فارسی / انگلیسی / عربی)
  String _px(String fa, String en, String ar) {
    final code = '${SettingsScope.read(context).lang}'.toLowerCase();
    if (code.endsWith('en')) return en;
    if (code.endsWith('ar')) return ar;
    return fa;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _city, _address, _desc, _photo, //
      _currency, _tz, _step, _buffer, _ot, _cancel,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final me = await ShopRaw(SettingsScope.read(context)).call('me');
      final sh = me['shop'] is Map
          ? Map<String, dynamic>.from(me['shop'] as Map)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _name.text = jStr(sh['name']);
        _phone.text = jStr(sh['phone']);
        _city.text = jStr(sh['city']);
        _address.text = jStr(sh['address']);
        _desc.text = jStr(sh['description']);
        _photo.text = jStr(sh['photo_url']);
        _currency.text = jStr(sh['currency']);
        _tz.text = jStr(sh['timezone']);
        _step.text = jStr(sh['slot_step_min']);
        _buffer.text = jStr(sh['buffer_min']);
        _ot.text = jStr(sh['overtime_min']);
        _cancel.text = jStr(sh['cancel_before_min']);
        _plan = jStr(sh['plan']).trim().toLowerCase();
        final c = jStr(sh['calendar']);
        _cal = const ['jalali', 'gregorian', 'hijri'].contains(c) ? c : 'jalali';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = T2(_lang).error(e);
      });
    }
  }

  int? _num(TextEditingController c) =>
      int.tryParse(normalizeDigits(c.text).trim());

  Future<void> _save() async {
    final x = T2(_lang);
    if (_name.text.trim().isEmpty) {
      toast(context, x.t('v_required'));
      return;
    }
    final step = _num(_step);
    final buffer = _num(_buffer);
    final ot = _num(_ot);
    final cancel = _num(_cancel);
    if (step == null || step < 5 || step > 120 || step % 5 != 0) {
      toast(context, x.t('ss_bad_step'));
      return;
    }
    if (buffer == null || buffer < 0 || buffer > 120 ||
        ot == null || ot < 0 || ot > 240 ||
        cancel == null || cancel < 0 || cancel > 10080) {
      toast(context, x.t('ed_bad_number'));
      return;
    }
    setState(() => _busy = true);
    try {
      final params = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': normalizeDigits(_phone.text).trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'description': _desc.text.trim(),
        'currency': _currency.text.trim(),
        'timezone': _tz.text.trim(),
        'calendar': _cal,
        'slot_step_min': step,
        'buffer_min': buffer,
        'overtime_min': ot,
        'cancel_before_min': cancel,
      };
      // عکس فقط برای پلن ویژه/شخصی فرستاده می‌شود
      if (_photoOk) params['photo_url'] = _photo.text.trim();
      await ShopRaw(SettingsScope.read(context)).call('shop_update', params);
      if (!mounted) return;
      toast(context, x.t('ss_saved'));
      widget.ctx.reload();
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      toast(context, x.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(t,
            style:
                TextStyle(color: muted(context), fontSize: 12.5, height: 1.6)),
      );

  Widget _chips(List<int> values, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text('$v'),
              selected: c.text.trim() == '$v',
              onSelected: (_) => setState(() => c.text = '$v'),
            ),
        ],
      ),
    );
  }

  /// بخش عکس: برای ویژه/شخصی فیلد لینک؛ برای بقیه کادر قفل با دکمه‌ی پلن‌ها
  Widget _photoBlock(T2 x) {
    if (_photoOk) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassField(
              controller: _photo,
              label: x.t('ss_photo'),
              icon: Icons.image_rounded,
              keyboard: TextInputType.url,
              ltr: true),
          _hint(_px(
            'لینک مستقیم یک عکس از آرایشگاه (فقط یک عکس). مشتری‌ها این عکس را در صفحه‌ی آرایشگاه می‌بینند.',
            'Direct link to one photo of your shop. Customers see it on your shop page.',
            'رابط مباشر لصورة واحدة لصالونك. يراها الزبائن في صفحة الصالون.',
          )),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lk(context).primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lk(context).primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, color: lk(context).primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _px(
                    'عکس آرایشگاه فقط برای پلن ویژه و شخصی است',
                    'Shop photo is only for the Special and Personal plans',
                    'صورة الصالون متاحة فقط لخطتي المميزة والشخصية',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            outlined: true,
            compact: true,
            icon: Icons.workspace_premium_rounded,
            label: _px('مشاهده‌ی پلن‌ها', 'View plans', 'عرض الخطط'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlansPage(widget.ctx)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final x = T2(st.lang);
    final unit = x.t('unit_min');

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_err!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: GradientButton(
                    label: x.t('retry'),
                    icon: Icons.refresh_rounded,
                    onPressed: _load),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          SectionLabel(x.t('ss_info')),
          Glass(
            child: Column(
              children: [
                GlassField(
                    controller: _name,
                    label: x.t('shop_name'),
                    icon: Icons.storefront_rounded),
                _gap(),
                GlassField(
                    controller: _phone,
                    label: x.t('phone'),
                    icon: Icons.phone_rounded,
                    keyboard: TextInputType.phone,
                    ltr: true),
                _gap(),
                GlassField(
                    controller: _city,
                    label: x.t('city'),
                    icon: Icons.location_city_rounded),
                _gap(),
                GlassField(
                    controller: _address,
                    label: x.t('address'),
                    icon: Icons.place_rounded),
                _gap(),
                GlassField(
                    controller: _desc,
                    label: x.t('ss_description'),
                    icon: Icons.notes_rounded),
                _gap(),
                _photoBlock(x),
                _gap(),
                GlassField(
                    controller: _currency,
                    label: x.t('ss_currency'),
                    icon: Icons.payments_rounded),
              ],
            ),
          ),
          SectionLabel(x.t('ss_booking')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassField(
                    controller: _step,
                    label: '${x.t('ss_step')} ($unit)',
                    icon: Icons.timelapse_rounded,
                    keyboard: TextInputType.number,
                    ltr: true),
                _hint(x.t('ss_step_hint')),
                _chips(const [5, 10, 15, 20, 30, 45, 60], _step),
                const SizedBox(height: 16),
                GlassField(
                    controller: _buffer,
                    label: '${x.t('ss_buffer')} ($unit)',
                    icon: Icons.pause_circle_outline_rounded,
                    keyboard: TextInputType.number,
                    ltr: true),
                _hint(x.t('ss_buffer_hint')),
                _chips(const [0, 5, 10, 15], _buffer),
                const SizedBox(height: 16),
                GlassField(
                    controller: _ot,
                    label: '${x.t('ss_overtime')} ($unit)',
                    icon: Icons.more_time_rounded,
                    keyboard: TextInputType.number,
                    ltr: true),
                _hint(x.t('ss_overtime_hint')),
                _chips(const [0, 5, 10, 15, 20, 30], _ot),
                const SizedBox(height: 16),
                GlassField(
                    controller: _cancel,
                    label: '${x.t('ss_cancel')} ($unit)',
                    icon: Icons.event_busy_rounded,
                    keyboard: TextInputType.number,
                    ltr: true),
                _hint(x.t('ss_cancel_hint')),
                _chips(const [30, 60, 120, 180, 360, 720, 1440], _cancel),
              ],
            ),
          ),
          SectionLabel(x.t('ss_calendar')),
          Glass(
            child: SegmentPicker<String>(
              options: [
                MapEntry('jalali', x.t('cal_jalali')),
                MapEntry('gregorian', x.t('cal_gregorian')),
                MapEntry('hijri', x.t('cal_hijri')),
              ],
              value: _cal,
              onChanged: (v) => setState(() => _cal = v),
            ),
          ),
          SectionLabel(x.t('ss_timezone')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassField(
                    controller: _tz,
                    label: x.t('ss_timezone'),
                    icon: Icons.public_rounded,
                    ltr: true),
                _hint(x.t('ss_tz_hint')),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final z in const [
                        'Asia/Tehran',
                        'Asia/Baghdad',
                        'Asia/Riyadh',
                        'Asia/Dubai',
                        'Europe/Istanbul',
                        'Europe/London',
                      ])
                        ChoiceChip(
                          label: Text(z, textDirection: TextDirection.ltr),
                          selected: _tz.text.trim() == z,
                          onSelected: (_) => setState(() => _tz.text = z),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: x.t('save'),
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _save,
          ),
        ],
      );
    }
    return GlassScaffold(title: x.t('ss_title'), body: body);
  }
}
