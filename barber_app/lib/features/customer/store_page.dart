import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/store_texts.dart';
import '../../app/widgets.dart';

class StoreData {
  final bool on;
  final String url;
  final String label;
  final List<Map<String, String>> items;

  const StoreData(this.on, this.url, this.label, this.items);

  static StoreData parse(dynamic raw) {
    if (raw is! Map) return const StoreData(false, '', '', []);
    final on = raw['on'] == true || raw['on'] == 1 || '${raw['on']}' == 'true';
    final url = '${raw['url'] ?? ''}'.trim();
    final label = '${raw['label'] ?? ''}'.trim();
    final items = <Map<String, String>>[];
    final list = raw['items'];
    if (list is List) {
      for (final it in list) {
        if (it is Map) {
          final name = '${it['name'] ?? ''}'.trim();
          if (name.isEmpty) continue;
          items.add({'name': name, 'img': '${it['img'] ?? ''}'.trim()});
        }
      }
    }
    return StoreData(on, url, label, items);
  }

  bool get validUrl => RegExp(r'^https://[^\s]+\.[^\s]+$', caseSensitive: false).hasMatch(url);

  bool get visible => on && validUrl && label.isNotEmpty;
}

Future<void> openStoreSite(String url) async {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https') return;
  await launchUrl(u, mode: LaunchMode.externalApplication);
}

/// دکمه‌ی فروشگاه/سایت در صفحه‌ی آرایشگاه. اگر خاموش باشد چیزی نشان نمی‌دهد.
class StoreButton extends StatelessWidget {
  final dynamic store;
  final String plan;
  final String lang;

  const StoreButton({
    super.key,
    required this.store,
    required this.plan,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final d = StoreData.parse(store);
    final planOk = plan == 'pro' || plan == 'special' || plan == 'personal';
    if (!planOk || !d.visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GradientButton(
        label: d.label,
        icon: Icons.storefront_rounded,
        outlined: true,
        onPressed: () {
          if (d.items.isEmpty) {
            openStoreSite(d.url);
          } else {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StorePage(data: d, plan: plan, lang: lang),
            ));
          }
        },
      ),
    );
  }
}

class StorePage extends StatelessWidget {
  final StoreData data;
  final String plan;
  final String lang;

  const StorePage({
    super.key,
    required this.data,
    required this.plan,
    required this.lang,
  });

  Widget _logo(double size) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/logo.png', width: size, height: size, fit: BoxFit.cover),
      );

  Widget _image(Map<String, String> it) {
    const size = 64.0;
    final own = plan != 'pro' && (it['img'] ?? '').isNotEmpty;
    if (!own) return _logo(size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        it['img']!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _logo(size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = StoreT(lang);
    return GlassScaffold(
      title: data.label,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final it in data.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Glass(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _image(it),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it['name'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          GradientButton(
            label: x.t('buy'),
            icon: Icons.open_in_new_rounded,
            onPressed: () => openStoreSite(data.url),
          ),
        ],
      ),
    );
  }
}
