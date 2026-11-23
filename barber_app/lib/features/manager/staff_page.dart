import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import 'shop_api.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key, required this.ctx});
  final ShopCtx ctx;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool _loading = true;
  bool _busy = false;
  String? _err;
  List<Map<String, dynamic>> _staff = [];
  int _max = 0;
  String _myStaffId = '';

  bool get _owner => widget.ctx.session.isOwner;
  S get _s => S(SettingsScope.read(context).lang);

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _lost(ApiException e) => const {
        'UNAUTHORIZED',
        'DEVICE_MISMATCH',
        'SUBSCRIPTION_EXPIRED',
        'SHOP_DEACTIVATED',
      }.contains(e.code);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final d = await widget.ctx.api.staffList();
      var my = '';
      if (_owner) {
        try {
          my = (await widget.ctx.api.me()).staffId;
        } catch (_) {}
      } else {
        my = widget.ctx.session.staffId;
      }
      final raw = d['staff'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) list.add(Map<String, dynamic>.from(e));
        }
      }
      if (!mounted) return;
      setState(() {
        _staff = list;
        _max = int.tryParse('${d['max_staff']}') ?? 0;
        _myStaffId = my;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_lost(e)) {
        Navigator.of(context).pop();
        widget.ctx.reload();
        return;
      }
      setState(() {
        _err = _s.error(e);
        _loading = false;
      });
    }
  }

  Future<void> _act(Future<void> Function() fn, String okMsg) async {
    final s = _s;
    setState(() => _busy = true);
    try {
      await fn();
      if (!mounted) return;
      toast(context, okMsg);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_lost(e)) {
        Navigator.of(context).pop();
        widget.ctx.reload();
        return;
      }
      toast(context, s.error(e));
    }
    if (mounted) {
      setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _add() async {
    final s = _s;
    final r = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _StaffDialog(s: s, title: s.t('add_barber')),
    );
    if (r == null) return;
    await _act(
      () => widget.ctx.api.staffAdd(
        name: r['name']!,
        specialty: r['specialty']!,
        workStart: r['start']!,
        workEnd: r['end']!,
      ),
      s.t('staff_added'),
    );
  }

  Future<void> _becomeBarber() async {
    final s = _s;
    final r = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _StaffDialog(
        s: s,
        title: s.t('become_barber'),
        initialName: widget.ctx.session.shop.name,
        withHours: false,
      ),
    );
    if (r == null) return;
    await _act(
      () => widget.ctx.api.ownerBarber(
        enabled: true,
        name: r['name']!,
        specialty: r['specialty']!,
      ),
      s.t('staff_added'),
    );
  }

  Future<void> _stopBarber() async {
    final s = _s;
    final ok = await confirmDialog(
      context,
      title: s.t('stop_barber'),
      message: s.t('stop_barber_confirm'),
      okLabel: s.t('remove'),
      cancelLabel: s.t('cancel'),
      danger: true,
    );
    if (!ok) return;
    await _act(
      () => widget.ctx.api.ownerBarber(enabled: false),
      s.t('staff_removed'),
    );
  }

  Future<void> _remove(String id) async {
    final s = _s;
    final ok = await confirmDialog(
      context,
      title: s.t('remove'),
      message: s.t('remove_confirm'),
      okLabel: s.t('remove'),
      cancelLabel: s.t('cancel'),
      danger: true,
    );
    if (!ok) return;
    await _act(() => widget.ctx.api.staffRemove(id), s.t('staff_removed'));
  }

  String _date(dynamic d) {
    final t = '${d ?? ''}';
    return t.length >= 10 ? t.substring(0, 10) : t;
  }

  Widget _card(Map<String, dynamic> m, S s) {
    final id = '${m['staff_id'] ?? ''}';
    final mine = id.isNotEmpty && id == _myStaffId;
    final name = '${m['name'] ?? ''}';
    final spec = '${m['specialty'] ?? ''}';
    final hasLogin = m['has_login'] == true ||
        '${m['has_login']}'.toLowerCase() == 'true';
    final inv = m['invite'] is Map
        ? Map<String, dynamic>.from(m['invite'] as Map)
        : null;
    final code = inv == null ? '' : '${inv['code'] ?? ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                          if (mine) ...[
                            const SizedBox(width: 8),
                            Pill(s.t('you')),
                          ],
                        ],
                      ),
                      if (spec.isNotEmpty)
                        Text(spec, style: TextStyle(color: muted(context))),
                    ],
                  ),
                ),
                if (_owner && !mine)
                  IconButton(
                    tooltip: s.t('remove'),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.red),
                    onPressed: _busy ? null : () => _remove(id),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if ('${m['work_start'] ?? ''}'.isNotEmpty)
                  Pill('${s.t('hours')}: ${m['work_start']}–${m['work_end']}',
                      color: AppColors.blue),
                if (hasLogin) Pill(s.t('has_login'), color: AppColors.green),
              ],
            ),
            if (_owner && mine) ...[
              const SizedBox(height: 12),
              GradientButton(
                compact: true,
                outlined: true,
                label: s.t('stop_barber'),
                onPressed: _busy ? null : _stopBarber,
              ),
            ],
            if (_owner && !mine && !hasLogin) ...[
              const SizedBox(height: 12),
              if (inv != null && code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.violet.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('invite_label'),
                          style:
                              TextStyle(color: muted(context), fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              code,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                fontFamily: 'Consolas',
                                fontFamilyFallback: ['monospace'],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: code));
                              if (mounted) toast(context, s.t('copied'));
                            },
                          ),
                        ],
                      ),
                      Text('${s.t('invite_expires')}: ${_date(inv['expires_at'])}',
                          style:
                              TextStyle(color: muted(context), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(s.t('invite_hint'),
                          style:
                              TextStyle(color: muted(context), fontSize: 12)),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _act(
                                    () => widget.ctx.api.inviteRevoke(code),
                                    s.t('invite_revoked'),
                                  ),
                          child: Text(s.t('invite_revoke'),
                              style: const TextStyle(color: AppColors.red)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GradientButton(
                  compact: true,
                  icon: Icons.confirmation_number_outlined,
                  label: s.t('invite_create'),
                  onPressed: _busy
                      ? null
                      : () => _act(
                            () => widget.ctx.api.inviteCreate(id),
                            s.t('invite_created'),
                          ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S(SettingsScope.of(context).lang);

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_err != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Glass(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_err!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                GradientButton(
                  compact: true,
                  label: s.t('retry'),
                  icon: Icons.refresh_rounded,
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            if (_owner && _max > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Glass(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded),
                      const SizedBox(width: 10),
                      Text(
                        s.t('capacity', {'n': _staff.length, 'max': _max}),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            if (_owner && _myStaffId.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('become_barber'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(s.t('become_barber_desc'),
                          style:
                              TextStyle(color: muted(context), fontSize: 12.5)),
                      const SizedBox(height: 12),
                      GradientButton(
                        compact: true,
                        icon: Icons.content_cut_rounded,
                        label: s.t('become_barber'),
                        onPressed: _busy ? null : _becomeBarber,
                      ),
                    ],
                  ),
                ),
              ),
            if (_staff.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                  child: Text(s.t('no_staff'),
                      style: TextStyle(color: muted(context))),
                ),
              ),
            for (final m in _staff) _card(m, s),
          ],
        ),
      );
    }

    return GlassScaffold(
      title: s.t(_owner ? 'staff_title' : 'staff_mine'),
      floatingActionButton: _owner && !_loading && _err == null
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _add,
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(s.t('add_barber')),
            )
          : null,
      body: content,
    );
  }
}

// ───────────────────────── دیالوگ افزودن آرایشگر ─────────────────────────
class _StaffDialog extends StatefulWidget {
  const _StaffDialog({
    required this.s,
    required this.title,
    this.initialName = '',
    this.withHours = true,
  });

  final S s;
  final String title;
  final String initialName;
  final bool withHours;

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  final _spec = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 21, minute: 0);

  @override
  void dispose() {
    _name.dispose();
    _spec.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final r = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox(),
      ),
    );
    if (r != null) setState(() => start ? _start = r : _end = r);
  }

  void _ok() {
    final s = widget.s;
    if (_name.text.trim().length < 2) {
      toast(context, s.t('v_required'));
      return;
    }
    if (widget.withHours &&
        (_start.hour * 60 + _start.minute) >= (_end.hour * 60 + _end.minute)) {
      toast(context, s.t('err_BAD_TIME'));
      return;
    }
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'specialty': _spec.text.trim(),
      'start': _fmt(_start),
      'end': _fmt(_end),
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            GlassField(
              controller: _name,
              label: s.t('barber_name'),
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            GlassField(
              controller: _spec,
              label: s.t('specialty'),
              icon: Icons.content_cut_rounded,
            ),
            if (widget.withHours) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text('${s.t('work_start')}\n${_fmt(_start)}',
                          textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(false),
                      child: Text('${s.t('work_end')}\n${_fmt(_end)}',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel'))),
        TextButton(onPressed: _ok, child: Text(s.t('add'))),
      ],
    );
  }
}
