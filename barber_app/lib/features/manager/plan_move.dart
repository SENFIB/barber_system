import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/config.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';
import '../../app/widgets.dart';
import 'activation_code.dart';

class MoveError implements Exception {
  final String code;
  final String message;
  MoveError(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

class MoveResult {
  final int trimmedStaff;
  final int trimmedShifts;
  MoveResult(this.trimmedStaff, this.trimmedShifts);
}

Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> body) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    var uri = Uri.parse(url);
    final req = await client.postUrl(uri);
    req.followRedirects = false;
    req.headers.set('Content-Type', 'text/plain;charset=utf-8');
    req.add(utf8.encode(jsonEncode(body)));
    var res = await req.close().timeout(const Duration(seconds: 120));
    var hops = 0;
    while ((res.statusCode == 301 ||
            res.statusCode == 302 ||
            res.statusCode == 303 ||
            res.statusCode == 307 ||
            res.statusCode == 308) &&
        hops < 5) {
      final loc = res.headers.value('location');
      await res.drain<void>();
      if (loc == null) break;
      uri = uri.resolve(loc);
      final r2 = await client.getUrl(uri);
      r2.followRedirects = false;
      res = await r2.close().timeout(const Duration(seconds: 120));
      hops++;
    }
    final text = await res.transform(utf8.decoder).join();
    final dynamic j = jsonDecode(text);
    if (j is! Map) throw MoveError('NETWORK', 'bad response');
    if (j['ok'] == true) {
      final d = j['data'];
      if (d is Map) return Map<String, dynamic>.from(d);
      return <String, dynamic>{};
    }
    throw MoveError('${j['error'] ?? 'SERVER_ERROR'}', '${j['message'] ?? ''}');
  } on MoveError {
    rethrow;
  } on TimeoutException {
    throw MoveError('NETWORK', 'timeout');
  } on SocketException {
    throw MoveError('NETWORK', 'socket');
  } on FormatException {
    throw MoveError('NETWORK', 'format');
  } finally {
    client.close(force: true);
  }
}

class PlanMover {
  static Future<MoveResult> move({
    required AppSettings st,
    required String targetUrl,
    required String license,
    required String plan,
  }) async {
    final oldUrl = st.apiUrl;
    final token = st.shopToken ?? '';
    final dev = st.deviceId;
    if (oldUrl == targetUrl) {
      await _post(oldUrl, {
        'action': 'renew',
        'token': token,
        'device_id': dev,
        'license_key': license,
      });
      return MoveResult(0, 0);
    }
    final bundle = await _post(oldUrl, {
      'action': 'transfer_export',
      'token': token,
      'device_id': dev,
    });
    final imp = await _post(targetUrl, {
      'action': 'transfer_import',
      'license_key': license,
      'plan': plan,
      'device_id': dev,
      'bundle': bundle,
    });
    final newToken = imp['token'];
    try {
      await _post(oldUrl, {
        'action': 'transfer_close',
        'token': token,
        'device_id': dev,
        'confirm': 'moved',
      });
    } catch (_) {}
    await st.setShopToken(newToken is String ? newToken : null);
    await st.setApiUrl(targetUrl == kDefaultApiUrl ? null : targetUrl);
    final ts = imp['trimmed_staff'];
    final tsh = imp['trimmed_shifts'];
    return MoveResult(ts is num ? ts.toInt() : 0, tsh is num ? tsh.toInt() : 0);
  }
}

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'تغییر پلن',
    'intro':
        'اطلاعات آرایشگاه (آرایشگرها، خدمات، رزروها و رمزها) به پلن جدید منتقل می‌شود و همان نام کاربری و رمز قبلی کار می‌کند. روزهای باقی‌مانده به اشتراک جدید اضافه می‌شود.',
    'note':
        'اگر پلن جدید محدودتر باشد، آرایشگرها و شیفت‌های اضافه کم می‌شوند؛ عکس و پیام‌های اختصاصی فقط پنهان می‌شوند.',
    'plan': 'پلن جدید',
    'basic': 'پایه',
    'pro': 'پرو',
    'special': 'ویژه',
    'personal': 'شخصی',
    'license': 'لایسنس پلن جدید',
    'code': 'کد فعال‌سازی',
    'go': 'انتقال و تغییر پلن',
    'confirm': 'آرایشگاه به پلن جدید منتقل می‌شود. ادامه می‌دهید؟',
    'yes': 'ادامه',
    'no': 'انصراف',
    'done': 'پلن تغییر کرد ✅',
    'trim': 'آرایشگر کم‌شده: {a} | شیفت کوتاه‌شده: {b}',
    'bad_code': 'کد واردشده درست نیست',
    'need_license': 'کد را وارد کنید',
    'need_code': 'کد فعال‌سازی کامل نیست',
    'LICENSE_INVALID': 'لایسنس معتبر نیست یا قبلاً استفاده شده است',
    'PLAN_MISMATCH': 'این لایسنس برای پلن دیگری است',
    'USERNAME_TAKEN': 'این نام کاربری روی پلن جدید گرفته شده است',
    'ALREADY_HERE': 'این آرایشگاه قبلاً در پلن جدید ثبت شده است',
    'UNKNOWN_ACTION': 'این سرویس هنوز آماده‌ی انتقال نیست',
    'TOO_MANY': 'تلاش زیاد بود، کمی بعد دوباره امتحان کنید',
    'BUSY': 'سرور شلوغ است، دوباره تلاش کنید',
    'UNAUTHORIZED': 'دوباره وارد شوید',
    'FORBIDDEN': 'این کار فقط برای صاحب آرایشگاه است',
    'NETWORK': 'اتصال برقرار نشد. اینترنت را بررسی کنید',
    'other': 'خطا؛ دوباره تلاش کنید',
  },
  'en': {
    'title': 'Change plan',
    'intro':
        'Your shop data (barbers, services, bookings and passwords) moves to the new plan and your current username and password keep working. Remaining days are added to the new subscription.',
    'note':
        'If the new plan is more limited, extra barbers and shifts are reduced; photo and custom messages are only hidden.',
    'plan': 'New plan',
    'basic': 'Basic',
    'pro': 'Pro',
    'special': 'Special',
    'personal': 'Personal',
    'license': 'License of the new plan',
    'code': 'Activation code',
    'go': 'Move and change plan',
    'confirm': 'Your shop will be moved to the new plan. Continue?',
    'yes': 'Continue',
    'no': 'Cancel',
    'done': 'Plan changed ✅',
    'trim': 'Barbers reduced: {a} | Shifts shortened: {b}',
    'bad_code': 'The code is not valid',
    'need_license': 'Enter the code',
    'need_code': 'The activation code is incomplete',
    'LICENSE_INVALID': 'The license is invalid or already used',
    'PLAN_MISMATCH': 'This license belongs to another plan',
    'USERNAME_TAKEN': 'This username is already taken on the new plan',
    'ALREADY_HERE': 'This shop is already registered on the new plan',
    'UNKNOWN_ACTION': 'This service is not ready for moving yet',
    'TOO_MANY': 'Too many attempts, try again later',
    'BUSY': 'Server is busy, try again',
    'UNAUTHORIZED': 'Please sign in again',
    'FORBIDDEN': 'Only the shop owner can do this',
    'NETWORK': 'Could not connect. Check your internet',
    'other': 'Error; please try again',
  },
  'ar': {
    'title': 'تغيير الخطة',
    'intro':
        'تُنقل بيانات الصالون (الحلاقون والخدمات والحجوزات وكلمات المرور) إلى الخطة الجديدة ويبقى اسم المستخدم وكلمة المرور كما هما. تُضاف الأيام المتبقية إلى الاشتراك الجديد.',
    'note':
        'إذا كانت الخطة الجديدة أقل حدًا، يُخفَّض عدد الحلاقين والورديات الزائدة؛ أما الصورة والرسائل الخاصة فتُخفى فقط.',
    'plan': 'الخطة الجديدة',
    'basic': 'الأساسية',
    'pro': 'برو',
    'special': 'المميزة',
    'personal': 'الشخصية',
    'license': 'ترخيص الخطة الجديدة',
    'code': 'رمز التفعيل',
    'go': 'نقل وتغيير الخطة',
    'confirm': 'سيتم نقل الصالون إلى الخطة الجديدة. هل تتابع؟',
    'yes': 'متابعة',
    'no': 'إلغاء',
    'done': 'تم تغيير الخطة ✅',
    'trim': 'حلاقون تم تقليلهم: {a} | ورديات تم تقصيرها: {b}',
    'bad_code': 'الرمز المُدخل غير صحيح',
    'need_license': 'أدخل الرمز',
    'need_code': 'رمز التفعيل غير مكتمل',
    'LICENSE_INVALID': 'الترخيص غير صالح أو مستخدم سابقًا',
    'PLAN_MISMATCH': 'هذا الترخيص لخطة أخرى',
    'USERNAME_TAKEN': 'اسم المستخدم هذا مأخوذ في الخطة الجديدة',
    'ALREADY_HERE': 'هذا الصالون مسجّل مسبقًا في الخطة الجديدة',
    'UNKNOWN_ACTION': 'هذه الخدمة غير جاهزة للنقل بعد',
    'TOO_MANY': 'محاولات كثيرة، حاول لاحقًا',
    'BUSY': 'الخادم مشغول، حاول مجددًا',
    'UNAUTHORIZED': 'سجّل الدخول من جديد',
    'FORBIDDEN': 'هذا الإجراء لمالك الصالون فقط',
    'NETWORK': 'تعذر الاتصال. تحقق من الإنترنت',
    'other': 'خطأ، حاول مجددًا',
  },
};

class PlanMovePage extends StatefulWidget {
  final AppSettings settings;
  const PlanMovePage({super.key, required this.settings});
  @override
  State<PlanMovePage> createState() => _PlanMovePageState();
}

class _PlanMovePageState extends State<PlanMovePage> {
  final _lic = TextEditingController();
  String _plan = 'pro';
  bool _busy = false;

  AppSettings get _st => widget.settings;

  String _t(String k) {
    final m = _tx[_st.lang] ?? _tx['fa']!;
    return m[k] ?? _tx['fa']![k] ?? k;
  }

  @override
  void dispose() {
    _lic.dispose();
    super.dispose();
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  bool get _needsCode => _plan == 'special' || _plan == 'personal';

  Future<void> _go() async {
    if (_busy) return;
    final raw = _lic.text.trim();
    if (raw.isEmpty) {
      _snack(_t('need_license'));
      return;
    }
    String lic = raw;
    String target;
    if (_plan == 'basic') {
      target = kDefaultApiUrl;
    } else if (_plan == 'pro') {
      target = kProApiUrl;
    } else {
      final p = splitActivation(raw);
      if (p.license.isEmpty) {
        _snack(_t('need_license'));
        return;
      }
      lic = p.license;
      final u = p.url;
      if (u != null) {
        target = u;
      } else if (_st.hasCustomApiUrl) {
        target = _st.apiUrl;
      } else {
        _snack(_t('need_code'));
        return;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(_t('confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('no'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('yes'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await PlanMover.move(st: _st, targetUrl: target, license: lic, plan: _plan);
      var msg = _t('done');
      if (r.trimmedStaff > 0 || r.trimmedShifts > 0) {
        msg += '\n' +
            _t('trim')
                .replaceAll('{a}', '${r.trimmedStaff}')
                .replaceAll('{b}', '${r.trimmedShifts}');
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      nav.popUntil((route) => route.isFirst);
      await _st.setRole(null);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _st.setRole('shop');
    } on MoveError catch (e) {
      final m = _tx[_st.lang] ?? _tx['fa']!;
      if (mounted) {
        setState(() => _busy = false);
        _snack(m[e.code] ?? _t('other'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(_t('other'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ['basic', 'pro', 'special', 'personal'];
    return Scaffold(
      appBar: AppBar(title: Text(_t('title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_t('intro')),
            const SizedBox(height: 8),
            Text(_t('note'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(_t('plan'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in plans)
                  ChoiceChip(
                    label: Text(_t(p)),
                    selected: _plan == p,
                    onSelected: _busy ? null : (_) => setState(() => _plan = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GlassField(
              controller: _lic,
              label: _needsCode ? _t('code') : _t('license'),
              icon: Icons.key_rounded,
              ltr: true,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: _t('go'),
              icon: Icons.swap_horiz_rounded,
              loading: _busy,
              onPressed: _go,
            ),
          ],
        ),
      ),
    );
  }
}
