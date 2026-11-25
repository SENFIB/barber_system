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

/// بخش «معرفی شما در دیگر آرایشگاه‌ها و کسب‌وکارها» داخل تنظیمات آرایشگاه
class AdsSection extends StatefulWidget {
  const AdsSection({super.key});
  @override
  State<AdsSection> createState() => _AdsSectionState();
}

class _AdsSectionState extends State<AdsSection> {
  final _text = TextEditingController();
  final _code = TextEditingController();
  final Set<String> _cats = <String>{};
  bool _loading = true;
  bool _busy = false;
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
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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

  Future<void> _redeem() async {
    final bt = BT(_st.lang);
    final code = normalizeDigits(_code.text).trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ShopRaw(_st).call('ad_redeem', {'code': code});
      if (!mounted) return;
      _code.clear();
      toast(context, bt.t('ad_code_ok'));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final c = _codeOf(e);
      final m = '$e';
      if (c == 'AD_CODE_USED' || m.contains('AD_CODE_USED')) {
        toast(context, bt.t('ad_code_used'));
      } else if (c == 'AD_CODE_INVALID' || m.contains('AD_CODE_INVALID')) {
        toast(context, bt.t('ad_code_bad'));
      } else {
        toast(context, T2(_st.lang).error(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final bt = BT(_st.lang);
    final text = _text.text.trim();
    final active = _adActive;
    if (active && text.isEmpty) {
      toast(context, bt.t('ad_need_text'));
      return;
    }
    if (text.runes.length > 60) {
      toast(context, bt.t('ad_text_long'));
      return;
    }
    if (active && _cats.isEmpty) {
      toast(context, bt.t('ad_need_cat'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ShopRaw(_st).call('ad_save', {
        'ad_text': text,
        'ad_cats': _cats.toList(),
        'ad_on': _adOn,
        'no_ads_on': _noAdsOn,
      });
      if (!mounted) return;
      toast(context, bt.t('ad_saved'));
    } catch (e) {
      if (!mounted) return;
      toast(context, T2(_st.lang).error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Widget _cats_(BT bt, String lang) {
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

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final lang = st.lang;
    final bt = BT(lang);
    Widget inner;
    if (_loading) {
      inner = const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_err != null) {
      inner = Column(
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
      );
    } else {
      String until(String iso) => CalFmt.date(iso, st.calendarKey, lang);
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bt.t('ad_hint'),
              style:
                  TextStyle(color: muted(context), fontSize: 12.5, height: 1.6)),
          const SizedBox(height: 12),
          if (_free) ...[
            _switchRow(bt.t('ad_free_on'), _adOn, (v) => setState(() {
                  _adOn = v;
                  _adActive = v;
                })),
            _switchRow(bt.t('ad_free_none'), _noAdsOn,
                (v) => setState(() => _noAdsOn = v)),
          ] else ...[
            Text(
              _adActive && _adUntil.isNotEmpty
                  ? bt.t('ad_on_until', {'d': until(_adUntil)})
                  : bt.t('ad_off'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (_noAdsActive && _noAdsUntil.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(bt.t('ad_noads_until', {'d': until(_noAdsUntil)}),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 12),
            GlassField(
              controller: _code,
              label: bt.t('ad_code'),
              icon: Icons.vpn_key_rounded,
              ltr: true,
            ),
            const SizedBox(height: 4),
            Text(bt.t('ad_code_hint'),
                style: TextStyle(color: muted(context), fontSize: 12)),
            const SizedBox(height: 10),
            GradientButton(
              outlined: true,
              compact: true,
              loading: _busy,
              icon: Icons.check_rounded,
              label: bt.t('ad_code_btn'),
              onPressed: _redeem,
            ),
          ],
          if (_adActive) ...[
            const SizedBox(height: 16),
            GlassField(
              controller: _text,
              label: '${bt.t('ad_text')} (${bt.t('ad_text_hint')})',
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: 14),
            Text(bt.t('ad_cats'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            _cats_(bt, lang),
          ],
          if (_free || _adActive) ...[
            const SizedBox(height: 16),
            GradientButton(
              loading: _busy,
              icon: Icons.check_rounded,
              label: bt.t('ad_save'),
              onPressed: _save,
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(bt.t('ad_title')),
        Glass(child: inner),
      ],
    );
  }
}
