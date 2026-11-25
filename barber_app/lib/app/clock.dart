import 'dart:async';
import 'package:flutter/material.dart';
import 'cal_fmt.dart';
import 'cal_names.dart' show calMonthName, localDigits;

/// اختلاف ساعت منطقه‌ی هر زبان (دقیقه نسبت به UTC)
/// فارسی = تهران ، عربی = مکه/ریاض ، انگلیسی = لندن (با ساعت تابستانی)
int zoneOffsetMinutes(String lang, DateTime utcNow) {
  if (lang == 'fa') return 210;
  if (lang == 'ar') return 180;
  final y = utcNow.year;
  final start = _lastSunday(y, 3).add(const Duration(hours: 1));
  final end = _lastSunday(y, 10).add(const Duration(hours: 1));
  final bst = !utcNow.isBefore(start) && utcNow.isBefore(end);
  return bst ? 60 : 0;
}

DateTime _lastSunday(int year, int month) {
  var d = DateTime.utc(year, month + 1, 0);
  while (d.weekday != DateTime.sunday) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}

/// ساعت دیواری (فقط اعداد سال/ماه/روز/ساعت/دقیقه مهم‌اند)
DateTime wallNow(String lang, bool phone) {
  if (phone) return DateTime.now();
  final u = DateTime.now().toUtc();
  return u.add(Duration(minutes: zoneOffsetMinutes(lang, u)));
}

String zoneCity(String lang) =>
    lang == 'fa' ? 'تهران' : (lang == 'ar' ? 'مكة' : 'London');

const Map<String, List<String>> _weekdays = {
  'fa': ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'],
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  'ar': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
};

String weekdayName(String lang, int weekday) {
  final l = _weekdays[lang] ?? _weekdays['fa']!;
  return l[(weekday - 1).clamp(0, 6)];
}

/// روزهای تعطیل: فارسی جمعه | عربی جمعه و شنبه | انگلیسی شنبه و یکشنبه
bool isWeekend(String lang, int weekday) {
  if (lang == 'fa') return weekday == DateTime.friday;
  if (lang == 'ar') {
    return weekday == DateTime.friday || weekday == DateTime.saturday;
  }
  return weekday == DateTime.saturday || weekday == DateTime.sunday;
}

String _two(int v) => v < 10 ? '0$v' : '$v';

class HeaderClock extends StatefulWidget {
  const HeaderClock({
    super.key,
    required this.lang,
    required this.calendar,
    required this.phone,
  });
  final String lang;
  final String calendar;
  final bool phone;
  @override
  State<HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<HeaderClock> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final now = wallNow(lang, widget.phone);
    final cal = CalFmt.kind(widget.calendar, lang);
    final iso = '${now.year.toString().padLeft(4, '0')}-${_two(now.month)}-${_two(now.day)}';
    final p = CalFmt.ymd(iso, cal, lang) ?? <int>[now.year, now.month, now.day];
    final day = localDigits(p[2], lang);
    final year = localDigits(p[0], lang);
    final month = calMonthName(cal, p[1], lang);
    final time = localDigits('${_two(now.hour)}:${_two(now.minute)}', lang);
    final wd = weekdayName(lang, now.weekday);
    final red = isWeekend(lang, now.weekday);
    final base = Theme.of(context).colorScheme.onSurface.withOpacity(0.8);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          style: TextStyle(
              fontSize: 12.5, color: base, fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: wd,
              style: TextStyle(
                color: red ? Colors.redAccent : base,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: '  $day $month $year  •  '),
            TextSpan(
              text: time,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}
