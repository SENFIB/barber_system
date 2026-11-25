import 'package:flutter/material.dart';
import '../../app/cal_names.dart';
import '../../app/extra_http.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';

class ClosureResult {
  final String from;
  final String to;
  final String reason;
  ClosureResult(this.from, this.to, this.reason);
}

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'انتخاب بازه‌ی تعطیلی',
    'hint': 'روز شروع و روز پایان را بزن. برای یک روز، همان روز را دوباره بزن.',
    'from': 'از',
    'to': 'تا',
    'reason': 'دلیل (اختیاری)',
    'ok': 'تأیید',
    'pick': 'یک روز انتخاب کن',
    'fallback': 'تقویم انتخابی در دسترس نیست؛ میلادی نشان داده می‌شود',
  },
  'en': {
    'title': 'Choose closure dates',
    'hint': 'Tap the first and the last day. For a single day tap it twice.',
    'from': 'From',
    'to': 'to',
    'reason': 'Reason (optional)',
    'ok': 'Confirm',
    'pick': 'Pick a day',
    'fallback': 'The selected calendar is not available; showing Gregorian',
  },
  'ar': {
    'title': 'اختيار فترة الإغلاق',
    'hint': 'اضغط أول يوم وآخر يوم. ليوم واحد اضغطه مرتين.',
    'from': 'من',
    'to': 'إلى',
    'reason': 'السبب (اختياري)',
    'ok': 'تأكيد',
    'pick': 'اختر يومًا',
    'fallback': 'التقويم المختار غير متاح؛ يُعرض الميلادي',
  },
};

const Map<String, List<String>> _wdNames = {
  // index 0 = Sunday
  'fa': ['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'],
  'en': ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  'ar': ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
};

class ClosurePickerPage extends StatefulWidget {
  const ClosurePickerPage({super.key, required this.settings, required this.calendar});
  final AppSettings settings;
  final String calendar;

  @override
  State<ClosurePickerPage> createState() => _ClosurePickerPageState();
}

class _ClosurePickerPageState extends State<ClosurePickerPage> {
  late String _cal;
  int _off = 0;
  bool _loading = true;
  int _y = 0;
  int _m = 1;
  List<String> _days = <String>[];
  String _today = '';
  String? _a;
  String? _b;
  String _aLabel = '';
  String _bLabel = '';
  bool _fallback = false;
  final _reason = TextEditingController();

  AppSettings get _st => widget.settings;
  String get _lang => _st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _cal = widget.calendar;
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _iso(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  void _loadLocal() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month + _off, 1);
    final n = DateTime(base.year, base.month + 1, 0).day;
    _y = base.year;
    _m = base.month;
    _days = [for (var i = 1; i <= n; i++) _iso(base.year, base.month, i)];
    _today = _iso(now.year, now.month, now.day);
  }

  /// true = موفق
  Future<bool> _load() async {
    setState(() => _loading = true);
    var ok = true;
    try {
      if (_cal == 'gregorian') {
        _loadLocal();
      } else {
        final d = await extraPublic(_st.apiUrl, 'cal_month', {'calendar': _cal, 'offset': _off});
        final days = d['days'];
        if (days is! List || days.isEmpty) throw ExtraError('CAL_UNAVAILABLE', '');
        _days = [for (final x in days) '$x'];
        _y = (d['year'] as num).toInt();
        _m = (d['month'] as num).toInt();
        _today = '${d['today']}';
      }
    } on ExtraError catch (e) {
      if (e.code == 'CAL_UNAVAILABLE' || e.code == 'UNKNOWN_ACTION') {
        _cal = 'gregorian';
        _fallback = true;
        _a = null;
        _b = null;
        _loadLocal();
      } else {
        ok = false;
        if (mounted) toast(context, extraErrorText(e, _lang));
      }
    } catch (_) {
      ok = false;
    }
    if (mounted) setState(() => _loading = false);
    return ok;
  }

  Future<void> _go(int delta) async {
    final old = _off;
    _off += delta;
    final ok = await _load();
    if (!ok) {
      _off = old;
      if (mounted) setState(() {});
    }
  }

  String _label(int day) =>
      '${localDigits(day, _lang)} ${calMonthName(_cal, _m, _lang)} ${localDigits(_y, _lang)}';

  void _tap(String iso, int day) {
    final label = _label(day);
    setState(() {
      if (_a == null || _b != null) {
        _a = iso;
        _aLabel = label;
        _b = null;
        _bLabel = '';
      } else if (iso.compareTo(_a!) < 0) {
        _b = _a;
        _bLabel = _aLabel;
        _a = iso;
        _aLabel = label;
      } else {
        _b = iso;
        _bLabel = label;
      }
    });
  }

  void _confirm() {
    if (_a == null) {
      toast(context, _t('pick'));
      return;
    }
    Navigator.of(context).pop(ClosureResult(_a!, _b ?? _a!, _reason.text.trim()));
  }

  Widget _cell(BuildContext context, int day, String iso) {
    final cs = Theme.of(context).colorScheme;
    final past = iso.compareTo(_today) < 0;
    final sel = iso == _a || iso == _b;
    final inRange = _a != null &&
        _b != null &&
        iso.compareTo(_a!) > 0 &&
        iso.compareTo(_b!) < 0;
    Color? bg;
    if (sel) {
      bg = cs.primary;
    } else if (inRange) {
      bg = cs.primary.withOpacity(0.2);
    }
    Color? fg;
    if (sel) {
      fg = cs.onPrimary;
    } else if (past) {
      fg = muted(context).withOpacity(0.4);
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: past ? null : () => _tap(iso, day),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(
            localDigits(day, _lang),
            style: TextStyle(color: fg, fontWeight: sel ? FontWeight.bold : null),
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    if (_days.isEmpty) return const SizedBox.shrink();
    final startJs = _cal == 'gregorian' ? 1 : 6;
    final names = _wdNames[_lang] ?? _wdNames['fa']!;
    final order = [for (var i = 0; i < 7; i++) (startJs + i) % 7];
    final head = Row(
      children: [
        for (final w in order)
          Expanded(
            child: Center(
              child: Text(names[w], style: TextStyle(color: muted(context), fontSize: 12)),
            ),
          ),
      ],
    );
    final first = DateTime.parse(_days.first);
    final blanks = ((first.weekday % 7) - startJs + 7) % 7;
    final cells = <Widget>[
      for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
      for (var i = 0; i < _days.length; i++) _cell(context, i + 1, _days[i]),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: [
          for (var j = 0; j < 7; j++)
            Expanded(child: AspectRatio(aspectRatio: 1, child: cells[i + j])),
        ],
      ));
    }
    return Column(children: [head, const SizedBox(height: 6), ...rows]);
  }

  @override
  Widget build(BuildContext context) {
    final title = _days.isEmpty
        ? ''
        : '${calMonthName(_cal, _m, _lang)} ${localDigits(_y, _lang)}';
    var summary = _t('pick');
    if (_a != null) {
      summary = '${_t('from')} $_aLabel';
      if (_b != null) summary += ' ${_t('to')} $_bLabel';
    }
    return GlassScaffold(
      title: _t('title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(_t('hint'), style: TextStyle(color: muted(context))),
          if (_fallback) ...[
            const SizedBox(height: 6),
            Text(_t('fallback'), style: const TextStyle(color: Colors.orange)),
          ],
          const SizedBox(height: 12),
          Glass(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: (_off <= 0 || _loading) ? null : () => _go(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (_off >= 24 || _loading) ? null : () => _go(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  )
                else
                  _grid(context),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(summary, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          GlassField(
            controller: _reason,
            label: _t('reason'),
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: _t('ok'),
            icon: Icons.check_rounded,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
