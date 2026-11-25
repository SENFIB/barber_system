import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app/biz_text.dart';
import '../../app/look.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_ex.dart';
import '../../app/strings_s2.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

/// صفحه‌ی ظاهرسازی.
/// بدون پارامتر: ظاهر خود برنامه. با [onSave]: ظاهر اختصاصی صفحه‌ی آرایشگاه (پلن ویژه).
class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key, this.initial, this.onSave, this.title});
  final AppLook? initial;
  final Future<void> Function(AppLook look)? onSave;
  final String? title;
  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late AppLook _look = widget.initial ?? const AppLook();
  bool? _darkSel;
  bool _saving = false;

  bool get _shop => widget.onSave != null;

  Future<void> _save() async {
    final st = SettingsScope.read(context);
    setState(() => _saving = true);
    try {
      await widget.onSave!(_look);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      toast(context, T2(st.lang).error(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final base = Theme.of(context);
    final dark = _darkSel ?? (base.brightness == Brightness.dark);
    Widget body = _AppearanceBody(
      look: _shop ? _look : st.look,
      shop: _shop,
      title: widget.title,
      previewDark: dark,
      saving: _saving,
      onChange: (l) {
        if (_shop) {
          setState(() => _look = l);
        } else {
          st.setLook(l);
        }
      },
      onPreviewDark: (v) => setState(() => _darkSel = v),
      onSaveTap: _save,
    );
    if (_shop) {
      body = Theme(
        data: buildTheme(dark ? Brightness.dark : Brightness.light, _look),
        child: body,
      );
    }
    return body;
  }
}

class _CR {
  const _CR(this.key, this.perMode, this.labelKey, this.color,
      {this.alpha = false});
  final String key;
  final bool perMode;
  final String labelKey;
  final Color color;
  final bool alpha;
}

class _AppearanceBody extends StatefulWidget {
  const _AppearanceBody({
    required this.look,
    required this.shop,
    required this.title,
    required this.previewDark,
    required this.saving,
    required this.onChange,
    required this.onPreviewDark,
    required this.onSaveTap,
  });
  final AppLook look;
  final bool shop;
  final String? title;
  final bool previewDark;
  final bool saving;
  final void Function(AppLook look) onChange;
  final void Function(bool dark) onPreviewDark;
  final VoidCallback onSaveTap;
  @override
  State<_AppearanceBody> createState() => _AppearanceBodyState();
}

class _AppearanceBodyState extends State<_AppearanceBody> {
  bool _busy = false;

  AppLook get look => widget.look;

  Future<void> _pickImage() async {
    final st = SettingsScope.read(context);
    final x = X(st.lang);
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);
      if (r == null || r.files.isEmpty) return;
      final path = r.files.single.path;
      if (path == null) return;
      final len = await File(path).length();
      if (len > 20 * 1024 * 1024) {
        if (mounted) toast(context, x.t('ap_img_big'));
        return;
      }
      if (mounted) setState(() => _busy = true);
      await st.setBackgroundImage(path);
    } catch (_) {
      if (mounted) toast(context, x.t('ap_img_fail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setMode(String m) async {
    if (m == 'image' && !look.hasImage) {
      await _pickImage();
      return;
    }
    widget.onChange(look.copyWith(bgMode: m));
  }

  Future<void> _editColor(_CR r, String key, String title) async {
    final st = SettingsScope.read(context);
    final x = X(st.lang);
    final res = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _PickerSheet(
        x: x,
        initial: r.color,
        title: title,
        withAlpha: r.alpha,
      ),
    );
    if (res == null) return;
    widget.onChange(look.withColor(key, res.reset ? null : res.color));
  }

  Future<void> _resetAll() async {
    final st = SettingsScope.read(context);
    final x = X(st.lang);
    final ok = await confirmDialog(
      context,
      title: x.t('ap_reset_all'),
      message: x.t('ap_reset_confirm'),
      okLabel: x.t('ap_reset_ok'),
      cancelLabel: x.t('pk_cancel'),
      danger: true,
    );
    if (!ok) return;
    if (widget.shop) {
      widget.onChange(const AppLook());
    } else {
      await st.resetLook();
    }
  }

  Widget _preset(LookPreset p, bool sel, String name) {
    final onS = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () =>
          widget.onChange(look.copyWith(preset: p.id, colors: const {})),
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.primary, p.secondary],
                ),
                border: Border.all(
                    color: sel ? onS : Colors.transparent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: sel
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(_CR r, AppLook look, LookExt l, X x) {
    final key = r.perMode ? '${r.key}${l.dark ? '_d' : '_l'}' : r.key;
    final overridden = look.colors.containsKey(key);
    final title = x.t(r.labelKey);
    return InkWell(
      onTap: () => _editColor(r, key, title),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: r.color,
                shape: BoxShape.circle,
                border: Border.all(color: muted(context).withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (overridden)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.restart_alt_rounded, color: muted(context)),
                onPressed: () => widget.onChange(look.withColor(key, null)),
              ),
            Icon(chevron(context), color: muted(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = S(st.lang);
    final x = X(st.lang);
    final bt = BT(st.lang);
    final shop = widget.shop;
    final l = lk(context);
    final scheme = Theme.of(context).colorScheme;
    final rows = <_CR>[
      _CR('primary', false, 'c_primary', l.primary),
      _CR('secondary', false, 'c_secondary', l.secondary),
      _CR('accent', false, 'c_accent', l.accent),
      _CR('danger', false, 'c_danger', l.danger),
      _CR('bg1', true, 'c_bg1', l.bg[0]),
      _CR('bg2', true, 'c_bg2', l.bg[1]),
      _CR('bg3', true, 'c_bg3', l.bg[2]),
      _CR('card', true, 'c_card', l.cardBase, alpha: true),
      _CR('text', true, 'c_text', l.text ?? scheme.onSurface),
    ];
    final bgLabels = <String, String>{
      'blobs': x.t('bg_blobs'),
      'gradient': x.t('bg_gradient'),
      'waves': x.t('bg_waves'),
      'dots': x.t('bg_dots'),
      'stripes': x.t('bg_stripes'),
      'solid': x.t('bg_solid'),
      'image': x.t('bg_image'),
    };
    final modes = [
      for (final m in kBgModes)
        if (!(shop && m == 'image')) m
    ];
    return GlassScaffold(
      title: widget.title ?? x.t('ap_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // ----- نمونه -----
          SectionLabel(x.t('ap_sample')),
          Glass(
            child: Column(
              children: [
                Row(
                  children: [
                    const AppLogo(size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(x.t('ap_sample_title'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(x.t('ap_sample_sub'),
                              style: TextStyle(
                                  color: muted(context), fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Pill(x.t('ap_sample_pill'), color: l.accent),
                  ],
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: x.t('ap_sample_btn'),
                  icon: Icons.check_rounded,
                  compact: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // ----- پوسته (تیره/روشن) -----
          SectionLabel(shop ? bt.t('th_mode') : s.t('theme')),
          Glass(
            child: shop
                ? SegmentPicker<String>(
                    options: [
                      MapEntry('light', s.t('theme_light')),
                      MapEntry('dark', s.t('theme_dark')),
                    ],
                    value: widget.previewDark ? 'dark' : 'light',
                    onChanged: (v) => widget.onPreviewDark(v == 'dark'),
                  )
                : SegmentPicker<String>(
                    options: [
                      MapEntry('system', s.t('theme_system')),
                      MapEntry('light', s.t('theme_light')),
                      MapEntry('dark', s.t('theme_dark')),
                    ],
                    value: st.themeKey,
                    onChanged: st.setThemeKey,
                  ),
          ),
          // ----- طرح‌های آماده -----
          SectionLabel(x.t('ap_presets')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8,
                    runSpacing: 14,
                    children: [
                      for (final p in kPresets)
                        _preset(p, look.preset == p.id, x.t('p_${p.id}')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(x.t('ap_presets_hint'),
                    style: TextStyle(color: muted(context), fontSize: 12)),
              ],
            ),
          ),
          // ----- پس‌زمینه -----
          SectionLabel(x.t('ap_background')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in modes)
                      _Opt(
                        label: bgLabels[m] ?? m,
                        selected: look.bgMode == m,
                        icon: m == 'image' ? Icons.image_rounded : null,
                        onTap: () => _setMode(m),
                      ),
                  ],
                ),
                if (!shop && look.bgMode == 'image' && look.hasImage) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          label: x.t('ap_change_image'),
                          icon: Icons.photo_library_rounded,
                          compact: true,
                          loading: _busy,
                          onPressed: _pickImage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(
                          label: x.t('ap_remove_image'),
                          icon: Icons.delete_outline_rounded,
                          compact: true,
                          outlined: true,
                          onPressed: () => st.clearBackgroundImage(),
                        ),
                      ),
                    ],
                  ),
                  _SliderRow(
                    label: x.t('ap_blur'),
                    value: look.bgBlur,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    fmt: (v) => v.round().toString(),
                    onEnd: (v) => widget.onChange(look.copyWith(bgBlur: v)),
                  ),
                  _SliderRow(
                    label: x.t('ap_dim'),
                    value: look.bgDim,
                    min: 0,
                    max: 0.8,
                    divisions: 16,
                    fmt: (v) => '${(v * 100).round()}%',
                    onEnd: (v) => widget.onChange(look.copyWith(bgDim: v)),
                  ),
                ],
              ],
            ),
          ),
          // ----- رنگ‌ها -----
          SectionLabel(x.t('ap_colors')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                        l.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 18,
                        color: l.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        x.t(l.dark ? 'ap_editing_dark' : 'ap_editing_light'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(x.t('ap_editing_hint'),
                    style: TextStyle(
                        color: muted(context), fontSize: 12, height: 1.6)),
                const SizedBox(height: 8),
                for (final r in rows) _colorRow(r, look, l, x),
                const SizedBox(height: 10),
                GradientButton(
                  label: x.t('ap_reset_colors'),
                  icon: Icons.restart_alt_rounded,
                  outlined: true,
                  compact: true,
                  onPressed: look.colors.isEmpty
                      ? null
                      : () => widget.onChange(look.copyWith(colors: const {})),
                ),
              ],
            ),
          ),
          // ----- فونت -----
          SectionLabel(x.t('ap_font')),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in ['', ...kFontFamilies])
                      _Opt(
                        label: f.isEmpty ? x.t('f_system') : f,
                        selected: look.font == f,
                        onTap: () => widget.onChange(look.copyWith(font: f)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(x.t('ap_font_hint'),
                    style: TextStyle(
                        color: muted(context), fontSize: 12, height: 1.6)),
                _SliderRow(
                  label: x.t('ap_font_size'),
                  value: look.fontScale,
                  min: 0.85,
                  max: 1.3,
                  divisions: 9,
                  fmt: (v) => '${(v * 100).round()}%',
                  onEnd: (v) => widget.onChange(look.copyWith(fontScale: v)),
                ),
              ],
            ),
          ),
          // ----- شیشه و گوشه‌ها -----
          SectionLabel(x.t('ap_glass')),
          Glass(
            child: Column(
              children: [
                _SliderRow(
                  label: x.t('ap_glass_blur'),
                  value: look.glassBlur,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  fmt: (v) => v.round().toString(),
                  onEnd: (v) => widget.onChange(look.copyWith(glassBlur: v)),
                ),
                _SliderRow(
                  label: x.t('ap_glass_opacity'),
                  value: look.glassOpacity,
                  min: 0.3,
                  max: 1.6,
                  divisions: 13,
                  fmt: (v) => '${(v * 100).round()}%',
                  onEnd: (v) =>
                      widget.onChange(look.copyWith(glassOpacity: v)),
                ),
                _SliderRow(
                  label: x.t('ap_radius'),
                  value: look.radius,
                  min: 8,
                  max: 34,
                  divisions: 26,
                  fmt: (v) => v.round().toString(),
                  onEnd: (v) => widget.onChange(look.copyWith(radius: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (shop) ...[
            GradientButton(
              icon: Icons.check_rounded,
              label: bt.t('th_save'),
              loading: widget.saving,
              onPressed: widget.onSaveTap,
            ),
            const SizedBox(height: 12),
          ],
          GradientButton(
            danger: true,
            icon: Icons.restart_alt_rounded,
            label: x.t('ap_reset_all'),
            onPressed: _resetAll,
          ),
        ],
      ),
    );
  }
}

class _Opt extends StatelessWidget {
  const _Opt({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l = lk(context);
    final fg = selected ? l.onPrimary : null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? l.gradient : null,
          color: selected
              ? null
              : (l.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onEnd,
    required this.fmt,
    this.divisions,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double) fmt;
  final ValueChanged<double> onEnd;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  double? _drag;

  @override
  void didUpdateWidget(covariant _SliderRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    final v = (_drag ?? widget.value).clamp(widget.min, widget.max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(widget.fmt(v),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: muted(context))),
            ],
          ),
          Slider(
            value: v,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (d) => setState(() => _drag = d),
            onChangeEnd: widget.onEnd,
          ),
        ],
      ),
    );
  }
}

// ======================= انتخابگر رنگ =======================
class _PickResult {
  const _PickResult(this.color, {this.reset = false});
  final Color color;
  final bool reset;
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.x,
    required this.initial,
    required this.title,
    required this.withAlpha,
  });
  final X x;
  final Color initial;
  final String title;
  final bool withAlpha;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late HSVColor _hsv;
  late final TextEditingController _hex;

  static const _swatches = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFF7C4DFF),
    Color(0xFF00B0FF),
    Color(0xFFFF4D8D),
    Color(0xFF2ECC71),
    Color(0xFFFFB84D),
    Color(0xFFFF5252),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF0091EA),
    Color(0xFF00BFA5),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFF6B35),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF0B1020),
    Color(0xFFEEF1FF),
  ];

  @override
  void initState() {
    super.initState();
    var c = widget.initial;
    if (!widget.withAlpha) c = c.withAlpha(255);
    _hsv = HSVColor.fromColor(c);
    _hex = TextEditingController(text: _hexOf(c));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  String _hexOf(Color c) {
    final h = c.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return widget.withAlpha ? h : h.substring(2);
  }

  void _set(HSVColor h) {
    setState(() => _hsv = h);
    _hex.text = _hexOf(h.toColor());
  }

  void _onHex(String v) {
    var t = v.replaceAll('#', '').trim();
    if (t.length == 6) t = 'FF$t';
    if (t.length != 8) return;
    final n = int.tryParse(t, radix: 16);
    if (n == null) return;
    var c = Color(n);
    if (!widget.withAlpha) c = c.withAlpha(255);
    setState(() => _hsv = HSVColor.fromColor(c));
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(t, style: TextStyle(color: muted(context), fontSize: 12.5)),
      );

  @override
  Widget build(BuildContext context) {
    final x = widget.x;
    final dark = isDark(context);
    final bg = dark ? const Color(0xFF1B2038) : Colors.white;
    final h = _hsv.hue;
    final color = _hsv.toColor();
    final opaque = _hsv.withAlpha(1).toColor();
    final hueColors = [
      for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor()
    ];
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: muted(context).withOpacity(0.4)),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _swatches)
                    GestureDetector(
                      onTap: () => _set(HSVColor.fromColor(
                          widget.withAlpha ? c : c.withAlpha(255))),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: muted(context).withOpacity(0.5)),
                        ),
                      ),
                    ),
                ],
              ),
              _label(x.t('pk_hue')),
              _GradSlider(
                value: h,
                max: 360,
                colors: hueColors,
                onChanged: (v) => _set(_hsv.withHue(v)),
              ),
              _label(x.t('pk_sat')),
              _GradSlider(
                value: _hsv.saturation,
                max: 1,
                colors: [
                  HSVColor.fromAHSV(1, h, 0, _hsv.value).toColor(),
                  HSVColor.fromAHSV(1, h, 1, _hsv.value).toColor(),
                ],
                onChanged: (v) => _set(_hsv.withSaturation(v)),
              ),
              _label(x.t('pk_val')),
              _GradSlider(
                value: _hsv.value,
                max: 1,
                colors: [
                  Colors.black,
                  HSVColor.fromAHSV(1, h, _hsv.saturation, 1).toColor(),
                ],
                onChanged: (v) => _set(_hsv.withValue(v)),
              ),
              if (widget.withAlpha) ...[
                _label(x.t('pk_alpha')),
                _GradSlider(
                  value: _hsv.alpha,
                  max: 1,
                  colors: [opaque.withAlpha(0), opaque],
                  onChanged: (v) => _set(_hsv.withAlpha(v)),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _hex,
                textDirection: TextDirection.ltr,
                onChanged: _onHex,
                decoration: InputDecoration(
                  labelText: x.t('pk_hex'),
                  prefixText: '#',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: x.t('pk_apply'),
                      icon: Icons.check_rounded,
                      compact: true,
                      onPressed: () =>
                          Navigator.pop(context, _PickResult(_hsv.toColor())),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GradientButton(
                      label: x.t('pk_default'),
                      outlined: true,
                      compact: true,
                      onPressed: () => Navigator.pop(context,
                          const _PickResult(Colors.transparent, reset: true)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GradientButton(
                      label: x.t('pk_cancel'),
                      outlined: true,
                      compact: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اسلایدر با نوار رنگی (همیشه چپ‌به‌راست تا گرادیان با دستگیره هم‌جهت بماند)
class _GradSlider extends StatelessWidget {
  const _GradSlider({
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
  });
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(colors: colors),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 14,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 11, elevation: 3),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value.clamp(0.0, max).toDouble(),
                min: 0,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
