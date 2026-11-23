import 'package:barber_core/barber_core.dart';

import 'strings_m.dart';

/// متن‌های بخش ۲. اگر کلیدی اینجا نباشد از M و بعد S خوانده می‌شود.
class T2 {
  T2(this.lang);
  final String lang;

  String t(String key, [Map<String, Object?>? args]) {
    final row = _d[key];
    if (row == null) return M(lang).t(key, args);
    final i = lang == 'fa' ? 0 : (lang == 'ar' ? 2 : 1);
    var r = row[i];
    if (args != null) {
      args.forEach((k, v) => r = r.replaceAll('{$k}', '$v'));
    }
    return r;
  }

  String error(Object e) =>
      e is ApiException ? M(lang).error(e) : M(lang).t('err_generic');
}

// ترتیب: [فارسی, English, العربية]
const Map<String, List<String>> _d = {
  'unit_min': ['دقیقه', 'min', 'دقيقة'],

  // روزهای هفته (۰ = یکشنبه ... ۶ = شنبه)
  'd_0': ['یکشنبه', 'Sun', 'الأحد'],
  'd_1': ['دوشنبه', 'Mon', 'الاثنين'],
  'd_2': ['سه‌شنبه', 'Tue', 'الثلاثاء'],
  'd_3': ['چهارشنبه', 'Wed', 'الأربعاء'],
  'd_4': ['پنجشنبه', 'Thu', 'الخميس'],
  'd_5': ['جمعه', 'Fri', 'الجمعة'],
  'd_6': ['شنبه', 'Sat', 'السبت'],

  // لیست آرایشگرها
  'sp_hours': ['ساعت کار', 'Hours', 'ساعات العمل'],
  'sp_days_off': ['تعطیل: {d}', 'Off: {d}', 'عطلة: {d}'],
  'sp_all_services': ['همه‌ی خدمات', 'All services', 'كل الخدمات'],
  'sp_services_n': ['{n} خدمت', '{n} service(s)', '{n} خدمة'],
  'sp_overtime': ['اضافه‌کار {n} دقیقه', 'Overtime {n} min', 'وقت إضافي {n} د'],

  // ویرایش آرایشگر
  'ed_title': ['ویرایش آرایشگر', 'Edit barber', 'تعديل الحلاق'],
  'ed_add_hint': [
    'فقط نام را بنویسید. ساعت کار و خدمات را در مرحله‌ی بعد تنظیم می‌کنید.',
    'Just type the name. You will set hours and services next.',
    'اكتب الاسم فقط. ستضبط ساعات العمل والخدمات في الخطوة التالية.',
  ],
  'ed_specialty': ['تخصص (اختیاری)', 'Specialty (optional)', 'التخصص (اختياري)'],
  'ed_services': ['خدمات این آرایشگر', 'Services of this barber', 'خدمات هذا الحلاق'],
  'ed_all_services': ['همه‌ی خدمات', 'All services', 'كل الخدمات'],
  'ed_all_services_hint': [
    'این آرایشگر همه‌ی خدمات آرایشگاه را انجام می‌دهد',
    'This barber does every service of the shop',
    'هذا الحلاق يقدّم كل خدمات الصالون',
  ],
  'ed_pick_services': [
    'خدماتی را که انجام می‌دهد انتخاب کنید',
    'Choose the services this barber does',
    'اختر الخدمات التي يقدّمها',
  ],
  'ed_no_services': [
    'هنوز خدمتی تعریف نشده. اول از بخش «خدمات» اضافه کنید.',
    'No services yet. Add some in the "Services" section first.',
    'لا توجد خدمات بعد. أضفها أولاً من قسم «الخدمات».',
  ],
  'ed_pick_at_least': [
    'حداقل یک خدمت انتخاب کنید',
    'Pick at least one service',
    'اختر خدمة واحدة على الأقل',
  ],
  'ed_hours': ['ساعت کاری', 'Working hours', 'ساعات العمل'],
  'ed_days_off': ['روزهای تعطیل هفتگی', 'Weekly days off', 'أيام العطلة الأسبوعية'],
  'ed_days_off_hint': [
    'در روزهای انتخاب‌شده برای این آرایشگر نوبت داده نمی‌شود',
    'No bookings are offered for this barber on the selected days',
    'لا تُعرض مواعيد لهذا الحلاق في الأيام المحددة',
  ],
  'ed_overtime': ['اضافه‌کار', 'Overtime', 'وقت إضافي'],
  'ed_overtime_default': [
    'مثل تنظیم آرایشگاه',
    'Same as shop setting',
    'مثل إعداد الصالون',
  ],
  'ed_overtime_hint': [
    'اگر خاموش کنید، برای این آرایشگر مقدار جداگانه می‌گذارید',
    'Turn off to set a separate value for this barber',
    'أوقفه لتحديد قيمة خاصة بهذا الحلاق',
  ],
  'ed_saved': ['ذخیره شد ✅', 'Saved ✅', 'تم الحفظ ✅'],
  'ed_bad_number': [
    'عدد واردشده درست نیست',
    'The number is not valid',
    'الرقم غير صحيح',
  ],

  // تنظیمات آرایشگاه
  'ss_title': ['تنظیمات آرایشگاه', 'Shop settings', 'إعدادات الصالون'],
  'ss_info': ['اطلاعات آرایشگاه', 'Shop info', 'معلومات الصالون'],
  'ss_description': ['توضیحات', 'Description', 'الوصف'],
  'ss_photo': ['لینک عکس (اختیاری)', 'Photo link (optional)', 'رابط الصورة (اختياري)'],
  'ss_currency': ['واحد پول', 'Currency', 'العملة'],
  'ss_booking': ['قوانین نوبت‌دهی', 'Booking rules', 'قواعد الحجز'],
  'ss_step': ['فاصله‌ی ساعت‌های نوبت', 'Slot interval', 'الفاصل بين المواعيد'],
  'ss_step_hint': [
    'مضرب ۵ بین ۵ تا ۱۲۰ دقیقه',
    'A multiple of 5, from 5 to 120 minutes',
    'من مضاعفات 5 بين 5 و120 دقيقة',
  ],
  'ss_buffer': ['فاصله بین دو نوبت', 'Gap between bookings', 'فاصل بين حجزين'],
  'ss_buffer_hint': [
    'استراحت کوتاه بعد از هر نوبت (دقیقه)',
    'A short break after each booking (minutes)',
    'استراحة قصيرة بعد كل حجز (دقائق)',
  ],
  'ss_overtime': ['اضافه‌کار پیش‌فرض', 'Default overtime', 'الوقت الإضافي الافتراضي'],
  'ss_overtime_hint': [
    'مثلاً پایان کار ۱۳:۰۰ و اضافه‌کار ۱۰ دقیقه: خدمت ۶۰ دقیقه‌ای تا ساعت ۱۲:۱۰ قابل شروع است.',
    'E.g. end 13:00 with 10 min overtime: a 60-min service can start by 12:10.',
    'مثلاً نهاية العمل 13:00 مع 10 دقائق إضافية: خدمة 60 دقيقة تبدأ حتى 12:10.',
  ],
  'ss_cancel': [
    'مهلت لغو توسط مشتری',
    'Customer cancellation window',
    'مهلة إلغاء الزبون',
  ],
  'ss_cancel_hint': [
    'مشتری تا این مقدار (دقیقه) قبل از نوبت می‌تواند لغو کند',
    'Customers can cancel up to this many minutes before the booking',
    'يستطيع الزبون الإلغاء قبل الموعد بهذا العدد من الدقائق',
  ],
  'ss_calendar': ['تقویم آرایشگاه', 'Shop calendar', 'تقويم الصالون'],
  'cal_jalali': ['شمسی', 'Jalali', 'هجري شمسي'],
  'cal_gregorian': ['میلادی', 'Gregorian', 'ميلادي'],
  'cal_hijri': ['قمری', 'Hijri', 'هجري قمري'],
  'ss_timezone': ['منطقه‌ی زمانی', 'Time zone', 'المنطقة الزمنية'],
  'ss_tz_hint': ['مثل Asia/Tehran', 'e.g. Asia/Tehran', 'مثل Asia/Tehran'],
  'ss_saved': ['تنظیمات ذخیره شد ✅', 'Settings saved ✅', 'تم حفظ الإعدادات ✅'],
  'ss_bad_step': [
    'فاصله‌ی ساعت‌ها باید مضرب ۵ بین ۵ تا ۱۲۰ باشد',
    'The interval must be a multiple of 5 from 5 to 120',
    'يجب أن يكون الفاصل من مضاعفات 5 بين 5 و120',
  ],
};
