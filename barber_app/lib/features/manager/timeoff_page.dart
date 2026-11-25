import 'package:flutter/material.dart';
import '../../app/date_pick.dart';
import '../../app/settings.dart';
import '../../app/strings_s3.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'booking_common.dart';
import 'shop_api.dart';
import 'shop_raw.dart';

class TimeOffPage extends StatefulWidget {
  const TimeOffPage(this.ctx, {super.key});
  final ShopCtx ctx;

  @override
  State<TimeOffPage> createState() => _TimeOffPageState();
}

class _TimeOffPageState extends State<TimeOffPage> {
  bool _loading = true;
  bool _busy = false;
  Object? _err;
  List<Map<String, dynamic>> _blocks = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _staff = <Map<String, dynamic>>[];

  T3 _tr() => T3(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  bool _lost(Object e) {
    if (isSessionLost(e)) {
      if (mounted) Navigator.of(context).pop();
      widget.ctx.reload();
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final raw = ShopRaw(SettingsScope.read(context));
      final r = await raw.call('timeoff_list');
      final blocks = bFirstList(r, ['blocks', 'timeoff', 'items', 'list']);
      blocks.sort((a, b) =>
          bStr(a['date_from']).compareTo(bStr(b['date_from'])));
      var staff = _staff;
      if (staff.isEmpty) {
        try {
          final sr = await raw.call('staff_list');
          staff = bFirstList(sr, ['staff', 'items', 'list']);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _staff = staff;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }

  String _staffName(String id) {
    if (id.isEmpty) return _tr().t('t_whole_shop');
    for (final s in _staff) {
      if (bStr(s['staff_id']) == id) return bStr(s['name']);
    }
    return id;
  }

  String _d(String iso) {
    final s = SettingsScope.of(context);
    return fmtPickIso(iso, s.calendarKey, s.lang);
  }

  Future<void> _add() async {
    final n = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => _TimeOffAddPage(staff: _staff)),
    );
    if (n == null || !mounted) return;
    final t = _tr();
    await _load();
    if (!mounted) return;
    if (n > 0) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
          title: Text(t.t('t_warn_title')),
          content: Text(t.t('t_conflict', {'n': '$n'})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: Text(t.t('c_ok')),
            ),
          ],
        ),
      );
    } else {
      bSnack(context, t.t('t_saved'));
    }
  }

  Future<void> _remove(Map<String, dynamic> b) async {
    if (_busy) return;
    final t = _tr();
    final ok = await confirmDialog(
      context,
      title: t.t('t_title'),
      message: t.t('t_remove_q'),
      okLabel: t.t('t_remove'),
      cancelLabel: t.t('c_cancel'),
      danger: true,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ShopRaw(SettingsScope.read(context)).call(
        'timeoff_remove',
        <String, dynamic>{'block_id': bStr(b['block_id'])},
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (_lost(e)) return;
      bSnack(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = T3(SettingsScope.of(context).lang);
    final children = <Widget>[];
    if (_loading && _blocks.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (_err != null) {
      children.add(Glass(
        child: Column(
          children: [
            Text(t.error(_err!), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GradientButton(
              compact: true,
              icon: Icons.refresh_rounded,
              label: t.t('c_retry'),
              onPressed: () {
                _load();
              },
            ),
          ],
        ),
      ));
    } else if (_blocks.isEmpty) {
      children.add(Glass(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              GradientIcon(Icons.event_busy_rounded, size: 44),
              const SizedBox(height: 12),
              Text(t.t('t_empty'), style: TextStyle(color: muted(context))),
            ],
          ),
        ),
      ));
    } else {
      for (final b in _blocks) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _card(b, t),
        ));
      }
    }
    children.add(const SizedBox(height: 90));
    return GlassScaffold(
      title: t.t('t_title'),
      maxWidth: 600,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lk(context).primary,
        foregroundColor: lk(context).onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.t('t_add')),
        onPressed: _add,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: children,
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> b, T3 t) {
    final from = bStr(b['date_from']);
    final to = bStr(b['date_to']);
    final st = bStr(b['start_time']);
    final en = bStr(b['end_time']);
    final allDay = st.isEmpty || en.isEmpty;
    final reason = bStr(b['reason']);
    final dateText =
        from == to || to.isEmpty ? _d(from) : '${_d(from)} → ${_d(to)}';
    return Glass(
      child: Row(
        children: [
          const GradientIcon(Icons.event_busy_rounded, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  allDay ? t.t('t_all_day') : '$st – $en',
                  textDirection: allDay ? null : TextDirection.ltr,
                  style: TextStyle(color: muted(context)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    Pill(_staffName(bStr(b['staff_id'])),
                        color: AppColors.blue),
                  ],
                ),
                if (reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(reason,
                        style:
                            TextStyle(color: muted(context), fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.t('t_remove'),
            icon: Icon(Icons.delete_outline_rounded,
                color: lk(context).danger),
            onPressed: () => _remove(b),
          ),
        ],
      ),
    );
  }
}

class _TimeOffAddPage extends StatefulWidget {
  const _TimeOffAddPage({required this.staff});
  final List<Map<String, dynamic>> staff;

  @override
  State<_TimeOffAddPage> createState() => _TimeOffAddPageState();
}

class _TimeOffAddPageState extends State<_TimeOffAddPage> {
  String _who = '';
  late DateTime _from;
  late DateTime _to;
  bool _allDay = true;
  TimeOfDay _ts = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _te = const TimeOfDay(hour: 13, minute: 0);
  final _reason = TextEditingController();
  bool _busy = false;

  T3 _tr() => T3(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _from = DateTime(n.year, n.month, n.day);
    _to = _from;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _show(DateTime d) {
    final s = SettingsScope.of(context);
    return fmtPickDate(d, s.calendarKey, s.lang);
  }

  Future<void> _pickDate(bool isFrom) async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final s = SettingsScope.read(context);
    final d = await pickLocalDate(
      context,
      initial: isFrom ? _from : _to,
      first: today.subtract(const Duration(days: 1)),
      last: today.add(const Duration(days: 730)),
      calKey: s.calendarKey,
      lang: s.lang,
    );
    if (d == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = d;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = d;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final v = await showTimePicker(
      context: context,
      initialTime: isStart ? _ts : _te,
    );
    if (v == null || !mounted) return;
    setState(() {
      if (isStart) {
        _ts = v;
      } else {
        _te = v;
      }
    });
  }

  Future<void> _save() async {
    final t = _tr();
    if (_to.isBefore(_from)) {
      bSnack(context, t.t('t_bad_range'));
      return;
    }
    if (!_allDay && bMin(bTime(_te)) <= bMin(bTime(_ts))) {
      bSnack(context, t.t('t_bad_time'));
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ShopRaw(SettingsScope.read(context)).call(
        'timeoff_add',
        <String, dynamic>{
          'staff_id': _who,
          'date_from': bIso(_from),
          'date_to': bIso(_to),
          'start_time': _allDay ? '' : bTime(_ts),
          'end_time': _allDay ? '' : bTime(_te),
          'reason': _reason.text.trim(),
        },
      );
      if (!mounted) return;
      final c = r['conflicts'];
      final n = c is List ? c.length : bInt(c);
      Navigator.of(context).pop(n);
    } catch (e) {
      if (!mounted) return;
      bSnack(context, t.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
      );

  Widget _pickTile(IconData icon, String title, String value, VoidCallback f) {
    return Glass(
      onTap: f,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = T3(SettingsScope.of(context).lang);
    return GlassScaffold(
      title: t.t('t_add'),
      maxWidth: 600,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _label(t.t('t_who')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(t.t('t_whole_shop')),
                selected: _who.isEmpty,
                onSelected: (_) => setState(() => _who = ''),
              ),
              for (final s in widget.staff)
                ChoiceChip(
                  label: Text(bStr(s['name'])),
                  selected: _who == bStr(s['staff_id']),
                  onSelected: (_) =>
                      setState(() => _who = bStr(s['staff_id'])),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _pickTile(Icons.event_rounded, t.t('t_from'), _show(_from),
              () => _pickDate(true)),
          const SizedBox(height: 10),
          _pickTile(Icons.event_rounded, t.t('t_to'), _show(_to),
              () => _pickDate(false)),
          const SizedBox(height: 14),
          Glass(
            child: Row(
              children: [
                Expanded(
                  child: Text(t.t('t_all_day'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Switch(
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
              ],
            ),
          ),
          if (!_allDay) ...[
            const SizedBox(height: 10),
            _pickTile(Icons.schedule_rounded, t.t('t_time_from'),
                bTime(_ts), () => _pickTime(true)),
            const SizedBox(height: 10),
            _pickTile(Icons.schedule_rounded, t.t('t_time_to'), bTime(_te),
                () => _pickTime(false)),
          ],
          const SizedBox(height: 14),
          GlassField(
            controller: _reason,
            label: t.t('t_reason'),
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 22),
          GradientButton(
            loading: _busy,
            icon: Icons.check_rounded,
            label: t.t('t_save'),
            onPressed: () {
              if (!_busy) _save();
            },
          ),
        ],
      ),
    );
  }
}
