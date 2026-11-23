import 'strings_s3.dart';

class T4 {
  T4(this.lang) : _p = T3(lang);
  final String lang;
  final T3 _p;

  static const Map<String, Map<String, String>> _m = {
    'fa': {
      'cu_tab_shops': 'آرایشگاه‌ها',
      'cu_tab_mine': 'نوبت‌های من',
      'cu_search': 'جستجوی آرایشگاه (نام یا شهر)',
      'cu_no_shops': 'آرایشگاهی پیدا نشد',
      'cu_new': 'جدید',
      'cu_reviews': '{n} نظر',
      'cu_services': 'خدمات',
      'cu_no_services': 'این آرایشگاه هنوز خدمتی ثبت نکرده',
      'cu_pick': 'خدمت‌های دلخواه را انتخاب کنید',
      'cu_your_name': 'نام شما',
      'cu_your_phone': 'شماره تلفن شما',
      'cu_saved_note': 'نام و شماره‌ی شما فقط روی همین دستگاه ذخیره می‌شود',
      'cu_book': 'ثبت نوبت',
      'cu_booked_ok': 'نوبت شما ثبت شد ✅',
      'cu_need_name': 'نام خود را بنویسید',
      'cu_need_phone': 'شماره تلفن خود را بنویسید',
      'cu_total': 'جمع',
      'cu_summary': 'خلاصه‌ی نوبت',
      'cu_policy': 'لغو نوبت تا {t} قبل از زمان نوبت ممکن است',
      'cu_h': '{n} ساعت',
      'cu_m': '{n} دقیقه',
      'cu_mine_empty': 'هنوز نوبتی ندارید',
      'cu_upcoming': 'نوبت‌های فعال',
      'cu_past': 'گذشته',
      'cu_cancel': 'لغو نوبت',
      'cu_cancel_q': 'این نوبت لغو شود؟ اگر چند خدمت دارد، همه‌ی آن‌ها لغو می‌شود.',
      'cu_cancel_yes': 'بله، لغو شود',
      'cu_checkin': 'روی صندلی نشستم',
      'cu_checkin_q': 'روی صندلی آرایشگر نشسته‌اید؟',
      'cu_checkin_yes': 'بله، نشستم',
      'cu_rate': 'امتیاز دادن',
      'cu_rate_title': 'به آرایشگر امتیاز بدهید',
      'cu_rate_note': 'امتیاز شما ناشناس است',
      'cu_rate_send': 'ثبت امتیاز',
      'cu_rate_all': 'برای همه‌ی ردیف‌ها امتیاز بدهید',
      'cu_rate_thanks': 'ممنون از امتیازتان',
      'cu_late': 'زمان لغو این نوبت گذشته؛ با آرایشگاه تماس بگیرید',
    },
    'en': {
      'cu_tab_shops': 'Shops',
      'cu_tab_mine': 'My bookings',
      'cu_search': 'Search shops (name or city)',
      'cu_no_shops': 'No shops found',
      'cu_new': 'New',
      'cu_reviews': '{n} reviews',
      'cu_services': 'Services',
      'cu_no_services': 'This shop has not added any services yet',
      'cu_pick': 'Choose the services you want',
      'cu_your_name': 'Your name',
      'cu_your_phone': 'Your phone number',
      'cu_saved_note': 'Your name and number are stored only on this device',
      'cu_book': 'Book now',
      'cu_booked_ok': 'Your booking is confirmed ✅',
      'cu_need_name': 'Enter your name',
      'cu_need_phone': 'Enter your phone number',
      'cu_total': 'Total',
      'cu_summary': 'Booking summary',
      'cu_policy': 'You can cancel up to {t} before the appointment',
      'cu_h': '{n} h',
      'cu_m': '{n} min',
      'cu_mine_empty': 'You have no bookings yet',
      'cu_upcoming': 'Active bookings',
      'cu_past': 'Past',
      'cu_cancel': 'Cancel booking',
      'cu_cancel_q': 'Cancel this booking? If it has several services, all of them will be cancelled.',
      'cu_cancel_yes': 'Yes, cancel',
      'cu_checkin': 'I sat down',
      'cu_checkin_q': "Are you sitting in the barber's chair?",
      'cu_checkin_yes': 'Yes, I sat down',
      'cu_rate': 'Rate',
      'cu_rate_title': 'Rate your barber',
      'cu_rate_note': 'Your rating is anonymous',
      'cu_rate_send': 'Submit rating',
      'cu_rate_all': 'Please rate every row',
      'cu_rate_thanks': 'Thanks for your rating',
      'cu_late': 'The cancellation time has passed; please contact the shop',
    },
    'ar': {
      'cu_tab_shops': 'الصالونات',
      'cu_tab_mine': 'حجوزاتي',
      'cu_search': 'ابحث عن صالون (الاسم أو المدينة)',
      'cu_no_shops': 'لم يتم العثور على صالون',
      'cu_new': 'جديد',
      'cu_reviews': '{n} تقييم',
      'cu_services': 'الخدمات',
      'cu_no_services': 'لم يضف هذا الصالون خدمات بعد',
      'cu_pick': 'اختر الخدمات التي تريدها',
      'cu_your_name': 'اسمك',
      'cu_your_phone': 'رقم هاتفك',
      'cu_saved_note': 'يُحفظ اسمك ورقمك على هذا الجهاز فقط',
      'cu_book': 'تأكيد الحجز',
      'cu_booked_ok': 'تم تسجيل حجزك ✅',
      'cu_need_name': 'اكتب اسمك',
      'cu_need_phone': 'اكتب رقم هاتفك',
      'cu_total': 'المجموع',
      'cu_summary': 'ملخص الحجز',
      'cu_policy': 'يمكنك إلغاء الحجز حتى {t} قبل الموعد',
      'cu_h': '{n} ساعة',
      'cu_m': '{n} دقيقة',
      'cu_mine_empty': 'ليس لديك حجوزات بعد',
      'cu_upcoming': 'الحجوزات الحالية',
      'cu_past': 'السابقة',
      'cu_cancel': 'إلغاء الحجز',
      'cu_cancel_q': 'هل تريد إلغاء هذا الحجز؟ إذا كان فيه عدة خدمات فسيتم إلغاؤها كلها.',
      'cu_cancel_yes': 'نعم، إلغاء',
      'cu_checkin': 'جلست على الكرسي',
      'cu_checkin_q': 'هل جلستَ على كرسي الحلاق؟',
      'cu_checkin_yes': 'نعم، جلست',
      'cu_rate': 'تقييم',
      'cu_rate_title': 'قيّم الحلاق',
      'cu_rate_note': 'تقييمك مجهول الهوية',
      'cu_rate_send': 'إرسال التقييم',
      'cu_rate_all': 'يرجى تقييم كل الصفوف',
      'cu_rate_thanks': 'شكرًا على تقييمك',
      'cu_late': 'انتهى وقت الإلغاء؛ يرجى التواصل مع الصالون',
    },
  };

  String t(String key, [Map<String, String>? args]) {
    final m = _m[lang] ?? _m['en']!;
    final v = m[key] ?? _m['en']![key];
    if (v == null) return _p.t(key, args);
    var out = v;
    if (args != null) {
      for (final e in args.entries) {
        out = out.replaceAll('{${e.key}}', e.value);
      }
    }
    return out;
  }

  String error(Object e) => _p.error(e);
}
