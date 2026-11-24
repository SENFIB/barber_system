import 'package:flutter/material.dart';

import '../../app/fmt.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';

/// یک شیفت کاری: شروع و پایان به‌صورت HH:mm
class Shift {
  Shift(this.start, this.end);
  String start;
  String end;
  Shift copy() => Shift(start, end);
}

int shiftMin(String t) {
  final p = t.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

String shiftTime(int m) {
  final h = (m ~/ 60).clamp(0, 23);
  final mm = (m % 60).clamp(0, 59);
  return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

String? _normHm(String v) {
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(v);
  if (m == null) return null;
  return '${m[1]!.padLeft(2, '0')}:${m[2]}';
}

/// «09:00-13:00|16:00-22:00» → لیست شیفت
List<Shift> parseShifts(String raw) {
  final out = <Shift>[];
  for (final part in raw.split(RegExp(r'[|,;]'))) {
    final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$')
        .firstMatch(part);
    if (m == null) continue;
    out.add(Shift('${m[1]!.padLeft(2, '0')}:${m[2]}',
        '${m[3]!.padLeft(2, '0')}:${m[4]}'));
  }
  return out;
}

String shiftsToString(List<Shift> l) =>
    l.map((s) => '${s.start}-${s.end}').join('|');

/// شیفت‌های یک آرایشگر از پاسخ سرور؛ اگر سرور هنوز شیفت ندارد از شروع/پایان
List<Shift> shiftsOfStaff(Map<String, dynamic> r) {
  final l = parseShifts('${r['shifts'] ?? ''}');
  if (l.isNotEmpty) return l;
  final a = _normHm('${r['work_start'] ?? ''}');
  final b = _normHm('${r['work_end'] ?? ''}');
  return [Shift(a ?? '09:00', b ?? '18:00')];
}

/// true یعنی سرور می‌گوید آرایشگر هنوز ساعتش را تنظیم نکرده.
/// اگر سرور این فیلد را نفرستد (نسخه‌ی قدیمی)، هشدار نمی‌دهیم.
bool scheduleUnset(Map<String, dynamic> r) {
  if (!r.containsKey('schedule_set')) return false;
  final v = r['schedule_set'];
  return !(v == true || v == 1 || '$v'.toUpperCase() == 'TRUE');
}

/// null = درست. در غیر این‌صورت کلید متنِ خطا
String? validateShifts(List<Shift> l) {
  if (l.isEmpty) return 'v_required';
  var prevEnd = -1;
  for (final s in l) {
    final a = shiftMin(s.start);
    final b = shiftMin(s.end);
    if (a >= b) return 'sh_overlap';
    if (a < prevEnd) return 'sh_overlap';
    prevEnd = b;
  }
  return null;
}

String shiftsText(List<Shift> l, String lang) => l
    .map((s) => localDigits('${s.start} – ${s.end}', lang))
    .join('   •   ');

/// ویرایشگر شیفت‌ها (تا ۳ شیفت)
class ShiftsEditor extends StatelessWidget {
  const ShiftsEditor({
    super.key,
    required this.shifts,
    required this.onChanged,
    this.max = 3,
  });

  final List<Shift> shifts;
  final ValueChanged<List<Shift>> onChanged;
  final int max;

  List<Shift> _copy() => [for (final s in shifts) s.copy()];

  Future<void> _pick(BuildContext c, int i, bool start) async {
    final cur = shiftMin(start ? shifts[i].start : shifts[i].end);
    final r = await showTimePicker(
      context: c,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      builder: (cc, child) => MediaQuery(
        data: MediaQuery.of(cc).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (r == null) return;
    final next = _copy();
    final v = shiftTime(r.hour * 60 + r.minute);
    if (start) {
      next[i].start = v;
    } else {
      next[i].end = v;
    }
    onChanged(next);
  }

  void _add(BuildContext c, T6 x) {
    final s = shiftMin(shifts.last.end) + 60;
    if (s >= 1380) {
      toast(c, x.t('sh_no_room'));
      return;
    }
    final e = (s + 240) > 1439 ? 1439 : (s + 240);
    final next = _copy()..add(Shift(shiftTime(s), shiftTime(e)));
    onChanged(next);
  }

  void _remove(int i) {
    final next = _copy()..removeAt(i);
    onChanged(next);
  }

  Widget _box(BuildContext c, String label, String value, VoidCallback onTap) {
    final lang = SettingsScope.read(c).lang;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: lk(c).dark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.045),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: muted(c), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              localDigits(value, lang),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext c, T6 x, int i) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lk(c).cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(x.t('sh_n', {'n': i + 1}),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              if (shifts.length > 1)
                IconButton(
                  tooltip: x.t('sh_remove'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: lk(c).danger, size: 22),
                  onPressed: () => _remove(i),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _box(c, x.t('sh_from'), shifts[i].start,
                      () => _pick(c, i, true))),
              const SizedBox(width: 10),
              Expanded(
                  child: _box(c, x.t('sh_to'), shifts[i].end,
                      () => _pick(c, i, false))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = T6(SettingsScope.of(context).lang);
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(x.t('sh_hint'),
              style: TextStyle(color: muted(context), fontSize: 12.5, height: 1.7)),
          const SizedBox(height: 12),
          for (var i = 0; i < shifts.length; i++) ...[
            _row(context, x, i),
            const SizedBox(height: 10),
          ],
          if (shifts.length < max)
            GradientButton(
              label: x.t('sh_add'),
              icon: Icons.add_rounded,
              compact: true,
              outlined: true,
              onPressed: () => _add(context, x),
            ),
        ],
      ),
    );
  }
}
