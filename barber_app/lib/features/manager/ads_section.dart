import 'package:flutter/material.dart';
import '../../app/biz_text.dart';
import '../../app/business_types.dart';
import '../../app/cal_fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s2.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import 'shop_raw.dart';

bool _b(dynamic v) => v == true || '$v' == 'true' || '$v' == '1';
String _s(dynamic v) => v == null ? '' : '$v';
String _codeOf(Object e) {
  try {
    return ((e as dynamic).code ?? '').toString();
  } catch (_) {
    return '';
  }
}

/// صفحه‌ی تبلیغات: سه کادر جدا
/// ۱) کد تبلیغ  ۲) انتخاب جاهای نمایش (همیشه باز) + دکمه‌ی فعال‌سازی  ۳) بدون تبلیغ
class AdsSection extends StatefulWidget {
  const AdsSection({super.key});
  @override
  State<AdsSection> createState() => _AdsSectionState();
}

class _AdsSectionState extends State<AdsSection> {
  final _text = TextEditingController();
  final _promoCode = TextEditingController();
  final _noAdsCode = TextEditingController();
  final Set<String> _cats = <String>{};
  bool _loading = true;
  bool _busyNo = false;
  bool _busySave = false;
  String? _err;
  bool _free = false; // ویژه/شخصی: رایگان
  bool _adOn = false;
  bool _noAdsOn = false;
  bool _adActive = false;
  bool _noAdsActive = false;
  String _adUntil = '';
  String _noAdsUntil = '';
  String _own = 'barber';

  AppSettings get _st => SettingsScope.read(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    _promoCode.dispose();
    _noAdsCode.dispose();
    super.dispose();
  }

  /// keep=true: متن و دسته‌هایی که کاربر تیک زده دست‌نخورده می‌مانند
  Future<void> _load({bool keep = false}) async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await ShopRaw(_st).call('ad_get');
      if (!mounted) return;
      setState(() {
        final plan = _s(d['plan']).toLowerCase();
        _free = _b(d['free']) || plan == 'special' || plan == 'personal';
        _adOn = _b(d['ad_on']);
        _noAdsOn = _b(d['no_ads_on']);
        _adActive = _free ? _adOn : _b(d['ad_active']);
        _noAdsActive = _free ? _noAdsOn : _b(d['no_ads_active']);
        _adUntil = _s(d['ad_until']);
        _noAdsUntil = _s(d['no_ads_until']);
        final own = _s(d['biz_type']);
        _own = bizTypeByKey(own) != null ? own : 'barber';
        if (!keep) {
          _text.text = _s(d['ad_text']);
          _cats.clear();
          final c = d['ad_cats'];
          if (c is List) {
            for (final e in c) {
              if (bizTypeByKey('$e') != null) _cats.add('$e');
            }
          } else if (c is String) {
            for (final e in c.split(RegExp(r'[|,]'))) {
              if (bizTypeByKey(e.trim()) != null) _cats.add(e.trim());
            }
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = T2(_st.lang).error(e);
      });
    }
  }

  void _redeemErr(Object e) {
    final bt = BT(_st.lang);
    final c = _codeOf(e);
    final m = '$e';
    if (c == 'AD_CODE_USED' || m.contains('AD_CODE_USED')) {
      toast(context, bt.t('ad_code_used'));
    } else if (c == 'AD_CODE_INVALID' || m.contains('AD_CODE_INVALID')) {
      toast(context, bt.t('ad_code_bad'));
    } else {
      toast(context, T2(_st.lang).error(e));
    }
  }

  Future<bool> _redeemCall(String code) async {
    try {
      await ShopRaw(_st).call('ad_redeem', {'code': code});
      return true;
    } catch (e) {
      if (mounted) _redeemErr(e);
      return false;
    }
  }

  /// کد «بدون تبلیغ»
  Future<void> _redeemNoAds() async {
    final bt = BT(_st.lang);
    final code = normalizeDigits(_noAdsCode.text).trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _busyNo = true);
    final ok = await _redeemCall(code);
    if (!mounted) return;
    setState(() => _busyNo = false);
    if (ok) {
      _noAdsCode.clear();
      toast(context, bt.t('ad_code_ok'));
      await _load(keep: true);
    }
  }

  Future<void> _post() async {
    await ShopRaw(_st).call('ad_save', {
      'ad_text': _text.text.trim(),
      'ad_cats': _cats.toList(),
      'ad_on': _adOn,
      'no_ads_on': _noAdsOn,
    });
  }

  /// دکمه‌ی فعال‌سازی: کد (در صورت نیاز) + جاهای تیک‌خورده با هم ثبت می‌شوند
  Future<void> _activate() async {
    final bt = BT(_st.lang);
    final text = _text.text.trim();
    final code = normalizeDigits(_promoCode.text).trim().toUpperCase();
    if (!_free && !_adActive && code.isEmpty) {
      toast(context, bt.t('ad_code_bad'));
      return;
    }
    if (text.isEmpty) {
      toast(context, bt.t('ad_need_text'));
      return;
    }
    if (text.runes.length > 60) {
      toast(context, bt.t('ad_text_long'));
      return;
    }
    if (_cats.isEmpty) {
      toast(context, bt.t('ad_need_cat'));
      return;
    }
    setState(() => _busySave = true);
    try {
      if (!_free && code.isNotEmpty) {
        final ok = await _redeemCall(code);
        if (!ok) return;
        _promoCode.clear();
      }
      _adOn = true;
      _adActive = true;
      await _post();
      if (!mounted) return;
      toast(context, bt.t('ad_saved'));
      await _load(keep: true);
    } catch (e) {
      if (!mounted) return;
      toast(context, T2(_st.lang).error(e));
    } finally {
      if (mounted) setState(() => _busySave = false);
    }
  }

  /// کلید تبلیغ برای پلن‌های رایگان: خاموش‌کردن همان لحظه ذخیره می‌شود
  Future<void> _toggleAd(bool v) async {
    final bt = BT(_st.lang);
    final old = _adOn;
    setState(() {
      _adOn = v;
      _adActive = v;
    });
    if (v) return; // روشن‌کردن با دکمه‌ی فعال‌سازی ثبت می‌شود
    try {
      await _post();
      if (!mounted) return;
      toast(context, bt.t('ad_saved'));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adOn = old;
        _adActive = old;
      });
      toast(context, T2(_st.lang).error(e));
    }
  }

  /// کلید «بدون تبلیغ» برای پلن‌های رایگان: همان لحظه ذخیره می‌شود
  Future<void> _toggleNoAds(bool v) async {
    final bt = BT(_st.lang);
    final old = _noAdsOn;
    setState(() {
      _noAdsOn = v;
      _noAdsActive = v;
    });
    try {
      await _post();
      if (!mounted) return;
      toast(context, bt.t('ad_saved'));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _noAdsOn = old;
        _noAdsActive = old;
      });
      toast(context, T2(_st.lang).error(e));
    }
  }

  Widget _switchRow(String label, bool v, ValueChanged<bool> on) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Switch(value: v, onChanged: on),
      ],
    );
  }

  Widget _catPicker(BT bt, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in kBizGroups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(g.name(lang),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: muted(context))),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in bizTypesOf(g.key))
                FilterChip(
                  showCheckmark: true,
                  label: Text(bizNotRecommended(_own, t.key)
                      ? '${t.name(lang)} (${bt.t('ad_not_rec')})'
                      : t.name(lang)),
                  selected: _cats.contains(t.key),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _cats.add(t.key);
                      } else {
                        _cats.remove(t.key);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _box(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        Glass(child: child),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _hint(String text) {
    return Text(text,
        style: TextStyle(color: muted(context), fontSize: 12.5, height: 1.6));
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final lang = st.lang;
    final bt = BT(lang);

    if (_loading) {
      return const Glass(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_err != null) {
      return Glass(
        child: Column(
          children: [
            Text(_err!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GradientButton(
              compact: true,
              icon: Icons.refresh_rounded,
              label: T2(lang).t('retry'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    String until(String iso) => CalFmt.date(iso, st.calendarKey, lang);
    final activateLabel =
        lang == 'fa' ? 'فعال‌سازی' : (lang == 'ar' ? 'تفعيل' : 'Activate');

    // ---------- کادر ۱: کد تبلیغ (لایسنس) ----------
    final Widget promoInner;
    if (_free) {
      promoInner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(bt.t('ad_hint')),
          const SizedBox(height: 8),
          _switchRow(bt.t('ad_free_on'), _adOn, _toggleAd),
        ],
      );
    } else {
      promoInner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(bt.t('ad_promo_hint')),
          const SizedBox(height: 12),
          Text(
            _adActive && _adUntil.isNotEmpty
                ? bt.t('ad_on_until', {'d': until(_adUntil)})
                : bt.t('ad_off'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          GlassField(
            controller: _promoCode,
            label: bt.t('ad_promo_code'),
            icon: Icons.vpn_key_rounded,
            ltr: true,
          ),
        ],
      );
    }

    // ---------- کادر ۲: کجا نمایش داده شود (همیشه باز) + فعال‌سازی ----------
    final Widget whereInner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hint(bt.t('ad_where_hint')),
        const SizedBox(height: 12),
        GlassField(
          controller: _text,
          label: '${bt.t('ad_text')} (${bt.t('ad_text_hint')})',
          icon: Icons.campaign_rounded,
        ),
        const SizedBox(height: 14),
        Text(bt.t('ad_cats'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        _catPicker(bt, lang),
        const SizedBox(height: 16),
        GradientButton(
          loading: _busySave,
          icon: Icons.check_rounded,
          label: activateLabel,
          onPressed: _activate,
        ),
      ],
    );

    // ---------- کادر ۳: بدون تبلیغ ----------
    final Widget noAdsInner;
    if (_free) {
      noAdsInner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(bt.t('ad_noads_hint')),
          const SizedBox(height: 8),
          _switchRow(bt.t('ad_free_none'), _noAdsOn, _toggleNoAds),
        ],
      );
    } else {
      noAdsInner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(bt.t('ad_noads_hint')),
          const SizedBox(height: 12),
          Text(
            _noAdsActive && _noAdsUntil.isNotEmpty
                ? bt.t('ad_noads_until', {'d': until(_noAdsUntil)})
                : bt.t('ad_noads_off'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          GlassField(
            controller: _noAdsCode,
            label: bt.t('ad_noads_code'),
            icon: Icons.block_rounded,
            ltr: true,
          ),
          const SizedBox(height: 10),
          GradientButton(
            outlined: true,
            compact: true,
            loading: _busyNo,
            icon: Icons.check_rounded,
            label: bt.t('ad_code_btn'),
            onPressed: _redeemNoAds,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(bt.t('ad_box_promo'), promoInner),
        _box(bt.t('ad_box_where'), whereInner),
        _box(bt.t('ad_box_noads'), noAdsInner),
      ],
    );
  }
}
