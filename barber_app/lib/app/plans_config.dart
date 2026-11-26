// ===== تنظیم قیمت‌ها و پلن‌ها =====
// هر وقت خواستید قیمت یا تخفیف را عوض کنید فقط همین فایل را ویرایش کنید.
// قیمت‌های تومانی و تتری فقط نمایشی هستند و قیمت واقعی را سرور حساب می‌کند
// (باید با Config سرور یکی باشد: price_*_usdt و price_*_toman).
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

  /// basic | pro | special
  final String key;

  /// قیمت یک ماه به تومان (۰ یعنی رایگان)
  final int monthly;

  /// قیمت خرید یک‌باره (دیگر استفاده نمی‌شود؛ برای سازگاری می‌ماند)
  final int oneTime;

  /// سقف پرسنل (۰ یعنی نامحدود)
  final int maxBarbers;

  /// سقف شیفت کاری هر نفر در روز
  final int maxShifts;

  /// کلید متن ویژگی‌ها (در strings_s5.dart)
  final List<String> features;

  /// قیمت یک ماه به تتر (عدد صحیح). ۰ یعنی با تتر فروخته نمی‌شود
  final int usdtMonthly;

  /// پرداخت آنلاین (تتر) فعال است؟
  bool get autoPay => usdtMonthly > 0;

  /// پرداخت کارت‌به‌کارت (تومان) فعال است؟
  bool get cardPay => autoPay && monthly > 0;
}

const PlanDef _basic = PlanDef(
  key: 'basic',
  monthly: 3000000,
  oneTime: 0,
  usdtMonthly: 9, // در Config سرور هم price_basic_usdt = 9
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
  usdtMonthly: 19, // در Config سرور هم price_pro_usdt = 19
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

/// پلن‌هایی که به کاربر نشان داده می‌شود
const List<PlanDef> kPlans = <PlanDef>[_basic, _pro, _special];

/// همه‌ی پلن‌ها
const List<PlanDef> kAllPlans = <PlanDef>[_basic, _pro, _special];

/// سقفِ شیفتِ یک پلن (برای ویرایشگر شیفت‌ها)
int shiftCapForPlan(String planKey) {
  // پلن شخصی از اپ حذف شده، ولی کاربران قدیمی آن روی سرور هنوز هستند
  if (planKey == 'personal') return 5;
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

/// ایمیل توسعه‌دهنده برای خرید پلن ویژه
const String kSupportEmail = 'EFMFIB.1373@gmail.com';

/// راه ارتباط برای خرید (قدیمی؛ برای سازگاری با فایل‌های دیگر می‌ماند)
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
