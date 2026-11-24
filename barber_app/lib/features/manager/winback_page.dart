import 'package:flutter/material.dart';
import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'plans_page.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

String _x(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

bool _isOff(dynamic v) {
  final s = bStr(v).toLowerCase();
  return v == false || s == 'false' || s == '0';
}

/// پیام «دلمون تنگ شده»: متن را آرایشگاه می‌نویسد، آرایشگر و زمان را انتخاب می‌کند.
class WinbackPage extends StatefulWidget {
  const WinbackPage(this.ctx, {super.key});
  final ShopCtx ctx;

  @override
  State<WinbackPage> createState() => _WinbackPageState();
}

class _WinbackPageState extends State<WinbackPage> {
  bool _loading = true;
  bool _busy = false;
  String? _err;
  List<Map<String, dynamic>> _rules = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _staff = <Map<String, dynamic>>[];

  String get _lang => SettingsScope.read(context).lang;

  bool get _ok {
    final p = widget.ctx.session.shop.plan.trim().toLowerCase();
    return p == 'special' || p == 'personal';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
    if (!_ok) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final raw = ShopRaw(SettingsScope.read(context));
      final r = await raw.call('winback_list');
      final s = await raw.call('staff_list');
      if (!mounted) return;
      setState(() {
        _rules = bFirstList(r, ['rules', 'items', 'winback', 'list'])
            .where((e) => !_isOff(e['active']))
            .toList();
        _staff = bFirstList(s, ['staff', 'items', 'list']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = T6(_lang).error(e);
      });
    }
  }

  Future<void> _call(String action, Map<String, dynamic> p) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call(action, p);
      if (!mounted) return;
      toast(context, _x(_lang, 'ذخیره شد', 'Saved', 'تم الحفظ'));
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      toast(context, T6(_lang).error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? rule]) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RuleDialog(lang: _lang, staff: _staff, rule: rule),
    );
    if (res == null || !mounted) return;
    await _call('winback_save', res);
  }

  Future<void> _remove(Map<String, dynamic> r) async {
    final l = _lang;
    final ok = await confirmDialog(
      context,
      title: _x(l, 'حذف پیام', 'Delete message', 'حذف الرسالة'),
      message: _x(l, 'این پیام حذف شود؟', 'Delete this message?',
          'هل تريد حذف هذه الرسالة؟'),
      okLabel: _x(l, 'حذف', 'Delete', 'حذف'),
      cancelLabel: _x(l, 'انصراف', 'Cancel', 'إلغاء'),
      danger: true,
    );
    if (ok != true || !mounted) return;
    await _call('winback_save', <String, dynamic>{
      'rule_id': bStr(r['rule_id']),
      'days_after': bInt(r['days_after'], 30),
      'message': bStr(r['message']),
      'staff_ids': bIds(r['staff_ids']).join(','),
      'active': false,
    });
  }

  String _names(Map<String, dynamic> r, String l) {
    final ids = bIds(r['staff_ids']);
    if (ids.isEmpty) {
      return _x(l, 'همهٔ آرایشگران', 'All barbers', 'كل الحلاقين');
    }
    final names = <String>[];
    for (final id in ids) {
      for (final s in _staff) {
        if (bStr(s['staff_id']) == id) names.add(bStr(s['name']));
      }
    }
    return names.isEmpty ? ids.join('، ') : names.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final l = SettingsScope.of(context).lang;
    final title = _x(l, 'پیام «دلمون تنگ شده»', '"We miss you" messages',
        'رسائل «اشتقنا لك»');
    Widget body;
    if (!_ok) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Glass(
            child: Column(
              children: [
                const GradientIcon(Icons.lock_rounded, size: 52),
                const SizedBox(height: 12),
                Text(
                  _x(
                      l,
                      'این قابلیت مخصوص پلن ویژه است.',
                      'This feature is only for the Special plan.',
                      'هذه الميزة مخصصة للباقة المميزة فقط.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  outlined: true,
                  compact: true,
                  icon: Icons.workspace_premium_rounded,
                  label: _x(l, 'مشاهده‌ی پلن‌ها', 'View plans', 'عرض الخطط'),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlansPage(widget.ctx))),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Glass(
            child: Column(
              children: [
                Text(_err!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GradientButton(
                  compact: true,
                  icon: Icons.refresh_rounded,
                  label: _x(l, 'تلاش دوباره', 'Retry', 'إعادة المحاولة'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Glass(
            child: Text(
              _x(
                  l,
                  'متن پیام را خودتان می‌نویسید و تعیین می‌کنید چند روز بعد از آخرین نوبتِ مشتری، پیام روی دستگاهِ خودش نمایش داده شود. فقط برای مشتری‌هایی است که از طریق برنامه نوبت گرفته‌اند. اگر مشتری دوباره نوبت بگیرد، شمارش از نو شروع می‌شود.',
                  'You write the message and choose how many days after the customer’s last booking it appears on their own device. It only reaches customers who booked through the app. If the customer books again, the countdown restarts.',
                  'تكتب الرسالة بنفسك وتحدد بعد كم يوم من آخر حجز للزبون تظهر على جهازه. تصل فقط للزبائن الذين حجزوا عبر التطبيق. إذا حجز الزبون مجددًا يبدأ العدّ من جديد.'),
              style:
                  TextStyle(color: muted(context), fontSize: 13, height: 1.7),
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            icon: Icons.add_rounded,
            label: _x(l, 'پیام جدید', 'New message', 'رسالة جديدة'),
            loading: _busy,
            onPressed: () => _edit(),
          ),
          const SizedBox(height: 14),
          if (_rules.isEmpty)
            Glass(
              child: Text(
                _x(l, 'هنوز پیامی نساخته‌اید.', 'No messages yet.',
                    'لا توجد رسائل بعد.'),
                style: TextStyle(color: muted(context)),
              ),
            ),
          for (final r in _rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _x(
                                l,
                                '${fmtNum(bInt(r['days_after']), l)} روز بعد از آخرین نوبت',
                                '${fmtNum(bInt(r['days_after']), l)} days after the last booking',
                                'بعد ${fmtNum(bInt(r['days_after']), l)} يومًا من آخر حجز'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _edit(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _remove(r),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(bStr(r['message']), style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 8),
                    Text(
                      '${_x(l, 'آرایشگر', 'Barber', 'الحلاق')}: ${_names(r, l)}',
                      style: TextStyle(color: muted(context), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return GlassScaffold(title: title, maxWidth: 720, body: body);
  }
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({required this.lang, required this.staff, this.rule});
  final String lang;
  final List<Map<String, dynamic>> staff;
  final Map<String, dynamic>? rule;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController _msg;
  late int _days;
  late Set<String> _ids;
  bool _bad = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _msg = TextEditingController(text: r == null ? '' : bStr(r['message']));
    final d = r == null ? 30 : bInt(r['days_after'], 30);
    _days = d < 1 ? 30 : d;
    _ids = r == null ? <String>{} : bIds(r['staff_ids']).toSet();
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  void _save() {
    final m = _msg.text.trim();
    if (m.isEmpty) {
      setState(() => _bad = true);
      return;
    }
    final r = widget.rule;
    Navigator.of(context).pop(<String, dynamic>{
      if (r != null) 'rule_id': bStr(r['rule_id']),
      'days_after': _days,
      'message': m,
      'staff_ids': _ids.join(','),
      'active': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    return AlertDialog(
      title: Text(widget.rule == null
          ? _x(l, 'پیام جدید', 'New message', 'رسالة جديدة')
          : _x(l, 'ویرایش پیام', 'Edit message', 'تعديل الرسالة')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _msg,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: _x(l, 'متن پیام', 'Message text', 'نص الرسالة'),
                  hintText: _x(l, 'مثلاً: دلمون برات تنگ شده، یه سر بهمون بزن',
                      'e.g. We miss you, come visit us soon',
                      'مثال: اشتقنا لك، زرنا قريبًا'),
                  errorText: _bad
                      ? _x(l, 'متن پیام را بنویسید', 'Write the message',
                          'اكتب الرسالة')
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (_) {
                  if (_bad) setState(() => _bad = false);
                },
              ),
              const SizedBox(height: 14),
              Text(
                  _x(l, 'چند روز بعد از آخرین نوبت؟',
                      'Days after the last booking?',
                      'بعد كم يوم من آخر حجز؟'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in const [7, 14, 21, 30, 45, 60, 90])
                    ChoiceChip(
                      label: Text(fmtNum(d, l)),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                  _x(l, 'برای مشتری‌های کدام آرایشگر؟', 'For which barbers’ customers?',
                      'لزبائن أي حلاق؟'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  _x(l, 'اگر هیچ‌کدام را انتخاب نکنید، برای همه است.',
                      'If you select none, it applies to all.',
                      'إن لم تختر أحدًا فهي للجميع.'),
                  style: TextStyle(color: muted(context), fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in widget.staff)
                    FilterChip(
                      label: Text(bStr(s['name'])),
                      selected: _ids.contains(bStr(s['staff_id'])),
                      onSelected: (v) => setState(() {
                        final id = bStr(s['staff_id']);
                        if (v) {
                          _ids.add(id);
                        } else {
                          _ids.remove(id);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_x(l, 'انصراف', 'Cancel', 'إلغاء')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_x(l, 'ذخیره', 'Save', 'حفظ')),
        ),
      ],
    );
  }
}
