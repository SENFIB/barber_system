import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/biz_text.dart';
import '../../app/config.dart';
import '../../app/extra_http.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';
import 'customer_filters.dart';

class _AdCache {
  _AdCache(this.at, this.ads);
  final DateTime at;
  final List<Map<String, dynamic>> ads;
}

/// کادر کوچک «معرفی» ته صفحه‌ی آرایشگاه
class AdsBox extends StatefulWidget {
  const AdsBox({
    super.key,
    required this.st,
    required this.type,
    required this.excludeShopId,
    required this.excludeServer,
    required this.onOpen,
  });
  final AppSettings st;
  final String type;
  final String excludeShopId;
  final String excludeServer;
  final void Function(Map<String, dynamic> ad) onOpen;

  @override
  State<AdsBox> createState() => _AdsBoxState();
}

class _AdsBoxState extends State<AdsBox> {
  static final Map<String, _AdCache> _cache = <String, _AdCache>{};
  Map<String, dynamic>? _ad;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final c = _cache[widget.type];
    if (c != null && DateTime.now().difference(c.at).inMinutes < 5) {
      return c.ads;
    }
    final urls = await CustomerSearch.servers(widget.st);
    final parts = await Future.wait(urls.map((u) async {
      try {
        final d = await extraPublic(u, 'ads_list', {'type': widget.type})
            .timeout(const Duration(seconds: 12));
        final out = <Map<String, dynamic>>[];
        final l = d['ads'];
        if (l is List) {
          for (final a in l) {
            if (a is Map) {
              final m = Map<String, dynamic>.from(a);
              m['_server'] = u;
              out.add(m);
            }
          }
        }
        return out;
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }));
    final all = <Map<String, dynamic>>[for (final p in parts) ...p];
    _cache[widget.type] = _AdCache(DateTime.now(), all);
    return all;
  }

  Future<void> _load() async {
    try {
      final all = await _fetch();
      final ex = widget.excludeServer.isEmpty
          ? kDefaultApiUrl
          : widget.excludeServer;
      final ok = all.where((a) {
        final same = '${a['_server']}' == ex &&
            '${a['shop_id']}' == widget.excludeShopId;
        return !same;
      }).toList();
      if (!mounted || ok.isEmpty) return;
      setState(() => _ad = ok[Random().nextInt(ok.length)]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    final st = SettingsScope.of(context);
    final bt = BT(st.lang);
    final name = '${ad['name'] ?? ''}';
    final city = '${ad['city'] ?? ''}'.trim();
    final text = '${ad['ad_text'] ?? ''}'.trim();
    final photo = '${ad['photo_url'] ?? ''}'.trim();
    return Glass(
      onTap: () => widget.onOpen(ad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bt.t('ad_label'),
              style: TextStyle(color: muted(context), fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (photo.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photo,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 46, height: 46),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.isEmpty ? name : '$name · $city',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: muted(context), fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              Icon(chevron(context), color: muted(context)),
            ],
          ),
        ],
      ),
    );
  }
}
