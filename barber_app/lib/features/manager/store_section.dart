import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/store_texts.dart';
import '../../app/widgets.dart';
import 'shop_raw.dart';

class _It {
  final TextEditingController name;
  String url;
  Uint8List? bytes;
  String fileName = '';
  _It(String n, this.url) : name = TextEditingController(text: n);
}

/// بخش «فروشگاه / سایت» در تنظیمات آرایشگاه (پرو و ویژه).
class StoreSection extends StatefulWidget {
  final AppSettings st;
  final String plan;
  const StoreSection({super.key, required this.st, required this.plan});

  @override
  State<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<StoreSection> {
  final _url = TextEditingController();
  final _label = TextEditingController();
  final List<_It> _items = [];
  bool _loading = true;
  bool _saving = false;
  bool _on = false;
  String? _error;
  int _max = 3;
  bool _images = false;

  bool get _allowed =>
      widget.plan == 'pro' || widget.plan == 'special' || widget.plan == 'personal';

  StoreT get _x => StoreT(widget.st.lang);

  @override
  void initState() {
    super.initState();
    _max = widget.plan == 'pro' ? 3 : 5;
    _images = widget.plan != 'pro';
    if (_allowed) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    for (final i in _items) {
      i.name.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dynamic r = await ShopRaw(widget.st).call('store_get');
      final Map m = r is Map ? r : <String, dynamic>{};
      _on = m['on'] == true || '${m['on']}' == 'true';
      _url.text = '${m['url'] ?? ''}';
      _label.text = '${m['label'] ?? ''}';
      final mx = int.tryParse('${m['max_items'] ?? ''}');
      if (mx != null && mx > 0) _max = mx;
      if (m['images'] != null) _images = m['images'] == true || '${m['images']}' == 'true';
      for (final i in _items) {
        i.name.dispose();
      }
      _items.clear();
      final list = m['items'];
      if (list is List) {
        for (final it in list) {
          if (it is Map) {
            _items.add(_It('${it['name'] ?? ''}', '${it['img'] ?? ''}'));
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _pick(_It it) async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (r == null || r.files.isEmpty) return;
      final f = r.files.first;
      final b = f.bytes;
      if (b == null) return;
      if (b.length > 600 * 1024) {
        _msg(_x.t('too_big'));
        return;
      }
      setState(() {
        it.bytes = b;
        it.fileName = f.name;
      });
    } catch (e) {
      _msg(e.toString());
    }
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    final label = _label.text.trim();
    if (_on) {
      if (!RegExp(r'^https://[^\s]+\.[^\s]+$', caseSensitive: false).hasMatch(url)) {
        _msg(_x.t('bad_url'));
        return;
      }
      if (label.isEmpty) {
        _msg(_x.t('need_label'));
        return;
      }
    }
    final items = <Map<String, dynamic>>[];
    for (final it in _items) {
      final n = it.name.text.trim();
      if (n.isEmpty) continue;
      final row = <String, dynamic>{'name': n};
      if (_images) {
        if (it.bytes != null) {
          row['img_b64'] = base64Encode(it.bytes!);
          row['img_name'] = it.fileName;
        } else {
          row['img_url'] = it.url;
        }
      }
      items.add(row);
    }
    setState(() => _saving = true);
    try {
      await ShopRaw(widget.st).call('store_save', {
        'on': _on,
        'url': url,
        'label': label,
        'items': items,
      });
      _msg(_x.t('saved'));
      await _load();
    } catch (e) {
      _msg(e.toString());
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _thumb(_It it) {
    const s = 56.0;
    Widget child;
    if (!_images) {
      child = Image.asset('assets/logo.png', width: s, height: s, fit: BoxFit.cover);
    } else if (it.bytes != null) {
      child = Image.memory(it.bytes!, width: s, height: s, fit: BoxFit.cover);
    } else if (it.url.isNotEmpty) {
      child = Image.network(
        it.url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: s,
          height: s,
          child: Icon(Icons.image_outlined),
        ),
      );
    } else {
      child = const SizedBox(width: s, height: s, child: Icon(Icons.image_outlined));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final x = _x;
    Widget content;
    if (!_allowed) {
      content = Text(x.t('locked'));
    } else if (_loading) {
      content = const Center(
        child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: Text(x.t('retry'))),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(x.t('hint'), style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(x.t('on')),
            value: _on,
            onChanged: (v) => setState(() => _on = v),
          ),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: x.t('url'), hintText: 'https://'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _label,
            maxLength: 24,
            decoration: InputDecoration(labelText: x.t('label')),
          ),
          const SizedBox(height: 4),
          Text(x.t('items', {'n': '$_max'}),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (!_images)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(x.t('pro_img'), style: const TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 6),
          for (final it in List<_It>.from(_items))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _thumb(it),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: it.name,
                          maxLength: 40,
                          decoration: InputDecoration(labelText: x.t('item_name')),
                        ),
                        if (_images)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: () => _pick(it),
                              child: Text(
                                (it.bytes != null || it.url.isNotEmpty)
                                    ? x.t('change')
                                    : x.t('pick'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: x.t('remove'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => setState(() {
                      _items.remove(it);
                      it.name.dispose();
                    }),
                  ),
                ],
              ),
            ),
          if (_items.length < _max)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _items.add(_It('', ''))),
                icon: const Icon(Icons.add_rounded),
                label: Text(x.t('add')),
              ),
            ),
          const SizedBox(height: 8),
          GradientButton(
            label: x.t('save'),
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(x.t('title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }
}
