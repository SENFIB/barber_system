import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'cal.dart';
import 'jx.dart';
import 'settings.dart';
import 'strings_pro.dart';
import 'theme.dart';
import 'widgets.dart';

bool sessionLost(ApiException e) => const {
      'UNAUTHORIZED',
      'DEVICE_MISMATCH',
      'SUBSCRIPTION_EXPIRED',
      'SHOP_DEACTIVATED',
    }.contains(e.code);

Color statusColor(String s) {
  switch (s) {
    case 'booked':
      return AppColors.blue;
    case 'checked_in':
      return AppColors.violet;
    case 'finished':
      return AppColors.green;
    case 'cancelled':
      return AppColors.red;
    default:
      return AppColors.amber;
  }
}

class Cap extends StatelessWidget {
  const Cap(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: muted(context))),
      );
}

class EmptyBox extends StatelessWidget {
  const EmptyBox(this.text, {super.key, this.icon = Icons.inbox_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: muted(context)),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted(context))),
            ],
          ),
        ),
      );
}

class ErrBox extends StatelessWidget {
  const ErrBox({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final z = Z(SettingsScope.of(context).lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Glass(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              GradientButton(
                compact: true,
                label: z.t('retry'),
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بارگذاری داده از سرور با حالت‌های «در حال بارگذاری / خطا / آماده»
class ApiLoader<T> extends StatefulWidget {
  const ApiLoader(
      {super.key, required this.load, required this.builder, this.onLost});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function()) builder;
  final VoidCallback? onLost;
  @override
  State<ApiLoader<T>> createState() => _ApiLoaderState<T>();
}

class _ApiLoaderState<T> extends State<ApiLoader<T>> {
  T? _data;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _err = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (sessionLost(e) && widget.onLost != null) {
        widget.onLost!();
        return;
      }
      final msg = Z(SettingsScope.read(context).lang).error(e);
      if (_data != null) {
        toast(context, msg);
      } else {
        setState(() {
          _err = msg;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return ErrBox(message: _err ?? '', onRetry: () {
        setState(() => _loading = true);
        _run();
      });
    }
    return widget.builder(context, _data as T, _run);
  }
}

/// بنر «نسخه‌ی جدید» (با app_version سرور)
class UpdateBanner extends StatefulWidget {
  const UpdateBanner(
      {super.key,
      required this.app,
      this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 8)});
  final String app;
  final EdgeInsets padding;
  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final st = SettingsScope.read(context);
      final info = await PackageInfo.fromPlatform();
      final d = mapOf(await ApiClient(st.apiUrl)
          .call('app_version', {'app': widget.app, 'version': info.version}));
      if (mounted && d['update_available'] == true) setState(() => _d = d);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null) return const SizedBox.shrink();
    final z = Z(SettingsScope.of(context).lang);
    final required = d['update_required'] == true;
    final url = strOf(d['url']);
    return Padding(
      padding: widget.padding,
      child: Glass(
        tint: (required ? AppColors.red : AppColors.amber).withOpacity(0.18),
        child: Row(
          children: [
            const Icon(Icons.system_update_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(z.t(required ? 'upd_required' : 'upd_available'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (url.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (mounted) toast(context, z.t('copied'));
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// دکمه‌ی تعویض تقویم
class CalButton extends StatelessWidget {
  const CalButton({super.key, required this.cal, required this.onChanged});
  final CalKind cal;
  final ValueChanged<CalKind> onChanged;
  @override
  Widget build(BuildContext context) {
    final z = Z(SettingsScope.of(context).lang);
    return PopupMenuButton<CalKind>(
      tooltip: z.t('calendar'),
      icon: const Icon(Icons.calendar_month_rounded),
      initialValue: cal,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final k in CalKind.values)
          PopupMenuItem(value: k, child: Text(z.t('cal_${k.name}'))),
      ],
    );
  }
}

Future<TimeOfDay?> pickTime24(BuildContext context, TimeOfDay initial) =>
    showTimePicker(
      context: context,
      initialTime: initial,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox(),
      ),
    );

String fmtTod(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTod(String s, TimeOfDay fallback) {
  final p = s.split(':');
  if (p.length != 2) return fallback;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  return (h == null || m == null) ? fallback : TimeOfDay(hour: h, minute: m);
}

/// انتخاب تاریخ در تقویم شمسی / میلادی / قمری. خروجی: تاریخ میلادی YYYY-MM-DD
Future<String?> pickDate(BuildContext context,
        {required String initial,
        required CalKind cal,
        required String lang,
        String? min,
        String? max}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 460),
      builder: (_) =>
          _CalSheet(initial: initial, cal: cal, lang: lang, min: min, max: max),
    );

class _CalSheet extends StatefulWidget {
  const _CalSheet(
      {required this.initial,
      required this.cal,
      required this.lang,
      this.min,
      this.max});
  final String initial, lang;
  final CalKind cal;
  final String? min, max;
  @override
  State<_CalSheet> createState() => _CalSheetState();
}

class _CalSheetState extends State<_CalSheet> {
  late int _y;
  late int _m;

  @override
  void initState() {
    super.initState();
    final v = toCal(parseIso(widget.initial), widget.cal);
    _y = v.y;
    _m = v.m;
  }

  void _step(int d) {
    setState(() {
      _m += d;
      if (_m > 12) {
        _m = 1;
        _y++;
      }
      if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  Widget _cell(BuildContext context, int d, String today) {
    final iso = isoOf(fromCal(YMD(_y, _m, d), widget.cal));
    final mn = widget.min;
    final mx = widget.max;
    final dis = (mn != null && iso.compareTo(mn) < 0) ||
        (mx != null && iso.compareTo(mx) > 0);
    final sel = iso == widget.initial;
    final isToday = iso == today;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: dis ? null : () => Navigator.pop(context, iso),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: sel ? lk(context).gradient : null,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !sel
              ? Border.all(color: lk(context).primary)
              : null,
        ),
        child: Text(
          localDigits('$d', widget.lang),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: sel
                ? Colors.white
                : (dis ? muted(context).withOpacity(0.4) : null),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.cal;
    final lang = widget.lang;
    final dim = daysInMonth(k, _y, _m);
    final first = fromCal(YMD(_y, _m, 1), k);
    final off = (first.weekday % 7 - weekStart(k) + 7) % 7;
    final today = todayIso();
    final cells = <Widget>[];
    for (var i = 0; i < off; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= dim; d++) {
      cells.add(_cell(context, d, today));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => _step(-1)),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${monthName(k, _m, lang)} ${localDigits('$_y', lang)}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      onPressed: () => _step(1)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekdayShort((weekStart(k) + i) % 7, lang),
                          style: TextStyle(
                              color: muted(context),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (var r = 0; r < cells.length; r += 7)
                Row(
                  children: [
                    for (final c in cells.sublist(r, r + 7))
                      Expanded(child: SizedBox(height: 42, child: c)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
