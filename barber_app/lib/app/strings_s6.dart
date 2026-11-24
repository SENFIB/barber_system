import 'package:barber_core/barber_core.dart';
import 'fmt.dart';
import 'strings_s5.dart';
/// جایگزینی واژه‌ی «باربر» با معادل درست هر زبان (جمع‌ها اول)
const Map<String, List<List<String>>> _termFix = {
  'fa': [
    ['باربرها', 'آرایشگرها'],
    ['باربران', 'آرایشگران'],
    ['باربر', 'آرایشگر'],
  ],
  'ar': [
    ['باربرها', 'حلاقين'],
    ['باربران', 'حلاقين'],
    ['باربر', 'حلاق'],
  ],
  'en': [
    ['باربرها', 'barbers'],
    ['باربران', 'barbers'],
    ['باربر', 'barber'],
  ],
};
/// «گوشی» → «دستگاه» (برنامه روی ویندوز هم اجرا می‌شود).
/// «شماره تلفن» و مشابهش دست نمی‌خورد (اول محافظت می‌شود).
const Map<String, List<List<String>>> _deviceFix = {
  'fa': [
    ['شماره‌ی گوشی', 'شماره‌ی تلفن'],
    ['شماره گوشی', 'شماره تلفن'],
    ['شماره‌ی موبایل', 'شماره‌ی تلفن'],
    ['شماره موبایل', 'شماره تلفن'],
    ['گوشی‌ها', 'دستگاه‌ها'],
    ['گوشی', 'دستگاه'],
    ['موبایل', 'دستگاه'],
  ],
  'en': [
    ['mobile number', 'phone number'],
    ['Your phone', 'Your device'],
    ['your phone', 'your device'],
    ['This phone', 'This device'],
    ['this phone', 'this device'],
    ['Phone time', 'Device time'],
    ['phone time', 'device time'],
    ['Phone storage', 'Device storage'],
    ['phone storage', 'device storage'],
    ['on the phone', 'on the device'],
    ['on your mobile', 'on your device'],
  ],
  'ar': [
    ['رقم الجوال', 'رقم الهاتف'],
    ['وقت الهاتف', 'وقت الجهاز'],
    ['ذاكرة الهاتف', 'ذاكرة الجهاز'],
    ['هذا الهاتف', 'هذا الجهاز'],
    ['جوالك', 'جهازك'],
    ['الجوال', 'الجهاز'],
  ],
};
/// آخرین مرحله‌ی هر متن: درست‌کردن واژه‌ها («باربر»، «گوشی») و رقم‌ها به زبان برنامه
String uiText(String s, String lang) {
  var r = s;
  final fixes = _termFix[lang] ?? _termFix['en']!;
  for (final f in fixes) {
    r = r.replaceAll(f[0], f[1]);
  }
  final dev = _deviceFix[lang] ?? _deviceFix['en']!;
  for (final f in dev) {
    r = r.replaceAll(f[0], f[1]);
  }
  return localDigits(r, lang);
}
/// متن‌های تازه + همه‌ی متن‌های قبلی (T5 و پایین‌تر).
/// هر متنی که از این کلاس رد شود، واژه‌ها و رقم‌هایش به زبان برنامه می‌شود.
class T6 {
  T6(this.lang) : _base = T5(lang);
  final String lang;
  final T5 _base;
  String t(String key, [Map<String, Object?>? args]) {
    final own = _m[lang]?[key] ?? _m['en']?[key];
    if (own == null) {
      return uiText(
          _base.t(key, args?.map((k, v) => MapEntry(k, '$v'))), lang);
    }
    var r = own;
    if (args != null) {
      args.forEach((k, v) => r = r.replaceAll('{$k}', '$v'));
    }
    return uiText(r, lang);
  }
  String error(Object e) {
    if (e is ApiException) {
      final k = 'err_${e.code}';
      if ((_m[lang]?.containsKey(k) ?? false) ||
          (_m['en']?.containsKey(k) ?? false)) {
        return t(k);
      }
    }
    return uiText(_base.error(e), lang);
  }
}
final Map<String, Map<String, String>> _m = {
  'fa': {
    'pl_f_winback': 'ارسال پیام اختصاصی آرایشگاه در بازه‌های مشخص',
    'sh_title': 'ساعت‌های کار',
    'sh_hint':
        'هر آرایشگر در پلن شما تا {n} شیفت در روز می‌تواند داشته باشد؛ مثلاً صبح ۹ تا ۱۳ و عصر ۱۶ تا ۲۲. بین شیفت‌ها مشتری نوبت نمی‌گیرد.',
    'sh_limit': 'به سقف شیفتِ پلنتان رسیده‌اید ({n} شیفت).',
    'sh_n': 'شیفت {n}',
    'sh_from': 'شروع',
    'sh_to': 'پایان',
    'sh_add': 'افزودن شیفت',
    'sh_remove': 'حذف شیفت',
    'sh_overlap':
        'شیفت‌ها باید به ترتیب باشند و روی هم نیفتند. هر شیفت باید قبل از پایانش شروع شود.',
    'sh_no_room': 'جای شیفت جدید نیست؛ ساعت پایان شیفت قبلی را زودتر بگذارید.',
    'sh_unset_title': 'ساعت کاری تنظیم نشده',
    'sh_unset_msg':
        'تا ساعت کاری ذخیره نشود، مشتری برای این آرایشگر هیچ وقتی نمی‌بیند. ساعت و روزهای تعطیل را تنظیم و ذخیره کنید.',
    'sh_unset_owner':
        '{n} آرایشگر هنوز ساعت کاری‌اش را تنظیم نکرده؛ مشتری برای او وقت آزاد نمی‌بیند.',
    'sh_unset_mine':
        'ساعت کاری شما هنوز تنظیم نشده؛ تا تنظیم نکنید مشتری وقت آزادی برای شما نمی‌بیند.',
    'sh_not_set': 'ساعت تنظیم نشده',
    'err_PLAN_REQUIRED': 'این قابلیت در اشتراک شما نیست.',
    'err_PLAN_MISMATCH':
        'این کد برای اشتراک دیگری است. اشتراک و کد باید یکی باشند.',
    'err_BAD_SHIFTS':
        'ساعت‌های کار درست نیست. شیفت‌ها باید به ترتیب باشند و روی هم نیفتند.',
    'err_SHIFT_LIMIT':
        'تعداد شیفت‌ها از سقف پلن شما بیشتر است. شیفت‌ها را کمتر کنید یا پلن را ارتقا دهید.',
  },
  'en': {
    'pl_f_winback': 'Custom shop messages to customers at set intervals',
    'sh_title': 'Working hours',
    'sh_hint':
        'On your plan each barber can have up to {n} shifts a day, for example 9–13 and 16–22. Customers cannot book between shifts.',
    'sh_limit': 'You have reached your plan\'s shift limit ({n} shifts).',
    'sh_n': 'Shift {n}',
    'sh_from': 'Start',
    'sh_to': 'End',
    'sh_add': 'Add shift',
    'sh_remove': 'Remove shift',
    'sh_overlap':
        'Shifts must be in order and must not overlap. Each shift must start before it ends.',
    'sh_no_room': 'No room for another shift; end the previous shift earlier.',
    'sh_unset_title': 'Working hours not set',
    'sh_unset_msg':
        'Until the working hours are saved, customers see no free time for this barber. Set the hours and days off, then save.',
    'sh_unset_owner':
        '{n} barber(s) have not set their working hours yet; customers cannot see free times for them.',
    'sh_unset_mine':
        'Your working hours are not set yet; customers cannot see free times for you until you set them.',
    'sh_not_set': 'Hours not set',
    'err_PLAN_REQUIRED': 'This feature is not included in your plan.',
    'err_PLAN_MISMATCH':
        'This code belongs to a different plan. The chosen plan and the code must match.',
    'err_BAD_SHIFTS':
        'Working hours are not valid. Shifts must be in order and must not overlap.',
    'err_SHIFT_LIMIT':
        'The number of shifts is above your plan\'s limit. Use fewer shifts or upgrade your plan.',
  },
  'ar': {
    'pl_f_winback': 'إرسال رسالة خاصة بالصالون للزبائن في فترات محددة',
    'sh_title': 'ساعات العمل',
    'sh_hint':
        'في باقتك يمكن لكل حلاق أن يعمل حتى {n} فترات في اليوم، مثلاً 9–13 و16–22. لا يستطيع الزبون الحجز بين الفترات.',
    'sh_limit': 'وصلت إلى حد الفترات في باقتك ({n} فترات).',
    'sh_n': 'الفترة {n}',
    'sh_from': 'البداية',
    'sh_to': 'النهاية',
    'sh_add': 'إضافة فترة',
    'sh_remove': 'حذف الفترة',
    'sh_overlap':
        'يجب أن تكون الفترات مرتبة وغير متداخلة، وأن تبدأ كل فترة قبل نهايتها.',
    'sh_no_room': 'لا توجد مساحة لفترة جديدة؛ اجعل نهاية الفترة السابقة أبكر.',
    'sh_unset_title': 'ساعات العمل غير مضبوطة',
    'sh_unset_msg':
        'حتى تُحفظ ساعات العمل لن يرى الزبون أي وقت متاح لهذا الحلاق. اضبط الساعات وأيام العطلة ثم احفظ.',
    'sh_unset_owner':
        '{n} حلاق لم يضبط ساعات عمله بعد؛ لا يرى الزبون أوقاتاً متاحة له.',
    'sh_unset_mine':
        'ساعات عملك غير مضبوطة بعد؛ لن يرى الزبون أوقاتاً متاحة لك حتى تضبطها.',
    'sh_not_set': 'الساعات غير مضبوطة',
    'err_PLAN_REQUIRED': 'هذه الميزة غير متوفرة في اشتراكك.',
    'err_PLAN_MISMATCH':
        'هذا الرمز لاشتراك آخر. يجب أن يتطابق الاشتراك مع الرمز.',
    'err_BAD_SHIFTS':
        'ساعات العمل غير صحيحة. يجب أن تكون الفترات مرتبة وغير متداخلة.',
    'err_SHIFT_LIMIT':
        'عدد الفترات أكبر من الحد المسموح في باقتك. قلّل الفترات أو رقِّ باقتك.',
  },
};
