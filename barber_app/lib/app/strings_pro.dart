import 'package:barber_core/barber_core.dart';
import 'strings.dart';

/// متن‌های بخش مشتری و مدیر (فارسی، انگلیسی، عربی)
class Z {
  const Z(this.lang);
  final String lang;

  int get _i => lang == 'en' ? 1 : (lang == 'ar' ? 2 : 0);

  bool has(String k) => _d.containsKey(k);

  String t(String k, [Map<String, dynamic>? a]) {
    final v = _d[k];
    if (v == null) return k;
    var s = v[_i];
    a?.forEach((key, val) {
      s = s.replaceAll('{$key}', '$val');
    });
    return s;
  }

  String error(ApiException e) =>
      has('err_${e.code}') ? t('err_${e.code}') : S(lang).error(e);

  static const Map<String, List<String>> _d = {
    // عمومی
    'retry': ['تلاش دوباره', 'Retry', 'إعادة المحاولة'],
    'cancel': ['انصراف', 'Cancel', 'إلغاء'],
    'save': ['ذخیره', 'Save', 'حفظ'],
    'saved': ['ذخیره شد', 'Saved', 'تم الحفظ'],
    'edit': ['ویرایش', 'Edit', 'تعديل'],
    'add': ['افزودن', 'Add', 'إضافة'],
    'remove': ['حذف', 'Delete', 'حذف'],
    'ok': ['باشه', 'OK', 'حسنًا'],
    'copied': ['کپی شد', 'Copied', 'تم النسخ'],
    'min': ['دقیقه', 'min', 'دقيقة'],
    'today': ['امروز', 'Today', 'اليوم'],
    'calendar': ['تقویم', 'Calendar', 'التقويم'],
    'cal_jalali': ['شمسی (جلالی)', 'Jalali (Persian)', 'الشمسي (الفارسي)'],
    'cal_gregorian': ['میلادی', 'Gregorian', 'الميلادي'],
    'cal_hijri': ['قمری (هجری)', 'Hijri (Islamic)', 'الهجري'],
    'upd_available': ['نسخه‌ی جدیدتری از برنامه منتشر شده است', 'A newer version of the app is available', 'يتوفر إصدار أحدث من التطبيق'],
    'upd_required': ['این نسخه قدیمی است و باید به‌روز شود', 'This version is outdated and must be updated', 'هذا الإصدار قديم ويجب تحديثه'],
    'shop_time': ['ساعت‌ها به وقت آرایشگاه است', 'Times are in the shop local time', 'الأوقات حسب توقيت المحل'],
    'shop_name': ['نام آرایشگاه', 'Shop name', 'اسم المحل'],
    'phone': ['تلفن', 'Phone', 'الهاتف'],
    'city': ['شهر', 'City', 'المدينة'],
    'address': ['نشانی', 'Address', 'العنوان'],
    'barber_name': ['نام آرایشگر', 'Barber name', 'اسم الحلاق'],
    'specialty': ['تخصص (اختیاری)', 'Specialty (optional)', 'التخصص (اختياري)'],
    'work_start': ['شروع کار', 'Start', 'بداية العمل'],
    'work_end': ['پایان کار', 'End', 'نهاية العمل'],

    // مشتری
    'tab_shops': ['آرایشگاه‌ها', 'Shops', 'المحلات'],
    'tab_bookings': ['نوبت‌های من', 'My bookings', 'حجوزاتي'],
    'search_shops': ['جستجوی آرایشگاه (نام یا شهر)', 'Search shops (name or city)', 'ابحث عن محل (الاسم أو المدينة)'],
    'no_shops': ['آرایشگاهی پیدا نشد', 'No shops found', 'لا توجد محلات'],
    'choose_services': ['خدمت یا خدمات را انتخاب کنید', 'Choose service(s)', 'اختر الخدمة أو الخدمات'],
    'max_services': ['حداکثر {n} خدمت', 'At most {n} services', 'الحد الأقصى {n} خدمات'],
    'not_combinable': ['این خدمت با انتخاب‌های فعلی قابل ترکیب نیست', 'This service cannot be combined with the current selection', 'لا يمكن دمج هذه الخدمة مع الاختيار الحالي'],
    'barber_for': ['آرایشگر برای', 'Barber for', 'الحلاق لـ'],
    'any_barber': ['هرکسی', 'Anyone', 'أي حلاق'],
    'choose_day': ['روز را انتخاب کنید', 'Choose a day', 'اختر اليوم'],
    'free_times': ['ساعت‌های خالی', 'Free times', 'الأوقات المتاحة'],
    'no_slots': ['در این روز ساعت خالی نیست', 'No free time on this day', 'لا توجد أوقات متاحة في هذا اليوم'],
    'your_name': ['نام شما', 'Your name', 'اسمك'],
    'your_phone': ['شماره‌ی تماس شما', 'Your phone', 'رقم هاتفك'],
    'book_now': ['ثبت نوبت', 'Book', 'تأكيد الحجز'],
    'book_title': ['تأیید نوبت', 'Confirm booking', 'تأكيد الحجز'],
    'total': ['جمع', 'Total', 'المجموع'],
    'booked_ok': ['نوبت ثبت شد ✅', 'Booked ✅', 'تم الحجز ✅'],
    'booked_ok_msg': ['{when}\nدر «نوبت‌های من» می‌توانید آن را ببینید', '{when}\nYou can see it in My bookings', '{when}\nيمكنك رؤيته في حجوزاتي'],
    'no_bookings': ['هنوز نوبتی ندارید', 'No bookings yet', 'لا توجد حجوزات بعد'],
    'st_booked': ['رزرو شده', 'Booked', 'محجوز'],
    'st_checked_in': ['نشسته', 'Seated', 'جالس'],
    'st_finished': ['انجام شد', 'Done', 'تم'],
    'st_cancelled': ['لغو شده', 'Cancelled', 'ملغي'],
    'st_no_show': ['نیامد', 'No-show', 'لم يحضر'],
    'b_cancel': ['لغو نوبت', 'Cancel booking', 'إلغاء الحجز'],
    'b_cancel_confirm': ['این نوبت لغو شود؟', 'Cancel this booking?', 'هل تريد إلغاء هذا الحجز؟'],
    'b_cancelled': ['نوبت لغو شد', 'Booking cancelled', 'تم إلغاء الحجز'],
    'b_checkin': ['نشستم', 'I sat down', 'جلست'],
    'b_checkin_done': ['ثبت شد', 'Recorded', 'تم التسجيل'],
    'b_rate': ['امتیاز دادن', 'Rate', 'قيّم'],
    'b_rate_title': ['به آرایشگر امتیاز بدهید', 'Rate your barber', 'قيّم الحلاق'],
    'b_rate_hint': ['امتیاز شما ناشناس است', 'Your rating is anonymous', 'تقييمك مجهول'],
    'b_rate_done': ['امتیاز ثبت شد، ممنون', 'Thanks for rating', 'شكرًا على تقييمك'],
    'cancel_deadline': ['لغو تا {n} دقیقه قبل از نوبت ممکن است', 'Cancellation is allowed up to {n} min before', 'يمكن الإلغاء حتى {n} دقيقة قبل الموعد'],

    // مدیر: صفحه‌ی اصلی
    'm_timeoff': ['مرخصی و تعطیلی', 'Time off', 'الإجازات'],
    'm_timeoff_desc': ['بستن یک روز یا چند ساعت', 'Close a day or some hours', 'إغلاق يوم أو ساعات'],
    'm_shop': ['تنظیمات آرایشگاه', 'Shop settings', 'إعدادات المحل'],
    'm_shop_desc': ['مشخصات و قوانین نوبت‌دهی', 'Info and booking rules', 'البيانات وقواعد الحجز'],
    'm_barbers_desc': ['ساعت کاری، خدمات و روز تعطیل هر آرایشگر', 'Hours, services and days off per barber', 'ساعات وخدمات وأيام عطلة كل حلاق'],

    // مدیر: نوبت‌ها
    'filter_all': ['همه', 'All', 'الكل'],
    'bk_none': ['برای این روز نوبتی نیست', 'No bookings for this day', 'لا توجد حجوزات لهذا اليوم'],
    'bk_done': ['انجام شد', 'Done', 'تم'],
    'bk_noshow': ['نیامد', 'No-show', 'لم يحضر'],
    'bk_cancel': ['لغو', 'Cancel', 'إلغاء'],
    'bk_cancel_confirm': ['این نوبت لغو شود؟', 'Cancel this booking?', 'هل تريد إلغاء الحجز؟'],
    'bk_saved': ['ثبت شد', 'Saved', 'تم'],
    'bk_cancelled': ['لغو شد', 'Cancelled', 'تم الإلغاء'],
    'src_manual': ['تلفنی', 'Phone', 'هاتفي'],
    'manual_title': ['نوبت دستی', 'Manual booking', 'حجز يدوي'],
    'c_name_opt': ['نام مشتری (اختیاری)', 'Customer name (optional)', 'اسم الزبون (اختياري)'],
    'c_phone_opt': ['شماره‌ی مشتری (اختیاری)', 'Customer phone (optional)', 'هاتف الزبون (اختياري)'],
    'book_confirm': ['این نوبت ثبت شود؟', 'Create this booking?', 'هل تريد تسجيل هذا الحجز؟'],
    'mb_ok': ['نوبت ثبت شد', 'Booking created', 'تم تسجيل الحجز'],

    // خدمات
    'svc_add': ['افزودن خدمت', 'Add service', 'إضافة خدمة'],
    'svc_edit': ['ویرایش خدمت', 'Edit service', 'تعديل الخدمة'],
    'svc_name': ['نام خدمت', 'Service name', 'اسم الخدمة'],
    'svc_duration': ['مدت (دقیقه)', 'Duration (minutes)', 'المدة (دقائق)'],
    'svc_price': ['قیمت', 'Price', 'السعر'],
    'svc_comb': ['قابل ترکیب با', 'Can be combined with', 'يمكن دمجها مع'],
    'svc_comb_hint': ['مشتری می‌تواند خدمات ترکیب‌پذیر را با هم رزرو کند (هر خدمت با آرایشگر خودش)', 'Customers can book combinable services together (each with its own barber)', 'يمكن للزبون حجز الخدمات القابلة للدمج معًا (لكل خدمة حلاقها)'],
    'svc_none': ['هنوز خدمتی تعریف نشده', 'No services yet', 'لا توجد خدمات بعد'],
    'svc_removed': ['خدمت حذف شد', 'Service deleted', 'تم حذف الخدمة'],
    'svc_remove_confirm': ['این خدمت حذف شود؟', 'Delete this service?', 'هل تريد حذف هذه الخدمة؟'],

    // ویرایش آرایشگر
    'se_title': ['ویرایش آرایشگر', 'Edit barber', 'تعديل الحلاق'],
    'se_hours': ['ساعت کاری', 'Working hours', 'ساعات العمل'],
    'se_days_off': ['روزهای تعطیل هفتگی', 'Weekly days off', 'أيام العطلة الأسبوعية'],
    'se_services': ['خدماتی که انجام می‌دهد', 'Services this barber does', 'الخدمات التي يقدمها'],
    'se_all': ['همه‌ی خدمات', 'All services', 'كل الخدمات'],
    'se_overtime': ['اضافه‌کار مخصوص این آرایشگر', 'Overtime just for this barber', 'وقت إضافي لهذا الحلاق'],
    'se_overtime_min': ['دقیقه اضافه‌کار', 'Overtime minutes', 'دقائق الوقت الإضافي'],
    'se_overtime_hint': ['اگر خاموش باشد، عدد کلی آرایشگاه اعمال می‌شود', 'If off, the shop-wide value applies', 'إن كان معطلاً تُطبق قيمة المحل'],
    'se_no_services': ['ابتدا از بخش «خدمات» خدمت تعریف کنید', 'Define services first', 'عرّف الخدمات أولاً'],

    // مرخصی
    'to_title': ['مرخصی و تعطیلی', 'Time off', 'الإجازات'],
    'to_add': ['ثبت مرخصی / تعطیلی', 'Add time off', 'إضافة إجازة'],
    'to_from': ['از تاریخ', 'From', 'من تاريخ'],
    'to_to': ['تا تاریخ', 'To', 'إلى تاريخ'],
    'to_whole_day': ['کل روز', 'Whole day', 'اليوم كاملًا'],
    'to_whole_shop': ['کل آرایشگاه', 'Whole shop', 'كل المحل'],
    'to_reason': ['دلیل (اختیاری)', 'Reason (optional)', 'السبب (اختياري)'],
    'to_none': ['مرخصی یا تعطیلی ثبت نشده', 'No time off', 'لا توجد إجازات'],
    'to_conflicts': ['{n} نوبت در این بازه هست. خودکار لغو نشده‌اند؛ خودتان بررسی کنید', '{n} booking(s) fall in this range. They were NOT cancelled automatically', 'يوجد {n} حجز في هذه الفترة ولم تُلغَ تلقائيًا'],
    'to_added': ['ثبت شد', 'Saved', 'تم'],
    'to_removed': ['حذف شد', 'Deleted', 'تم الحذف'],
    'to_remove_confirm': ['این مورد حذف شود؟', 'Delete this entry?', 'هل تريد حذف هذا؟'],

    // تنظیمات آرایشگاه
    'ss_title': ['تنظیمات آرایشگاه', 'Shop settings', 'إعدادات المحل'],
    'ss_rules': ['قوانین نوبت‌دهی', 'Booking rules', 'قواعد الحجز'],
    'f_description': ['توضیحات', 'Description', 'الوصف'],
    'f_photo': ['لینک عکس (https)', 'Photo link (https)', 'رابط الصورة (https)'],
    'f_currency': ['واحد پول', 'Currency', 'العملة'],
    'f_buffer': ['فاصله بین نوبت‌ها (دقیقه)', 'Gap between bookings (min)', 'الفاصل بين الحجوزات (دقائق)'],
    'f_overtime': ['اضافه‌کار مجاز بعد از پایان کار (دقیقه)', 'Allowed overtime after closing (min)', 'الوقت الإضافي المسموح بعد الإغلاق (دقائق)'],
    'f_cancel': ['مهلت لغو توسط مشتری (دقیقه قبل از نوبت)', 'Customer cancel deadline (min before)', 'مهلة الإلغاء للزبون (دقائق قبل الموعد)'],
    'f_step': ['فاصله‌ی شروع نوبت‌ها (مضرب ۵)', 'Slot step (multiple of 5)', 'خطوة المواعيد (مضاعف 5)'],
    'f_calendar': ['تقویم آرایشگاه', 'Shop calendar', 'تقويم المحل'],
    'f_timezone': ['منطقه‌ی زمانی', 'Time zone', 'المنطقة الزمنية'],

    // خطاها
    'err_BAD_NAME': ['نام معتبر نیست', 'Invalid name', 'الاسم غير صالح'],
    'err_BAD_PHONE': ['شماره تلفن معتبر نیست', 'Invalid phone number', 'رقم الهاتف غير صالح'],
    'err_BAD_DATE': ['تاریخ معتبر نیست', 'Invalid date', 'التاريخ غير صالح'],
    'err_BAD_URL': ['لینک باید با https شروع شود', 'The link must start with https', 'يجب أن يبدأ الرابط بـ https'],
    'err_BAD_NUMBER': ['عدد واردشده معتبر نیست', 'Invalid number', 'الرقم غير صالح'],
    'err_TOO_MANY_SERVICES': ['تعداد خدمات انتخابی بیشتر از حد مجاز است', 'Too many services selected', 'عدد الخدمات المختارة أكثر من المسموح'],
    'err_NOT_COMBINABLE': ['این خدمات با هم قابل ترکیب نیستند', 'These services cannot be combined', 'لا يمكن دمج هذه الخدمات'],
    'err_SLOT_TAKEN': ['این ساعت دیگر خالی نیست، ساعت دیگری انتخاب کنید', 'This time is no longer free, pick another', 'هذا الوقت لم يعد متاحًا، اختر وقتًا آخر'],
    'err_PAST_TIME': ['این زمان گذشته است', 'This time has passed', 'هذا الوقت مضى'],
    'err_TOO_FAR': ['این تاریخ بیش از حد دور است', 'This date is too far ahead', 'هذا التاريخ بعيد جدًا'],
    'err_CANCEL_TOO_LATE': ['مهلت لغو این نوبت تمام شده است', 'The cancellation deadline has passed', 'انتهت مهلة إلغاء هذا الحجز'],
    'err_CHECKIN_NOT_ALLOWED': ['الان نمی‌توانید «نشستم» را بزنید', 'You cannot check in right now', 'لا يمكنك تسجيل الجلوس الآن'],
    'err_RATE_NOT_ALLOWED': ['امتیازدهی برای این نوبت ممکن نیست', 'Rating is not possible for this booking', 'التقييم غير ممكن لهذا الحجز'],
    'err_TOO_EARLY': ['هنوز وقت نوبت نشده است', 'It is not time yet', 'لم يحن الموعد بعد'],
    'err_DAILY_CAP': ['سقف روزانه پر شده است', 'Daily limit reached', 'تم بلوغ الحد اليومي'],
    'err_ACTIVE_LIMIT': ['تعداد نوبت‌های فعال شما به سقف رسیده است', 'You have too many active bookings', 'وصلت إلى الحد الأقصى للحجوزات النشطة'],
    'err_PLAN_REQUIRED': ['این امکان فقط برای پلن ویژه است', 'This needs the Special plan', 'هذه الميزة للخطة المميزة فقط'],
    'err_SERVICE_LIMIT': ['تعداد خدمات به سقف رسیده است', 'Service limit reached', 'تم بلوغ حد الخدمات'],
    'err_BAD_STATE': ['وضعیت نوبت اجازه‌ی این کار را نمی‌دهد', 'The booking state does not allow this', 'حالة الحجز لا تسمح بذلك'],
  };
}
