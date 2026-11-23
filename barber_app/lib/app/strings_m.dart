import 'package:barber_core/barber_core.dart';
import 'strings.dart';

/// متن‌های بخش مدیر و مشتری (فارسی، انگلیسی، عربی).
/// اگر کلیدی اینجا نبود، از S پرسیده می‌شود.
class M {
  M(this.lang);
  final String lang;

  String t(String key, [Map<String, Object?>? args]) {
    final row = _data[key];
    if (row == null) return S(lang).t(key, args);
    final i = lang == 'en' ? 1 : (lang == 'ar' ? 2 : 0);
    var v = i < row.length ? row[i] : row[0];
    if (args != null) {
      args.forEach((k, val) {
        v = v.replaceAll('{$k}', '$val');
      });
    }
    return v;
  }

  bool has(String key) => _data.containsKey(key) || S(lang).has(key);

  String error(ApiException e) {
    final k = 'err_${e.code}';
    if (_data.containsKey(k)) return t(k);
    return S(lang).error(e);
  }
}

const Map<String, List<String>> _data = {
  // ───── خطاهای جدید سرور ─────
  'err_BAD_DATE': ['تاریخ معتبر نیست', 'Invalid date', 'التاريخ غير صالح'],
  'err_BAD_URL': [
    'لینک باید با https شروع شود',
    'The link must start with https',
    'يجب أن يبدأ الرابط بـ https'
  ],
  'err_BAD_NUMBER': ['عدد واردشده معتبر نیست', 'Invalid number', 'الرقم غير صالح'],
  'err_TOO_MANY_SERVICES': [
    'تعداد خدمات انتخابی بیشتر از حد مجاز است',
    'Too many services selected',
    'عدد الخدمات المختارة أكبر من المسموح'
  ],
  'err_NOT_COMBINABLE': [
    'این خدمات با هم قابل ترکیب نیستند',
    'These services cannot be combined',
    'لا يمكن الجمع بين هذه الخدمات'
  ],
  'err_SLOT_TAKEN': [
    'این ساعت دیگر خالی نیست، ساعت دیگری انتخاب کنید',
    'This time is no longer free, please pick another',
    'هذا الوقت لم يعد متاحاً، اختر وقتاً آخر'
  ],
  'err_PAST_TIME': [
    'این زمان گذشته است',
    'This time has already passed',
    'هذا الوقت مضى'
  ],
  'err_TOO_FAR': [
    'این تاریخ بیش از حد دور است',
    'This date is too far ahead',
    'هذا التاريخ بعيد جداً'
  ],
  'err_CANCEL_TOO_LATE': [
    'مهلت لغو این نوبت تمام شده است',
    'The cancellation window has passed',
    'انتهت مهلة إلغاء هذا الموعد'
  ],
  'err_CHECKIN_NOT_ALLOWED': [
    'الان نمی‌توانید «نشستم» را بزنید',
    "You can't check in right now",
    'لا يمكنك تأكيد الحضور الآن'
  ],
  'err_RATE_NOT_ALLOWED': [
    'امتیازدهی برای این نوبت ممکن نیست',
    'Rating is not possible for this booking',
    'لا يمكن التقييم لهذا الموعد'
  ],
  'err_TOO_EARLY': [
    'هنوز وقت نوبت نشده است',
    'It is not time for this booking yet',
    'لم يحن وقت الموعد بعد'
  ],
  'err_DAILY_CAP': [
    'سقف روزانه‌ی این کار پر شده است',
    'The daily limit for this action has been reached',
    'تم بلوغ الحد اليومي لهذا الإجراء'
  ],
  'err_ACTIVE_LIMIT': [
    'تعداد نوبت‌های فعال شما به سقف رسیده است',
    'You have reached the limit of active bookings',
    'وصلت إلى الحد الأقصى للمواعيد النشطة'
  ],
  'err_PLAN_REQUIRED': [
    'این امکان فقط برای پلن ویژه است',
    'This feature is only for the Special plan',
    'هذه الميزة للخطة المميزة فقط'
  ],
  'err_SERVICE_LIMIT': [
    'تعداد خدمات به سقف رسیده است',
    'The number of services has reached the limit',
    'وصل عدد الخدمات إلى الحد الأقصى'
  ],
  'err_BAD_STATE': [
    'وضعیت نوبت اجازه‌ی این کار را نمی‌دهد',
    'The booking status does not allow this',
    'حالة الموعد لا تسمح بذلك'
  ],

  // ───── عمومی ─────
  'cur_default': ['تومان', '', ''],
  'min_unit': ['دقیقه', 'min', 'دقيقة'],

  // ───── خدمات ─────
  'svc_title': ['خدمات آرایشگاه', 'Shop services', 'خدمات الصالون'],
  'svc_add': ['افزودن خدمت', 'Add service', 'إضافة خدمة'],
  'svc_edit': ['ویرایش خدمت', 'Edit service', 'تعديل الخدمة'],
  'svc_empty': [
    'هنوز خدمتی ثبت نشده. با دکمه‌ی پایین اولین خدمت را اضافه کن.',
    'No services yet. Use the button below to add the first one.',
    'لا توجد خدمات بعد. استخدم الزر بالأسفل لإضافة أول خدمة.'
  ],
  'svc_name': ['نام خدمت', 'Service name', 'اسم الخدمة'],
  'svc_duration': ['مدت (دقیقه)', 'Duration (min)', 'المدة (دقيقة)'],
  'svc_price': ['قیمت', 'Price', 'السعر'],
  'svc_combinable': ['قابل ترکیب با', 'Can be combined with', 'يمكن دمجها مع'],
  'svc_combinable_hint': [
    'اگر مشتری چند خدمت را با هم بخواهد، فقط خدماتی که اینجا تیک بزنی با هم انتخاب می‌شوند.',
    'When a customer books several services together, only the ones ticked here can be combined.',
    'عند حجز عدة خدمات معاً، تُدمج فقط الخدمات المحددة هنا.'
  ],
  'svc_no_others': [
    'خدمت دیگری برای ترکیب وجود ندارد',
    'No other service to combine with',
    'لا توجد خدمة أخرى للدمج'
  ],
  'svc_saved': ['خدمت ذخیره شد', 'Service saved', 'تم حفظ الخدمة'],
  'svc_removed': ['خدمت حذف شد', 'Service removed', 'تم حذف الخدمة'],
  'svc_remove_confirm': [
    'این خدمت حذف شود؟ نوبت‌های قبلی تغییری نمی‌کنند.',
    'Remove this service? Existing bookings are not affected.',
    'حذف هذه الخدمة؟ المواعيد السابقة لا تتأثر.'
  ],
  'svc_bad_duration': [
    'مدت خدمت باید بین ۵ تا ۴۸۰ دقیقه باشد',
    'Duration must be between 5 and 480 minutes',
    'يجب أن تكون المدة بين 5 و480 دقيقة'
  ],
  'svc_quick': ['مدت سریع', 'Quick duration', 'مدة سريعة'],
};
