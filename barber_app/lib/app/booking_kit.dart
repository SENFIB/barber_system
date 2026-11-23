import 'package:flutter/material.dart';
import 'cal.dart';
import 'jx.dart';
import 'settings.dart';
import 'strings_pro.dart';
import 'ui_kit.dart';
import 'widgets.dart';

/// انتخاب خدمت‌ها (با رعایت ترکیب‌پذیری) و آرایشگر هر خدمت
class ServicePicker extends StatelessWidget {
  const ServicePicker({
    super.key,
    required this.services,
    required this.staff,
    required this.selected,
    required this.pick,
    required this.maxServices,
    required this.currency,
    required this.onChanged,
    this.lockedStaff = false,
  });
  final List<Map<String, dynamic>> services, staff;
  final List<String> selected;
  final Map<String, String> pick;
  final int maxServices;
  final String currency;
  final bool lockedStaff;
  final void Function(List<String>, Map<String, String>) onChanged;

  bool _comb(Map<String, dynamic> a, Map<String, dynamic> b) =>
      strList(a['combinable_with']).contains(strOf(b['service_id'])) ||
      strList(b['combinable_with']).contains(strOf(a['service_id']));

  bool _ok(Map<String, dynamic> s) {
    for (final id in selected) {
      final o = services.firstWhere((x) => strOf(x['service_id']) == id,
          orElse: () => <String, dynamic>{});
      if (o.isEmpty) continue;
      if (!_comb(s, o)) return false;
    }
    return true;
  }

  void _tap(BuildContext c, Map<String, dynamic> s, Z z) {
    final id = strOf(s['service_id']);
    final next = [...selected];
    final np = Map<String, String>.from(pick);
    if (next.contains(id)) {
      next.remove(id);
      np.remove(id);
    } else {
      if (next.length >= maxServices) {
        toast(c, z.t('max_services', {'n': maxServices}));
        return;
      }
      if (!_ok(s)) {
        toast(c, z.t('not_combinable'));
        return;
      }
      next.add(id);
    }
    onChanged(next, np);
  }

  Widget _row(BuildContext context, Map<String, dynamic> s, Z z, String lang) {
    final id = strOf(s['service_id']);
    final sel = selected.contains(id);
    final ok = sel || _ok(s);
    final price = intOf(s['price']);
    final dur = localDigits('${intOf(s['duration_min'])}', lang);
    final extra = price > 0 ? ' · ${localDigits(money(price), lang)} $currency' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: ok ? 1 : 0.45,
        child: Glass(
          onTap: () => _tap(context, s, z),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                sel
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: sel ? lk(context).primary : muted(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strOf(s['name']),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5)),
                    Text('$dur ${z.t('min')}$extra',
                        style: TextStyle(color: muted(context), fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _chips(String id, Z z) {
    if (lockedStaff) return const [];
    final sv = services.firstWhere((x) => strOf(x['service_id']) == id,
        orElse: () => <String, dynamic>{});
    final cands = staff.where((t) {
      final l = strList(t['service_ids'] ?? t['service_id_list']);
      return l.isEmpty || l.contains(id);
    }).toList();
    if (cands.length < 2) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Text('${z.t('barber_for')} ${strOf(sv['name'])}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: Text(z.t('any_barber')),
            selected: !pick.containsKey(id),
            onSelected: (_) {
              final np = Map<String, String>.from(pick)..remove(id);
              onChanged([...selected], np);
            },
          ),
          for (final t in cands)
            ChoiceChip(
              label: Text(strOf(t['name'])),
              selected: pick[id] == strOf(t['staff_id']),
              onSelected: (_) {
                final np = Map<String, String>.from(pick);
                np[id] = strOf(t['staff_id']);
                onChanged([...selected], np);
              },
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final z = Z(lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in services) _row(context, s, z, lang),
        for (final id in selected) ..._chips(id, z),
      ],
    );
  }
}

/// نوار انتخاب روز: قبلی / تقویم / بعدی
class DateBar extends StatelessWidget {
  const DateBar(
      {super.key,
      required this.iso,
      required this.cal,
      required this.onChanged,
      this.min,
      this.max});
  final String iso;
  final CalKind cal;
  final ValueChanged<String> onChanged;
  final String? min, max;

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final mn = min;
    final mx = max;
    final prev = addDaysIso(iso, -1);
    final next = addDaysIso(iso, 1);
    final canPrev = mn == null || prev.compareTo(mn) >= 0;
    final canNext = mx == null || next.compareTo(mx) <= 0;
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: canPrev ? () => onChanged(prev) : null,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final r = await pickDate(context,
                    initial: iso, cal: cal, lang: lang, min: mn, max: mx);
                if (r != null) onChanged(r);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fmtDate(iso, cal, lang, weekday: true),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: canNext ? () => onChanged(next) : null,
          ),
        ],
      ),
    );
  }
}
