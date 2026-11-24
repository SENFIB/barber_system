import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../manager/booking_common.dart';
import 'customer_api.dart';
import 'customer_shop_page.dart';

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
  bool _loading = true;
  Object? _err;
  List<Map<String, dynamic>> _shops = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _q.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
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

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.api.shopSearch(_q.text.trim());
      if (!mounted || seq != _seq) return;
      setState(() {
        _shops = bFirstList(r, ['shops']);
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
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopPage(api: widget.api, card: shop),
      ),
    );
    if (ok == true && mounted) widget.onBooked();
  }

  @override
  Widget build(BuildContext context) {
    final t = T6(SettingsScope.of(context).lang);
    final children = <Widget>[
      GlassField(
        controller: _q,
        label: t.t('cu_search'),
        icon: Icons.search_rounded,
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
              Text(t.t('cu_no_shops'),
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

  Widget _card(Map<String, dynamic> s, T6 t) {
    final avg = cDouble(s['rating_avg']);
    final count = bInt(s['rating_count']);
    final sep = t.lang == 'en' ? ', ' : '، ';
    final place = [bStr(s['city']), bStr(s['address'])]
        .where((e) => e.isNotEmpty)
        .join(sep);
    return Glass(
      onTap: () => _open(s),
      child: Row(
        children: [
          ShopPhoto(url: bStr(s['photo_url']), width: 72, height: 72),
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
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(place,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted(context), fontSize: 12.5)),
                ],
                const SizedBox(height: 6),
                if (count > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(localDigits(avg.toStringAsFixed(1), t.lang),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Text(t.t('cu_reviews', {'n': fmtNum(count, t.lang)}),
                          style: TextStyle(
                              color: muted(context), fontSize: 12)),
                    ],
                  )
                else
                  Wrap(children: [Pill(t.t('cu_new'))]),
              ],
            ),
          ),
          Icon(chevron(context), color: muted(context)),
        ],
      ),
    );
  }
}
