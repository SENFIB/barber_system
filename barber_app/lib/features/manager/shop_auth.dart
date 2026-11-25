import 'package:barber_core/barber_core.dart';
import 'package:flutter/material.dart';
import '../../app/config.dart' show kDefaultApiUrl;
import '../../app/extra_http.dart' show extraPost;
import '../../app/fmt.dart';
import '../../app/plans_config.dart';
import '../../app/servers.dart' show kProApiUrl;
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/util.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';
import 'activation_code.dart';
import 'server_code.dart';
import 'shifts_editor.dart';
import 'shop_api.dart';

typedef SessionCallback = Future<void> Function(ManagerSession session);

String _x(String lang, String fa, String en, String ar) =>
    lang == 'fa' ? fa : (lang == 'ar' ? ar : en);

// متن‌های «کسب‌وکار» که جای واژه‌های قدیمی آرایشگاه می‌نشینند
const Map<String, List<String>> _ov = {
  'shop_panel': ['پنل کسب‌وکار', 'Business panel', 'لوحة النشاط التجاري'],
  'shop_panel_sub': [
    'برای مدیریت نوبت‌ها وارد شوید',
    'Sign in to manage your bookings',
    'سجّل الدخول لإدارة الحجوزات'
  ],
  'signup_owner': [
    'ثبت‌نام کسب‌وکار',
    'Register a business',
    'تسجيل نشاط تجاري'
  ],
  'signup_owner_desc': [
    'با کد لایسنس، کسب‌وکار خودت را بساز',
    'Create your business with a license code',
    'أنشئ نشاطك التجاري برمز الترخيص'
  ],
  'signup_staff': [
    'ثبت‌نام پرسنل',
    'Register as staff',
    'تسجيل موظف'
  ],
  'signup_staff_desc': [
    'با کد دعوتی که صاحب کسب‌وکار به تو داده',
    'With the invite code from the business owner',
    'برمز الدعوة من صاحب النشاط التجاري'
  ],
  'shop_name': ['نام کسب‌وکار', 'Business name', 'اسم النشاط التجاري'],
  'i_am_barber': [
    'خودم هم خدمت می‌دهم',
    'I also provide services myself',
    'أقدّم الخدمات بنفسي'
  ],
  'create_shop': ['ساخت کسب‌وکار', 'Create business', 'إنشاء النشاط التجاري'],
};

String _w(String lang, T6 s, String key) {
  final o = _ov[key];
  if (o == null) return s.t(key);
  return lang == 'fa' ? o[0] : (lang == 'ar' ? o[2] : o[1]);
}

Future<void> _saveGender(
    AppSettings st, String gender, String plan, String? serverUrl) async {
  if (gender != 'men' && gender != 'women') return;
  try {
    final String url;
    if (plan == 'basic') {
      url = kDefaultApiUrl;
    } else if (plan == 'pro') {
      url = kProApiUrl;
    } else {
      url = serverUrl ?? st.apiUrl;
    }
    await extraPost(url, <String, dynamic>{
      'action': 'shop_update',
      'token': st.shopToken,
      'device_id': st.deviceId,
      'gender': gender,
    });
  } catch (_) {}
}

class ShopAuthPage extends StatefulWidget {
  const ShopAuthPage({super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;
  @override
  State<ShopAuthPage> createState() => _ShopAuthPageState();
}

class _ShopAuthPageState extends State<ShopAuthPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final s = T6(SettingsScope.read(context).lang);
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    if (!usernameOk(_user.text)) {
      toast(context, s.t('v_username'));
      return;
    }
    setState(() => _loading = true);
    try {
      final sess = await widget.api.login(_user.text, _pass.text);
      await widget.onSession(sess);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final s = T6(st.lang);
    return GlassScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Center(child: AppLogo()),
          const SizedBox(height: 18),
          Center(
            child: Text(_w(st.lang, s, 'shop_panel'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(_w(st.lang, s, 'shop_panel_sub'),
                style: TextStyle(color: muted(context))),
          ),
          const SizedBox(height: 24),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  onSubmitted: (_) => _login(),
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('login_btn'),
                  icon: Icons.login_rounded,
                  loading: _loading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(s.t('no_account'),
                    style: TextStyle(color: muted(context))),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            outlined: true,
            icon: Icons.person_add_alt_1_rounded,
            label: s.t('signup'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SignupChoicePage(
                  api: widget.api, onSession: widget.onSession),
            )),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServerCodePage())),
              icon: Icon(
                  st.hasCustomApiUrl
                      ? Icons.check_circle_rounded
                      : Icons.vpn_key_outlined,
                  size: 18),
              label: Text(
                _x(
                  st.lang,
                  st.hasCustomApiUrl ? 'کد راه‌اندازی (فعال)' : 'کد راه‌اندازی',
                  st.hasCustomApiUrl ? 'Setup code (active)' : 'Setup code',
                  st.hasCustomApiUrl ? 'رمز الإعداد (مفعّل)' : 'رمز الإعداد',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupChoicePage extends StatelessWidget {
  const SignupChoicePage(
      {super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    final s = T6(lang);
    Widget card(IconData icon, String title, String desc, VoidCallback onTap) {
      return Glass(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GradientIcon(icon, size: 58),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(color: muted(context), height: 1.5)),
                ],
              ),
            ),
            Icon(chevron(context), color: muted(context)),
          ],
        ),
      );
    }

    return GlassScaffold(
      title: s.t('signup_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          card(
            Icons.storefront_rounded,
            _w(lang, s, 'signup_owner'),
            _w(lang, s, 'signup_owner_desc'),
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OwnerPlanPage(api: api, onSession: onSession),
            )),
          ),
          const SizedBox(height: 14),
          card(
            Icons.badge_rounded,
            _w(lang, s, 'signup_staff'),
            _w(lang, s, 'signup_staff_desc'),
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StaffJoinPage(api: api, onSession: onSession),
            )),
          ),
        ],
      ),
    );
  }
}

String _planName(String lang, String key) {
  switch (key) {
    case 'basic':
      return _x(lang, 'پایه', 'Basic', 'أساسية');
    case 'pro':
      return _x(lang, 'پرو', 'Pro', 'برو');
    case 'special':
      return _x(lang, 'ویژه', 'Special', 'مميزة');
    default:
      return _x(lang, 'پلن شخصی', 'Personal plan', 'الخطة الشخصية');
  }
}

IconData _planIcon(String key) {
  switch (key) {
    case 'basic':
      return Icons.store_rounded;
    case 'pro':
      return Icons.workspace_premium_rounded;
    case 'special':
      return Icons.diamond_rounded;
    default:
      return Icons.dns_rounded;
  }
}

String _planPrice(String lang, PlanDef p) {
  final toman = _x(lang, 'تومان', 'Toman', 'تومان');
  if (p.key == 'personal' || p.oneTime > 0) {
    return _x(lang, 'خرید یکباره', 'One-time purchase', 'شراء لمرة واحدة');
  }
  if (p.monthly <= 0) return _x(lang, 'رایگان', 'Free', 'مجاني');
  final perMonth = _x(lang, '/ ماه', '/ month', '/ شهر');
  return '${fmtNum(p.monthly, lang)} $toman $perMonth';
}

List<String> _planFeatures(String lang, PlanDef p) {
  final booking = _x(lang, 'رزرو آنلاین مشتری', 'Online customer booking',
      'حجز العملاء عبر الإنترنت');
  final photo = _x(
      lang,
      'قرار دادن عکس کسب‌وکار در صفحهٔ کسب‌وکارها',
      'Your business photo on the businesses page',
      'وضع صورة نشاطك في صفحة الأنشطة التجارية');
  final winback = _x(
      lang,
      'ارسال پیام اختصاصی آرایشگاه در بازه‌های مشخص',
      'Custom shop messages to customers at set intervals',
      'إرسال رسالة خاصة بالصالون للزبائن في فترات محددة');
  final bizList = _x(
      lang,
      'نمایش در جستجوی مشتریان بر اساس نوع کسب‌وکار',
      'Listed in customer search by business type',
      'الظهور في بحث العملاء حسب نوع النشاط');
  final adsPaid = _x(lang, 'تبلیغ در صفحه‌ی سایر کسب‌وکارها (اختیاری، پولی)',
      'Ads on other businesses’ pages (optional, paid)',
      'إعلان في صفحات الأنشطة الأخرى (اختياري، مدفوع)');
  final adsFree = _x(lang, 'تبلیغ رایگان در صفحه‌ی سایر کسب‌وکارها',
      'Free ads on other businesses’ pages',
      'إعلان مجاني في صفحات الأنشطة الأخرى');
  final n = fmtNum(p.maxBarbers, lang);
  final sh = fmtNum(p.maxShifts, lang);
  final staff = p.maxBarbers == 1
      ? _x(lang, 'یک نفر پرسنل', 'One staff member', 'موظف واحد')
      : p.maxBarbers > 0
          ? _x(lang, 'تا $n نفر پرسنل', 'Up to $n staff members',
              'حتى $n موظفين')
          : _x(lang, 'پرسنل نامحدود', 'Unlimited staff',
              'عدد غير محدود من الموظفين');
  final shifts = _x(
      lang,
      'تا $sh شیفت کاری در روز برای هر نفر',
      'Up to $sh work shifts a day per person',
      'حتى $sh فترات عمل يوميًا لكل شخص');
  switch (p.key) {
    case 'basic':
      return [
        staff,
        shifts,
        booking,
        bizList,
        adsPaid,
        _x(lang, 'پاکسازی هفتگی نوبت‌های گذشته',
            'Past bookings cleaned weekly', 'تنظيف الحجوزات القديمة أسبوعياً'),
      ];
    case 'pro':
      return [
        staff,
        shifts,
        booking,
        bizList,
        _x(lang, 'دکمه فروشگاه یا سایت با تا ۳ محصول',
            'Store/website button with up to 3 products',
            'زر المتجر أو الموقع مع حتى ٣ منتجات'),
        adsPaid,
        _x(lang, 'پاکسازی نوبت‌های گذشته هر دو هفته',
            'Past bookings cleaned every 2 weeks',
            'تنظيف الحجوزات القديمة كل أسبوعين'),
      ];
    case 'special':
      return [
        staff,
        shifts,
        booking,
        photo,
        _x(lang, 'ظاهر اختصاصی برای صفحه‌ی کسب‌وکار شما',
            'Custom look for your business page',
            'مظهر خاص لصفحة نشاطك'),
        winback,
        _x(lang, 'دکمه فروشگاه یا سایت با تا ۵ محصول (با عکس)',
            'Store/website button with up to 5 products (with photos)',
            'زر المتجر أو الموقع مع حتى ٥ منتجات (بصور)'),
        adsFree,
        _x(lang, 'فضای اختصاصی برای کسب‌وکار شما و پشتیبان‌گیری',
            'Dedicated space for your business, plus backups',
            'مساحة خاصة لنشاطك ونسخ احتياطي'),
        _x(lang, 'فعال‌سازی اختصاصی با کد راه‌اندازی',
            'Dedicated activation with a setup code',
            'تفعيل خاص برمز الإعداد'),
      ];
    default:
      return [
        _x(lang, 'راه‌اندازی توسط خود کسب‌وکار',
            'Set up by the business itself',
            'الإعداد يتولاه النشاط التجاري بنفسه'),
      ];
  }
}

class OwnerPlanPage extends StatelessWidget {
  const OwnerPlanPage({super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;

  @override
  Widget build(BuildContext context) {
    final lang = SettingsScope.of(context).lang;
    return GlassScaffold(
      title: _x(lang, 'انتخاب پلن', 'Choose a plan', 'اختيار الباقة'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              _x(
                  lang,
                  'اول پلن کسب‌وکارتان را انتخاب کنید',
                  'First, pick the plan for your business',
                  'اختر باقة نشاطك التجاري أولاً'),
              style: TextStyle(color: muted(context), height: 1.5),
            ),
          ),
          for (final p in kPlans) ...[
            _PlanCard(
              plan: p,
              lang: lang,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    OwnerSignupPage(api: api, onSession: onSession, plan: p),
              )),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.plan, required this.lang, required this.onTap});
  final PlanDef plan;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final feats = _planFeatures(lang, plan);
    return Glass(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIcon(_planIcon(plan.key), size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_planName(lang, plan.key),
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_planPrice(lang, plan),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(chevron(context), color: muted(context)),
            ],
          ),
          const SizedBox(height: 12),
          for (final f in feats)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: muted(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f,
                        style: TextStyle(color: muted(context), height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class OwnerSignupPage extends StatefulWidget {
  const OwnerSignupPage(
      {super.key,
      required this.api,
      required this.onSession,
      required this.plan});
  final ShopApi api;
  final SessionCallback onSession;
  final PlanDef plan;
  @override
  State<OwnerSignupPage> createState() => _OwnerSignupPageState();
}

class _OwnerSignupPageState extends State<OwnerSignupPage> {
  final _license = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _ownerName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _barber = true;
  bool _hide = true;
  bool _loading = false;
  String _gender = 'both';
  late List<Shift> _shifts;
  List<int> _daysOff = <int>[];

  bool get _planNeedsCode =>
      widget.plan.key == 'special' || widget.plan.key == 'personal';

  @override
  void initState() {
    super.initState();
    _shifts = parseShifts('09:00-13:00|16:00-20:00');
    final cap = widget.plan.maxShifts;
    if (_shifts.length > cap) _shifts = _shifts.sublist(0, cap);
  }

  @override
  void dispose() {
    for (final c in [
      _license, _shop, _phone, _ownerName, _address, _city, _user, _pass
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(T6 s) {
    if (_license.text.trim().isEmpty ||
        _shop.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _user.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      return s.t('v_required');
    }
    final digits =
        normalizeDigits(_phone.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) return s.t('v_phone');
    if (!usernameOk(_user.text)) return s.t('v_username');
    if (_pass.text.length < 6) return s.t('v_password');
    if (_barber) {
      final e = validateShifts(_shifts);
      if (e != null) return s.t(e);
    }
    return null;
  }

  Future<void> _submit() async {
    final st = SettingsScope.read(context);
    final lang = st.lang;
    final s = T6(lang);
    final err = _validate(s);
    if (err != null) {
      toast(context, err);
      return;
    }
    var licenseText = _license.text.trim();
    String? serverUrl;
    if (_planNeedsCode) {
      final p = splitActivation(_license.text);
      if (p.license.isEmpty || (p.url == null && !st.hasCustomApiUrl)) {
        toast(
            context,
            _x(lang, 'کد فعال‌سازی درست نیست', 'The activation code is not valid',
                'رمز التفعيل غير صحيح'));
        return;
      }
      licenseText = p.license;
      serverUrl = p.url;
    }
    final gender = _gender;
    final planKey = widget.plan.key;
    final onSession = widget.onSession;
    setState(() => _loading = true);
    try {
      final sess = await widget.api.register(
        licenseKey: licenseText,
        shopName: _shop.text,
        phone: _phone.text,
        username: _user.text,
        password: _pass.text,
        address: _address.text,
        city: _city.text,
        ownerName: _ownerName.text,
        ownerIsBarber: _barber,
        plan: planKey,
        shifts: _barber ? shiftsToString(_shifts) : '',
        daysOff: _barber ? _daysOff : null,
        serverUrl: serverUrl,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      await onSession(sess);
      _saveGender(st, gender, planKey, serverUrl);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } catch (_) {
      if (mounted) {
        toast(
            context,
            _x(
                lang,
                'اتصال برقرار نشد. کد و اینترنت را بررسی کنید',
                'Could not connect. Check the code and your internet',
                'تعذر الاتصال. تحقق من الرمز والإنترنت'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _genderBox(String lang) {
    final opts = <List<String>>[
      [
        'men',
        _x(lang, 'مردانه', 'Men', 'رجالي'),
      ],
      [
        'women',
        _x(lang, 'زنانه', 'Women', 'نسائي'),
      ],
      [
        'both',
        _x(lang, 'هر دو', 'Both', 'كلاهما'),
      ],
    ];
    return Glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _x(lang, 'کسب‌وکار شما برای چه کسانی است؟',
                  'Who is your business for?', 'لمن هذا النشاط التجاري؟'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in opts)
                ChoiceChip(
                  label: Text(o[1]),
                  selected: _gender == o[0],
                  onSelected: (_) => setState(() => _gender = o[0]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              _x(
                  lang,
                  'بعداً از «قوانین و زمان رزرو» قابل تغییر است',
                  'You can change this later in “Booking rules”',
                  'يمكن تغييره لاحقاً من «قواعد الحجز»'),
              style: TextStyle(color: muted(context), fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final lang = st.lang;
    final s = T6(lang);
    final order = lang == 'en'
        ? <int>[0, 1, 2, 3, 4, 5, 6]
        : <int>[6, 0, 1, 2, 3, 4, 5];
    final combined = _planNeedsCode && !st.hasCustomApiUrl;
    return GlassScaffold(
      title: _w(lang, s, 'signup_owner'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GradientIcon(_planIcon(widget.plan.key), size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${_x(lang, 'پلن شما', 'Your plan', 'باقتك')}: '
                          '${_planName(lang, widget.plan.key)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(_planPrice(lang, widget.plan),
                          style:
                              TextStyle(color: muted(context), fontSize: 13)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_x(lang, 'تغییر', 'Change', 'تغيير')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _license,
                  label: combined
                      ? _x(lang, 'کد فعال‌سازی', 'Activation code',
                          'رمز التفعيل')
                      : s.t('license_key'),
                  icon: Icons.vpn_key_rounded,
                  ltr: true,
                ),
                if (!combined) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                        _x(
                            lang,
                            'کد لایسنس باید مخصوص همین پلن باشد',
                            'The license code must be for this plan',
                            'يجب أن يكون رمز الترخيص لهذه الباقة'),
                        style: TextStyle(color: muted(context), fontSize: 12)),
                  ),
                ],
                _gap(),
                GlassField(
                  controller: _shop,
                  label: _w(lang, s, 'shop_name'),
                  icon: Icons.storefront_rounded,
                ),
                _gap(),
                GlassField(
                  controller: _phone,
                  label: s.t('phone'),
                  icon: Icons.phone_rounded,
                  keyboard: TextInputType.phone,
                  ltr: true,
                ),
                _gap(),
                GlassField(
                  controller: _city,
                  label: s.t('city'),
                  icon: Icons.location_city_rounded,
                ),
                _gap(),
                GlassField(
                  controller: _address,
                  label: s.t('address'),
                  icon: Icons.place_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _genderBox(lang),
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _ownerName,
                  label: s.t('owner_name'),
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _barber,
                  onChanged: (v) => setState(() => _barber = v),
                  title: Text(_w(lang, s, 'i_am_barber')),
                ),
              ],
            ),
          ),
          if (_barber) ...[
            const SizedBox(height: 16),
            Glass(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _x(lang, 'ساعت کاری شما', 'Your working hours',
                          'ساعات عملك'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ShiftsEditor(
                    shifts: _shifts,
                    max: widget.plan.maxShifts,
                    onChanged: (v) => setState(() => _shifts = v),
                  ),
                  const SizedBox(height: 18),
                  Text(
                      _x(lang, 'روزهای تعطیل هفتگی', 'Weekly days off',
                          'العطل الأسبوعية'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in order)
                        FilterChip(
                          label: Text(s.t('d_$d')),
                          selected: _daysOff.contains(d),
                          onSelected: (v) => setState(() {
                            final next = List<int>.from(_daysOff);
                            if (v) {
                              if (!next.contains(d)) next.add(d);
                            } else {
                              next.remove(d);
                            }
                            next.sort();
                            _daysOff = next;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                _gap(),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _w(lang, s, 'create_shop'),
            icon: Icons.check_circle_outline_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class StaffJoinPage extends StatefulWidget {
  const StaffJoinPage({super.key, required this.api, required this.onSession});
  final ShopApi api;
  final SessionCallback onSession;
  @override
  State<StaffJoinPage> createState() => _StaffJoinPageState();
}

class _StaffJoinPageState extends State<StaffJoinPage> {
  final _code = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = T6(SettingsScope.read(context).lang);
    if (_code.text.trim().isEmpty ||
        _user.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      toast(context, s.t('v_required'));
      return;
    }
    if (!usernameOk(_user.text)) {
      toast(context, s.t('v_username'));
      return;
    }
    if (_pass.text.length < 6) {
      toast(context, s.t('v_password'));
      return;
    }
    setState(() => _loading = true);
    try {
      final sess = await widget.api.join(_code.text, _user.text, _pass.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      await widget.onSession(sess);
    } on ApiException catch (e) {
      if (mounted) toast(context, s.error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = T6(SettingsScope.of(context).lang);
    return GlassScaffold(
      title: s.t('join_title'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                GlassField(
                  controller: _code,
                  label: s.t('invite_code'),
                  icon: Icons.confirmation_number_outlined,
                  ltr: true,
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _user,
                  label: s.t('username'),
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(s.t('username_hint'),
                      style: TextStyle(color: muted(context), fontSize: 12)),
                ),
                const SizedBox(height: 12),
                GlassField(
                  controller: _pass,
                  label: s.t('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  ltr: true,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: s.t('join_btn'),
                  icon: Icons.login_rounded,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
