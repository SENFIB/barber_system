// ===== تنظیم قیمت‌ها و پلن‌ها =====
// هر وقت خواستید قیمت یا تخفیف را عوض کنید فقط همین فایل را ویرایش کنید.
// همه‌ی قیمت‌ها به تومان هستند.

class PlanDef {
  const PlanDef({
    required this.key,
    required this.monthly,
    required this.oneTime,
    required this.maxBarbers,
    required this.features,
  });

  /// basic | pro | special | personal
  final String key;

  /// قیمت یک ماه (۰ یعنی رایگان)
  final int monthly;

  /// قیمت خرید یک‌باره (فقط پلن شخصی)؛ اگر ۰ باشد ماهانه حساب می‌شود
  final int oneTime;

  /// سقف باربر (۰ یعنی نامحدود)
  final int maxBarbers;

  /// کلید متن ویژگی‌ها (در strings_s5.dart)
  final List<String> features;
}

const List<PlanDef> kPlans = <PlanDef>[
  PlanDef(
    key: 'basic',
    monthly: 0, // فعلاً رایگان
    oneTime: 0,
    maxBarbers: 2,
    features: <String>['pl_f_barbers', 'pl_f_booking', 'pl_f_cleanup7'],
  ),
  PlanDef(
    key: 'pro',
    monthly: 5000000,
    oneTime: 0,
    maxBarbers: 5,
    features: <String>['pl_f_barbers', 'pl_f_booking', 'pl_f_cleanup14'],
  ),
  PlanDef(
    key: 'special',
    monthly: 10000000,
    oneTime: 0,
    maxBarbers: 30,
    features: <String>[
      'pl_f_barbers',
      'pl_f_booking',
      'pl_f_photo',
      'pl_f_winback',
      'pl_f_ownsheet',
      'pl_f_backup',
      'pl_f_cleanup30',
    ],
  ),
  PlanDef(
    key: 'personal',
    monthly: 0,
    oneTime: 30000000,
    maxBarbers: 0,
    features: <String>[
      'pl_f_barbers_any',
      'pl_f_booking',
      'pl_f_photo',
      'pl_f_winback',
      'pl_f_ownserver',
    ],
  ),
];

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
