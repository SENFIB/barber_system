import 'dart:convert';
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

String _latin(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final c in s.runes) {
    final ch = String.fromCharCode(c);
    var i = fa.indexOf(ch);
    if (i < 0) i = ar.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return b.toString();
}

const int _kMaxMsgs = 5;
const int _kMaxDays = 365;

/// ارسال پیام اختصاصی آرایشگاه در بازه‌های مشخص (فقط پلن ویژه).
/// تا ۵ متن + یک بازهٔ مشترک. برای هر مشتری یکی از متن‌ها تصادفی انتخاب می‌شود.
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
  final TextEditingController _days = TextEditingController(text: '30');
  final List<TextEditingController> _msgs = <TextEditingController>[];

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

  @override
  void dispose() {
    _days.dispose();
    for (final c in _msgs) {
      c.dispose();
    }
    super.dispose();
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  void _fill(List<String> texts) {
    for (final c in _msgs) {
      c.dispose();
    }
    _msgs.clear();
    for (final t in texts.take(_kMaxMsgs)) {
      _msgs.add(TextEditingController(text: t));
    }
    if (_msgs.isEmpty) _msgs.add(TextEditingController());
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
      if (!mounted) return;
      final rules = bFirstList(r, ['rules', 'items', 'winback', 'list'])
          .where((e) => !_isOff(e['active']))
          .toList();
      setState(() {
        final texts = <String>[];
        var d = 30;
        for (final e in rules) {
          final m = bStr(e['message']).trim();
          if (m.isNotEmpty) texts.add(m);
          final x = bInt(e['days_after'], 0);
          if (x >= 1 && texts.length == 1) d = x;
        }
        _days.text = '$d';
        _fill(texts);
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

  Future<void> _save() async {
    if (_busy) return;
    final l = _lang;
    final d = int.tryParse(_latin(_days.text.trim()));
    if (d == null || d < 1 || d > _kMaxDays) {
      toast(
          context,
          _x(
              l,
              'تعداد روز باید بین ۱ تا ۳۶۵ باشد',
              'Days must be between 1 and 365',
              'يجب أن يكون عدد الأيام بين 1 و365'));
      return;
    }
    final list = <String>[
      for (final c in _msgs)
        if (c.text.trim().isNotEmpty) c.text.trim()
    ];
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call(
        'winback_set',
        <String, dynamic>{
          'days_after': d,
          'messages': jsonEncode(list),
        },
      );
      if (!mounted) return;
      toast(context, _x(l, 'ذخیره شد', 'Saved', 'تم الحفظ'));
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      toast(context, T6(l).error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addMsg() {
    if (_msgs.length >= _kMaxMsgs) return;
    setState(() => _msgs.add(TextEditingController()));
  }

  void _removeMsg(int i) {
    setState(() {
      final c = _msgs.removeAt(i);
      c.dispose();
      if (_msgs.isEmpty) _msgs.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = SettingsScope.of(context).lang;
    final title = _x(l, 'پیام اختصاصی آرایشگاه', 'Custom shop messages',
        'رسائل خاصة بالصالون');
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
      final cur = int.tryParse(_latin(_days.text.trim()));
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Glass(
            child: Text(
              _x(
                  l,
                  'تا ۵ متن بنویسید و یک بازهٔ زمانی انتخاب کنید. بعد از هر نوبتِ مشتری، پس از همان تعداد روز، یکی از متن‌ها روی دستگاهِ خودش نمایش داده می‌شود. اگر فقط یک متن بنویسید همان می‌رود و اگر چند متن باشد، یکی‌شان به‌صورت تصادفی انتخاب می‌شود. این پیام فقط برای مشتری‌هایی است که از طریق برنامه نوبت گرفته‌اند.',
                  'Write up to 5 messages and choose one time interval. After each customer’s booking, once that many days have passed, one of the messages appears on their own device. With one message that one is sent; with several, one is picked at random. It only reaches customers who booked through the app.',
                  'اكتب حتى 5 رسائل واختر فترة زمنية واحدة. بعد كل حجز للزبون، وبعد مرور هذا العدد من الأيام، تظهر إحدى الرسائل على جهازه. إذا كتبت رسالة واحدة تُرسل هي، وإذا كانت عدة رسائل يُختار واحدة منها عشوائيًا. تصل فقط للزبائن الذين حجزوا عبر التطبيق.'),
              style:
                  TextStyle(color: muted(context), fontSize: 13, height: 1.7),
            ),
          ),
          const SizedBox(height: 14),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _x(l, 'چند روز بعد از نوبت پیام برود؟',
                      'Send how many days after the booking?',
                      'بعد كم يوم من الحجز تُرسل الرسالة؟'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _x(l, 'تعداد روز (۱ تا ۳۶۵)',
                        'Number of days (1–365)', 'عدد الأيام (1–365)'),
                    counterText: '',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in const [7, 15, 25, 30, 45, 60, 90])
                      ChoiceChip(
                        label: Text(fmtNum(d, l)),
                        selected: cur == d,
                        onSelected: (_) => setState(() => _days.text = '$d'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _x(l, 'متن‌ها', 'Messages', 'الرسائل'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                '${fmtNum(_msgs.length, l)} / ${fmtNum(_kMaxMsgs, l)}',
                style: TextStyle(color: muted(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _msgs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Glass(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgs[i],
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText:
                              '${_x(l, 'متن', 'Message', 'الرسالة')} ${fmtNum(i + 1, l)}',
                          hintText: _x(
                              l,
                              'مثلاً: دلمون برات تنگ شده، یه سر بهمون بزن',
                              'e.g. We miss you, come visit us soon',
                              'مثال: اشتقنا لك، زرنا قريبًا'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _x(l, 'حذف', 'Delete', 'حذف'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _removeMsg(i),
                    ),
                  ],
                ),
              ),
            ),
          if (_msgs.length < _kMaxMsgs)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GradientButton(
                outlined: true,
                compact: true,
                icon: Icons.add_rounded,
                label: _x(l, 'افزودن متن', 'Add message', 'إضافة رسالة'),
                onPressed: _addMsg,
              ),
            )
          else
            Text(
              _x(l, 'به سقف ۵ متن رسیده‌اید.', 'You reached the limit of 5.',
                  'وصلت إلى الحد الأقصى (5).'),
              style: TextStyle(color: muted(context), fontSize: 12.5),
            ),
          const SizedBox(height: 18),
          GradientButton(
            icon: Icons.check_rounded,
            label: _x(l, 'ذخیره', 'Save', 'حفظ'),
            loading: _busy,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          Text(
            _x(
                l,
                'اگر همهٔ متن‌ها را خالی بگذارید و ذخیره کنید، ارسال پیام غیرفعال می‌شود.',
                'If you leave all messages empty and save, sending is turned off.',
                'إذا تركت كل الرسائل فارغة وحفظت، يتوقف الإرسال.'),
            style: TextStyle(color: muted(context), fontSize: 12.5),
          ),
        ],
      );
    }
    return GlassScaffold(title: title, maxWidth: 720, body: body);
  }
}
