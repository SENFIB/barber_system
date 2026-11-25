import 'package:flutter/material.dart';
import '../../app/cal_names.dart';
import '../../app/extra_http.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';
import 'closure_picker.dart';
import 'suggested_services.dart';

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'نوبت‌دهی و تعطیلی',
    'range_h': 'مشتری تا چه زمانی می‌تواند نوبت بگیرد؟',
    'week': 'تا آخر هفته',
    'd3': '۳ روز آینده',
    'd7': '۷ روز آینده',
    'month': 'تا آخر ماه',
    'd30': '۳۰ روز آینده',
    'custom': 'عدد دلخواه',
    'days_label': 'تعداد روز (۱ تا ۳۰)',
    'range_note':
        'هفته مطابق تقویم آرایشگاه است. روز تعطیل جزو نوبت‌گیری حساب نمی‌شود.',
    'off_h': 'روز تعطیل هفتگی آرایشگاه',
    'off_none': 'ندارد',
    'off_note': 'برای همه‌ی آرایشگرها اعمال می‌شود. هر آرایشگر روز تعطیل خودش را هم دارد.',
    'gender_h': 'آرایشگاه برای چه کسانی است؟',
    'men': 'مردانه',
    'women': 'زنانه',
    'both': 'هر دو',
    'save': 'ذخیره',
    'saved': 'ذخیره شد ✅',
    'closures_h': 'تعطیلی‌های برنامه‌ریزی‌شده',
    'closures_empty': 'تعطیلی‌ای ثبت نشده',
    'add_closure': 'افزودن تعطیلی',
    'services_h': 'خدمات',
    'suggested': 'افزودن خدمات پیشنهادی',
    'conflicts': '{n} رزرو در این بازه از قبل هست؛ خودکار لغو نمی‌شوند.',
    'del_confirm': 'این تعطیلی حذف شود؟',
    'yes': 'بله',
    'no': 'خیر',
    'not_updated': 'سرویس هنوز به‌روز نشده است',
    'retry': 'تلاش دوباره',
    'to': 'تا',
  },
  'en': {
    'title': 'Booking & closures',
    'range_h': 'How far ahead can customers book?',
    'week': 'Until end of week',
    'd3': 'Next 3 days',
    'd7': 'Next 7 days',
    'month': 'Until end of month',
    'd30': 'Next 30 days',
    'custom': 'Custom number',
    'days_label': 'Number of days (1 to 30)',
    'range_note':
        'The week follows the shop calendar. The closed day is not counted for booking.',
    'off_h': 'Weekly closed day of the shop',
    'off_none': 'None',
    'off_note': 'Applies to all barbers. Each barber also keeps their own day off.',
    'gender_h': 'Who is the shop for?',
    'men': 'Men',
    'women': 'Women',
    'both': 'Both',
    'save': 'Save',
    'saved': 'Saved ✅',
    'closures_h': 'Planned closures',
    'closures_empty': 'No closures yet',
    'add_closure': 'Add closure',
    'services_h': 'Services',
    'suggested': 'Add suggested services',
    'conflicts': '{n} bookings already exist in this period; they are not cancelled automatically.',
    'del_confirm': 'Delete this closure?',
    'yes': 'Yes',
    'no': 'No',
    'not_updated': 'The service is not updated yet',
    'retry': 'Try again',
    'to': 'to',
  },
  'ar': {
    'title': 'الحجز والإغلاق',
    'range_h': 'إلى متى يستطيع الزبون الحجز؟',
    'week': 'حتى نهاية الأسبوع',
    'd3': '٣ أيام قادمة',
    'd7': '٧ أيام قادمة',
    'month': 'حتى نهاية الشهر',
    'd30': '٣٠ يومًا قادمة',
    'custom': 'رقم مخصص',
    'days_label': 'عدد الأيام (من ١ إلى ٣٠)',
    'range_note': 'الأسبوع حسب تقويم الصالون. يوم العطلة لا يُحتسب في الحجز.',
    'off_h': 'يوم العطلة الأسبوعي للصالون',
    'off_none': 'لا يوجد',
    'off_note': 'يسري على كل الحلاقين. ولكل حلاق عطلته الخاصة أيضًا.',
    'gender_h': 'لمن هذا الصالون؟',
    'men': 'رجالي',
    'women': 'نسائي',
    'both': 'كلاهما',
    'save': 'حفظ',
    'saved': 'تم الحفظ ✅',
    'closures_h': 'فترات الإغلاق المخططة',
    'closures_empty': 'لا توجد فترات إغلاق',
    'add_closure': 'إضافة إغلاق',
    'services_h': 'الخدمات',
    'suggested': 'إضافة خدمات مقترحة',
    'conflicts': 'يوجد {n} حجز في هذه الفترة ولن تُلغى تلقائيًا.',
    'del_confirm': 'حذف هذا الإغلاق؟',
    'yes': 'نعم',
    'no': 'لا',
    'not_updated': 'الخدمة لم تُحدَّث بعد',
    'retry': 'حاول مجددًا',
    'to': 'إلى',
  },
};

const Map<String, List<String>> _wdFull = {
  // index 0 = Sunday
  'fa': ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'],
  'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'ar': ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
};

class _Block {
  final String id;
  final String from;
  final String to;
  final String reason;
  _Block(this.id, this.from, this.to, this.reason);
}

class BookingRulesPage extends StatefulWidget {
  const BookingRulesPage({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<BookingRulesPage> createState() => _BookingRulesPageState();
}

class _BookingRulesPageState extends State<BookingRulesPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _gender = 'both';
  String _cal = 'jalali';
  String _preset = 'd30';
  int _weeklyOff = -1;
  final _daysC = TextEditingController(text: '10');
  List<_Block> _blocks = <_Block>[];
  final Map<String, String> _lab = {};

  AppSettings get _st => widget.settings;
  String get _lang => _st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _daysC.dispose();
    super.dispose();
  }

  void _applyLoaded(String mode, int n) {
    if (mode == 'week') {
      _preset = 'week';
    } else if (mode == 'month') {
      _preset = 'month';
    } else if (mode == 'days') {
      if (n == 3) {
        _preset = 'd3';
      } else if (n == 7) {
        _preset = 'd7';
      } else if (n == 30) {
        _preset = 'd30';
      } else {
        _preset = 'custom';
        _daysC.text = '$n';
      }
    } else {
      _preset = 'd30';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await extraManager(_st, 'me');
      final shop = me['shop'];
      if (shop is Map) {
        final Map sh = shop;
        final g = '${sh['gender'] ?? ''}';
        _gender = (g == 'men' || g == 'women') ? g : 'both';
        final c = '${sh['calendar'] ?? ''}';
        _cal = (c == 'gregorian' || c == 'hijri') ? c : 'jalali';
        final n = int.tryParse('${sh['book_days'] ?? ''}') ?? 30;
        _applyLoaded('${sh['book_mode'] ?? ''}', n);
        final wo = int.tryParse('${sh['weekly_off'] ?? ''}');
        _weeklyOff = (wo != null && wo >= 0 && wo <= 6) ? wo : -1;
      }
      await _loadBlocks();
    } on ExtraError catch (e) {
      _error = extraErrorText(e, _lang);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _todayIso() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBlocks() async {
    final r = await extraManager(_st, 'timeoff_list');
    final list = r['blocks'];
    final today = _todayIso();
    final out = <_Block>[];
    if (list is List) {
      for (final b in list) {
        if (b is! Map) continue;
        if ('${b['staff_id'] ?? ''}'.isNotEmpty) continue;
        if ('${b['start_time'] ?? ''}'.isNotEmpty) continue;
        final to = '${b['date_to'] ?? ''}';
        if (to.compareTo(today) < 0) continue;
        out.add(_Block('${b['block_id']}', '${b['date_from']}', to, '${b['reason'] ?? ''}'));
      }
    }
    out.sort((a, b) => a.from.compareTo(b.from));
    _blocks = out;
    // برچسب تاریخ‌ها به تقویم آرایشگاه (اگر نشد، همان تاریخ میلادی)
    _lab.clear();
    if (_cal != 'gregorian' && out.isNotEmpty) {
      try {
        final dates = <String>[];
        for (final b in out) {
          if (!dates.contains(b.from)) dates.add(b.from);
          if (!dates.contains(b.to)) dates.add(b.to);
        }
        final p = await extraPublic(_st.apiUrl, 'cal_parts', {'calendar': _cal, 'dates': dates});
        final parts = p['parts'];
        if (parts is List) {
          for (var i = 0; i < dates.length && i < parts.length; i++) {
            final x = parts[i];
            if (x is Map) {
              final y = (x['y'] as num).toInt();
              final m = (x['m'] as num).toInt();
              final d = (x['d'] as num).toInt();
              _lab[dates[i]] =
                  '${localDigits(d, _lang)} ${calMonthName(_cal, m, _lang)} ${localDigits(y, _lang)}';
            }
          }
        }
      } catch (_) {}
    }
  }

  String _labelOf(String iso) => _lab[iso] ?? iso;

  Future<void> _save() async {
    if (_busy) return;
    var mode = 'days';
    var days = 30;
    switch (_preset) {
      case 'week':
        mode = 'week';
        days = 7;
        break;
      case 'month':
        mode = 'month';
        days = 30;
        break;
      case 'd3':
        days = 3;
        break;
      case 'd7':
        days = 7;
        break;
      case 'custom':
        days = int.tryParse(latinOf(_daysC.text.trim())) ?? 0;
        if (days < 1 || days > 30) {
          toast(context, extraErrorText(ExtraError('BAD_NUMBER', ''), _lang));
          return;
        }
        break;
      default:
        days = 30;
    }
    setState(() => _busy = true);
    try {
      final r = await extraManager(_st, 'shop_update', {
        'gender': _gender,
        'book_mode': mode,
        'book_days': days,
        'weekly_off': _weeklyOff < 0 ? '' : _weeklyOff,
      });
      final shop = r['shop'];
      if (!mounted) return;
      if (shop is Map && shop.containsKey('gender')) {
        toast(context, _t('saved'));
      } else {
        toast(context, _t('not_updated'));
      }
    } on ExtraError catch (e) {
      if (mounted) toast(context, extraErrorText(e, _lang));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addClosure() async {
    if (_busy) return;
    final res = await Navigator.of(context).push<ClosureResult>(
      MaterialPageRoute<ClosureResult>(
        builder: (_) => ClosurePickerPage(settings: _st, calendar: _cal),
      ),
    );
    if (res == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await extraManager(_st, 'timeoff_add', {
        'date_from': res.from,
        'date_to': res.to,
        'reason': res.reason,
      });
      await _loadBlocks();
      if (!mounted) return;
      final c = r['conflicts'];
      if (c is num && c > 0) {
        toast(context, _t('conflicts').replaceAll('{n}', localDigits(c.toInt(), _lang)));
      } else {
        toast(context, _t('saved'));
      }
    } on ExtraError catch (e) {
      if (mounted) toast(context, extraErrorText(e, _lang));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _removeBlock(_Block b) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(_t('del_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('no'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('yes'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await extraManager(_st, 'timeoff_remove', {'block_id': b.id});
      await _loadBlocks();
    } on ExtraError catch (e) {
      if (mounted) toast(context, extraErrorText(e, _lang));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openSuggested() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SuggestedServicesPage(settings: _st, gender: _gender),
      ),
    );
  }

  Widget _head(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _busy ? null : (_) => onTap(),
    );
  }

  Widget _card(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          GradientButton(label: _t('retry'), icon: Icons.refresh_rounded, onPressed: _load),
        ],
      );
    } else {
      final presets = <String>['week', 'd3', 'd7'];
      if (_cal != 'hijri' || _preset == 'month') presets.add('month');
      presets.addAll(['d30', 'custom']);
      final names = _wdFull[_lang] ?? _wdFull['fa']!;
      final order = _cal == 'gregorian'
          ? <int>[1, 2, 3, 4, 5, 6, 0]
          : <int>[6, 0, 1, 2, 3, 4, 5];
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _card([
            _head(_t('range_h')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in presets)
                  _chip(_t(p), _preset == p, () => setState(() => _preset = p)),
              ],
            ),
            if (_preset == 'custom') ...[
              const SizedBox(height: 12),
              GlassField(
                controller: _daysC,
                label: _t('days_label'),
                icon: Icons.event_rounded,
                ltr: true,
                keyboard: TextInputType.number,
              ),
            ],
            const SizedBox(height: 10),
            Text(_t('range_note'), style: TextStyle(color: muted(context), fontSize: 12)),
          ]),
          _card([
            _head(_t('off_h')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(_t('off_none'), _weeklyOff < 0, () => setState(() => _weeklyOff = -1)),
                for (final d in order)
                  _chip(names[d], _weeklyOff == d, () => setState(() => _weeklyOff = d)),
              ],
            ),
            const SizedBox(height: 10),
            Text(_t('off_note'), style: TextStyle(color: muted(context), fontSize: 12)),
          ]),
          _card([
            _head(_t('gender_h')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in const ['men', 'women', 'both'])
                  _chip(_t(g), _gender == g, () => setState(() => _gender = g)),
              ],
            ),
          ]),
          GradientButton(
            label: _t('save'),
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _save,
          ),
          const SizedBox(height: 20),
          _card([
            _head(_t('closures_h')),
            if (_blocks.isEmpty)
              Text(_t('closures_empty'), style: TextStyle(color: muted(context))),
            for (final b in _blocks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(b.from == b.to
                    ? _labelOf(b.from)
                    : '${_labelOf(b.from)} ${_t('to')} ${_labelOf(b.to)}'),
                subtitle: b.reason.isEmpty ? null : Text(b.reason),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _removeBlock(b),
                ),
              ),
            const SizedBox(height: 10),
            GradientButton(
              label: _t('add_closure'),
              icon: Icons.event_busy_rounded,
              outlined: true,
              onPressed: _addClosure,
            ),
          ]),
          _card([
            _head(_t('services_h')),
            GradientButton(
              label: _t('suggested'),
              icon: Icons.auto_awesome_rounded,
              outlined: true,
              onPressed: _openSuggested,
            ),
          ]),
        ],
      );
    }
    return GlassScaffold(title: _t('title'), body: body);
  }
}
