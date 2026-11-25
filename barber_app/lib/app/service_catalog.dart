class CatalogItem {
  final String key;
  final String gender; // men | women | both
  final int minutes;
  final String fa;
  final String en;
  final String ar;
  final String group; // کلید گروه کسب‌وکار
  const CatalogItem(this.key, this.gender, this.minutes, this.fa, this.en, this.ar,
      [this.group = 'beauty']);
  String name(String lang) => lang == 'en' ? en : (lang == 'ar' ? ar : fa);
}

const List<CatalogItem> kServiceCatalog = [
  // ---- آرایش و زیبایی ----
  CatalogItem('full_cut', 'men', 45, 'اصلاح کامل', 'Full grooming', 'حلاقة كاملة'),
  CatalogItem('beard', 'men', 20, 'اصلاح ریش و سیبیل', 'Beard & mustache trim', 'تشذيب اللحية والشارب'),
  CatalogItem('face_groom', 'women', 30, 'اصلاح صورت', 'Facial threading', 'تنظيف الوجه بالخيط'),
  CatalogItem('eyebrow', 'women', 20, 'اصلاح ابرو', 'Eyebrow shaping', 'تهذيب الحواجب'),
  CatalogItem('blowdry', 'women', 30, 'براشینگ و سشوار', 'Blow-dry & styling', 'سشوار وتصفيف'),
  CatalogItem('highlights', 'women', 150, 'مش و هایلایت', 'Highlights', 'هايلايت'),
  CatalogItem('manicure', 'women', 60, 'مانیکور و پدیکور', 'Manicure & pedicure', 'مانيكير وباديكير'),
  CatalogItem('waxing', 'women', 40, 'اپیلاسیون', 'Waxing', 'إزالة الشعر بالشمع'),
  CatalogItem('makeup', 'women', 90, 'آرایش و میکاپ', 'Makeup', 'مكياج'),
  CatalogItem('lash_ext', 'women', 90, 'اکستنشن مژه', 'Eyelash extensions', 'وصل الرموش'),
  CatalogItem('nail_art', 'women', 60, 'ناخن و نیل‌آرت', 'Nail art', 'فن الأظافر'),
  CatalogItem('haircut', 'both', 30, 'کوتاهی مو', 'Haircut', 'قص الشعر'),
  CatalogItem('keratin', 'both', 120, 'کراتین مو', 'Hair keratin treatment', 'علاج الكيراتين'),
  CatalogItem('hair_color', 'both', 90, 'رنگ مو', 'Hair coloring', 'صبغ الشعر'),
  CatalogItem('skin_clean', 'both', 45, 'پاکسازی پوست', 'Facial cleansing', 'تنظيف البشرة'),
  CatalogItem('hair_mask', 'both', 40, 'ماسک و احیای مو', 'Hair mask & repair', 'ماسك وترميم الشعر'),
  // ---- سلامت و آرامش ----
  CatalogItem('massage_body', 'both', 60, 'ماساژ بدن', 'Body massage', 'مساج الجسم', 'wellness'),
  CatalogItem('massage_foot', 'both', 30, 'ماساژ پا', 'Foot massage', 'مساج القدمين', 'wellness'),
  CatalogItem('massage_sport', 'both', 60, 'ماساژ ورزشی', 'Sports massage', 'مساج رياضي', 'wellness'),
  CatalogItem('spa_package', 'both', 90, 'پکیج اسپا', 'Spa package', 'باقة سبا', 'wellness'),
  CatalogItem('sauna_jacuzzi', 'both', 45, 'سونا و جکوزی', 'Sauna & jacuzzi', 'ساونا وجاكوزي', 'wellness'),
  CatalogItem('relax_session', 'both', 45, 'جلسه‌ی ریلکسیشن', 'Relaxation session', 'جلسة استرخاء', 'wellness'),
  CatalogItem('yoga_class', 'both', 60, 'کلاس یوگا', 'Yoga class', 'حصة يوغا', 'wellness'),
  CatalogItem('meditation_session', 'both', 45, 'جلسه‌ی مدیتیشن', 'Meditation session', 'جلسة تأمل', 'wellness'),
  CatalogItem('pt_session', 'both', 60, 'جلسه‌ی مربی بدنسازی', 'Personal training session', 'جلسة تدريب شخصي', 'wellness'),
  // ---- خودرو ----
  CatalogItem('wash_out', 'both', 20, 'شست‌وشوی بیرون خودرو', 'Exterior car wash', 'غسيل خارجي للسيارة', 'auto'),
  CatalogItem('wash_full', 'both', 45, 'شست‌وشوی کامل (بیرون و داخل)', 'Full wash (inside & out)', 'غسيل كامل (داخل وخارج)', 'auto'),
  CatalogItem('wax_polish', 'both', 90, 'واکس و پولیش', 'Wax & polish', 'تلميع وشمع', 'auto'),
  CatalogItem('ceramic_coat', 'both', 180, 'پوشش سرامیک', 'Ceramic coating', 'طلاء سيراميك', 'auto'),
  CatalogItem('interior_detail', 'both', 120, 'دیتیلینگ داخل خودرو', 'Interior detailing', 'تنظيف وتجميل داخلي', 'auto'),
  CatalogItem('oil_change', 'both', 30, 'تعویض روغن', 'Oil change', 'تغيير الزيت', 'auto'),
  CatalogItem('car_service', 'both', 90, 'سرویس دوره‌ای', 'Periodic service', 'صيانة دورية', 'auto'),
  CatalogItem('tire_balance', 'both', 30, 'تعویض لاستیک و بالانس', 'Tires & balancing', 'تغيير الإطارات والموازنة', 'auto'),
  CatalogItem('body_paint_job', 'both', 240, 'صافکاری و نقاشی', 'Body work & paint', 'سمكرة ودهان', 'auto'),
  CatalogItem('car_inspection', 'both', 45, 'کارشناسی خودرو', 'Car inspection', 'فحص السيارة', 'auto'),
  // ---- خدمات تخصصی و مشاوره ----
  CatalogItem('photo_shoot', 'both', 60, 'عکاسی در آتلیه', 'Studio photo shoot', 'جلسة تصوير في الاستوديو', 'pro'),
  CatalogItem('wedding_shoot', 'both', 180, 'عکاسی عروسی', 'Wedding photography', 'تصوير حفلات الزفاف', 'pro'),
  CatalogItem('biz_consulting', 'both', 60, 'مشاوره‌ی کسب‌وکار', 'Business consulting', 'استشارة أعمال', 'pro'),
  CatalogItem('legal_consulting', 'both', 45, 'مشاوره‌ی حقوقی', 'Legal consultation', 'استشارة قانونية', 'pro'),
  CatalogItem('finance_consulting', 'both', 45, 'مشاوره‌ی مالی', 'Financial consulting', 'استشارة مالية', 'pro'),
  CatalogItem('translation_service', 'both', 30, 'ترجمه', 'Translation', 'ترجمة', 'pro'),
  // ---- آموزش و ورزش ----
  CatalogItem('gym_session', 'both', 90, 'تمرین در باشگاه', 'Gym session', 'تمرين في النادي', 'edu'),
  CatalogItem('coach_session', 'both', 60, 'جلسه‌ی مربی خصوصی', 'Private coaching', 'جلسة مدرب خاص', 'edu'),
  CatalogItem('music_lesson', 'both', 45, 'کلاس موسیقی', 'Music lesson', 'حصة موسيقى', 'edu'),
  CatalogItem('language_lesson', 'both', 60, 'کلاس زبان', 'Language lesson', 'حصة لغة', 'edu'),
  CatalogItem('driving_lesson', 'both', 60, 'کلاس رانندگی', 'Driving lesson', 'درس قيادة', 'edu'),
  CatalogItem('private_lesson', 'both', 60, 'کلاس خصوصی', 'Private lesson', 'حصة خصوصية', 'edu'),
  // ---- حیوانات خانگی ----
  CatalogItem('pet_grooming_s', 'both', 60, 'آرایش و شست‌وشوی حیوان', 'Pet grooming & bath', 'تجميل واستحمام الحيوان', 'pets'),
  CatalogItem('pet_clean_trim', 'both', 45, 'نظافت و اصلاح', 'Cleaning & trimming', 'تنظيف وتقليم', 'pets'),
  CatalogItem('pet_visit', 'both', 30, 'ویزیت دامپزشکی', 'Vet visit', 'زيارة بيطرية', 'pets'),
  CatalogItem('pet_vaccine', 'both', 20, 'واکسیناسیون حیوان', 'Pet vaccination', 'تطعيم الحيوان', 'pets'),
  CatalogItem('pet_boarding', 'both', 60, 'نگهداری و پانسیون', 'Pet boarding', 'إيواء ورعاية', 'pets'),
  CatalogItem('pet_training_s', 'both', 60, 'آموزش حیوان', 'Pet training', 'تدريب الحيوان', 'pets'),
];

/// خدمات پیشنهادیِ آرایش و زیبایی، مناسب جنسیت (men | women | both)
List<CatalogItem> catalogFor(String gender) {
  return kServiceCatalog.where((c) {
    if (c.group != 'beauty') return false;
    if (gender == 'men') return c.gender != 'women';
    if (gender == 'women') return c.gender != 'men';
    return true;
  }).toList();
}

/// خدمات برای جستجو: group خالی یعنی همه‌ی گروه‌ها.
/// جنسیت فقط روی خدمات آرایش و زیبایی اثر دارد.
List<CatalogItem> catalogForGroup(String group, String gender) {
  return kServiceCatalog.where((c) {
    if (group.isNotEmpty && c.group != group) return false;
    if (c.group != 'beauty') return true;
    if (gender == 'men') return c.gender != 'women';
    if (gender == 'women') return c.gender != 'men';
    return true;
  }).toList();
}

String catalogName(String key, String lang) {
  for (final c in kServiceCatalog) {
    if (c.key == key) return c.name(lang);
  }
  return '';
}
