// ===== تنظیم قیمت‌ها و پلن‌ها =====
// هر وقت خواستید قیمت یا تخفیف را عوض کنید فقط همین فایل را ویرایش کنید.
// قیمت‌های تومانی فقط نمایشی هستند. قیمت تتر (usdtMonthly) فقط برای نمایش است
// و قیمت واقعی را سرور حساب می‌کند (باید با Config سرور یکی باشد).
class PlanDef {
  const PlanDef({
    required this.key,
    required this.monthly,
    required this.oneTime,
    required this.maxBarbers,
    required this.maxShifts,
    required this.features,
    this.usdtMonthly = 0,
  });
  /// basic | pro | special | personal   (personal = پلن شخصی / خرید کامل برنامه)
  final String key;
  /// قیمت یک ماه به تومان (۰ یعنی رایگان)
  final int monthly;
  /// قیمت خرید یک‌باره (فقط پلن شخصی)؛ اگر ۰ باشد ماهانه حساب می‌شود
  final int oneTime;
  /// سقف پرسنل (۰ یعنی نامحدود)
  final int maxBarbers;
  /// سقف شیفت کاری هر نفر در روز
  final int maxShifts;
  /// کلید متن ویژگی‌ها (در strings_s5.dart)
  final List<String> features;
  /// قیمت یک ماه به تتر (عدد صحیح). ۰ یعنی با تتر فروخته نمی‌شود
  final int usdtMonthly;

  /// پرداخت خودکار با تتر
  bool get autoPay => usdtMonthly > 0;
}
const PlanDef _basic = PlanDef(
  key: 'basic',
  monthly: 0, // فعلاً رایگان
  oneTime: 0,
  usdtMonthly: 0, // وقتی پایه پولی شد اینجا 9 بگذارید (و در Config سرور هم price_basic_usdt = 9)
  maxBarbers: 1,
  maxShifts: 2,
  features: <String>[
    'pl_f_barber_one',
    'pl_f_shifts',
    'pl_f_booking',
    'pl_f_biz',
    'pl_f_ads_paid',
    'pl_f_cleanup7',
  ],
);
const PlanDef _pro = PlanDef(
  key: 'pro',
  monthly: 5000000,
  oneTime: 0,
  usdtMonthly: 19,
  maxBarbers: 5,
  maxShifts: 3,
  features: <String>[
    'pl_f_barbers',
    'pl_f_shifts',
    'pl_f_booking',
    'pl_f_biz',
    'pl_f_store_pro',
    'pl_f_ads_paid',
    'pl_f_cleanup14',
  ],
);
const PlanDef _special = PlanDef(
  key: 'special',
  monthly: 10000000,
  oneTime: 0,
  maxBarbers: 30,
  maxShifts: 5,
  features: <String>[
    'pl_f_barbers',
    'pl_f_shifts',
    'pl_f_booking',
    'pl_f_photo',
    'pl_f_theme',
    'pl_f_winback',
    'pl_f_store_sp',
    'pl_f_ads_free',
    'pl_f_ownsheet',
    'pl_f_backup',
    'pl_f_cleanup30',
  ],
);
// پلن شخصی (خرید کامل برنامه): آخرِ فهرست نمایش داده می‌شود
// فقط یک ویژگی نمایش داده می‌شود: راه‌اندازی توسط خود کسب‌وکار
const PlanDef _personal = PlanDef(
  key: 'personal',
  monthly: 0,
  oneTime: 30000000,
  maxBarbers: 0,
  maxShifts: 5,
  features: <String>[
    'pl_f_selfhost',
  ],
);
/// پلن‌هایی که به کاربر نشان داده می‌شود (پلن شخصی همیشه آخر است)
const List<PlanDef> kPlans = <PlanDef>[_basic, _pro, _special, _personal];
/// همه‌ی پلن‌ها
const List<PlanDef> kAllPlans = <PlanDef>[_basic, _pro, _special, _personal];
/// سقفِ شیفتِ یک پلن (برای ویرایشگر شیفت‌ها)
int shiftCapForPlan(String planKey) {
  for (final p in kAllPlans) {
    if (p.key == planKey) return p.maxShifts;
  }
  return 3;
}
/// مدت‌های قابل خرید (ماه)
const List<int> kMonthOptions = <int>[1, 3, 6, 9, 12];
/// درصد تخفیف هر مدت
const Map<int, int> kDiscountPercent = <int, int>{
  1: 0,
  3: 10,
  6: 15,
  9: 20,
  12: 25,
};
/// راه ارتباط برای خرید (شماره یا آیدی تلگرام و...). خالی بگذارید تا پیام عمومی نشان داده شود.
const String kPayContact = '';
/// قیمت نهایی (تومان) برای یک پلن ماهانه و تعداد ماه، گرد شده به هزار تومان
int planTotal(PlanDef p, int months) {
  final d = kDiscountPercent[months] ?? 0;
  final raw = p.monthly * months * (100 - d) ~/ 100;
  return (raw ~/ 1000) * 1000;
}
/// قیمت نهایی (تتر، عدد صحیح) برای نمایش؛ سرور هم دقیقاً همین فرمول را دارد
int planTotalUsdt(PlanDef p, int months) {
  final d = kDiscountPercent[months] ?? 0;
  final v = (p.usdtMonthly * months * (100 - d) + 50) ~/ 100;
  return v < 1 ? 1 : v;
}
