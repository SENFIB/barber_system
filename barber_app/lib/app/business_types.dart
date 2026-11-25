class BizGroup {
  const BizGroup(this.key, this.fa, this.en, this.ar);
  final String key;
  final String fa;
  final String en;
  final String ar;
  String name(String lang) => lang == 'fa' ? fa : (lang == 'ar' ? ar : en);
}

class BizType {
  const BizType(
      this.key, this.group, this.family, this.fa, this.en, this.ar);
  final String key;
  final String group;

  /// نوع‌هایی که خانواده‌ی یکسان دارند رقیب هم حساب می‌شوند
  final String family;
  final String fa;
  final String en;
  final String ar;
  String name(String lang) => lang == 'fa' ? fa : (lang == 'ar' ? ar : en);
}

const kBizGroups = <BizGroup>[
  BizGroup('beauty', 'آرایش و زیبایی', 'Beauty', 'التجميل والجمال'),
  BizGroup('wellness', 'سلامتی و آرامش', 'Wellness & relaxation',
      'الصحة والاسترخاء'),
  BizGroup('auto', 'خودرو و خدمات فنی', 'Cars & technical services',
      'السيارات والخدمات الفنية'),
  BizGroup('pro', 'خدمات شخصی و حرفه‌ای', 'Personal & professional',
      'خدمات شخصية ومهنية'),
  BizGroup('edu', 'آموزش و ورزش', 'Education & sports', 'التعليم والرياضة'),
  BizGroup('pets', 'حیوانات خانگی', 'Pets', 'الحيوانات الأليفة'),
];

const kBizTypes = <BizType>[
  // آرایش و زیبایی
  BizType('barber', 'beauty', 'hair', 'آرایشگاه مردانه', 'Men’s barbershop',
      'صالون حلاقة رجالي'),
  BizType('salon', 'beauty', 'hair', 'آرایشگاه زنانه',
      'Women’s beauty salon', 'صالون تجميل نسائي'),
  BizType('hair_color', 'beauty', 'hair', 'رنگ و مش مو',
      'Hair color & highlights', 'صبغ الشعر والخصل'),
  BizType('nails', 'beauty', 'nails', 'ناخن', 'Nails', 'الأظافر'),
  BizType('lash_brow', 'beauty', 'lash_brow', 'مژه و ابرو', 'Lashes & brows',
      'الرموش والحواجب'),
  BizType('makeup', 'beauty', 'makeup', 'میکاپ و گریم', 'Makeup', 'المكياج'),
  BizType('skin', 'beauty', 'skin', 'خدمات پوست و زیبایی',
      'Skin & beauty care', 'العناية بالبشرة والجمال'),
  // سلامتی و آرامش
  BizType('massage', 'wellness', 'massage', 'ماساژ', 'Massage', 'المساج'),
  BizType('spa', 'wellness', 'spa', 'اسپا', 'Spa', 'سبا'),
  BizType('relax', 'wellness', 'relax', 'مراکز مراقبت و ریلکسیشن',
      'Care & relaxation centers', 'مراكز العناية والاسترخاء'),
  BizType('yoga', 'wellness', 'yoga', 'یوگا', 'Yoga', 'اليوغا'),
  BizType('meditation', 'wellness', 'meditation', 'مدیتیشن', 'Meditation',
      'التأمل'),
  BizType('fitness_pt', 'wellness', 'fitness_pt', 'مربی شخصی تناسب اندام',
      'Personal fitness trainer', 'مدرب لياقة شخصي'),
  // خودرو و خدمات فنی
  BizType('carwash', 'auto', 'carwash', 'کارواش', 'Car wash', 'مغسلة سيارات'),
  BizType('detailing', 'auto', 'detailing', 'دیتیلینگ', 'Car detailing',
      'تلميع وتجميل السيارات'),
  BizType('oil_change', 'auto', 'oil_change', 'تعویض روغن', 'Oil change',
      'تغيير الزيت'),
  BizType('garage', 'auto', 'garage', 'تعمیرگاه', 'Auto repair shop',
      'ورشة تصليح'),
  BizType('body_paint', 'auto', 'body_paint', 'صافکاری و نقاشی',
      'Body work & paint', 'سمكرة ودهان'),
  BizType('car_inspect', 'auto', 'car_inspect', 'کارشناسی خودرو',
      'Car inspection', 'فحص السيارات'),
  // خدمات شخصی و حرفه‌ای
  BizType('photo_studio', 'pro', 'photo_studio', 'آتلیه عکاسی',
      'Photo studio', 'استوديو تصوير'),
  BizType('wedding_photo', 'pro', 'wedding_photo', 'عکاسی عروسی',
      'Wedding photography', 'تصوير الأعراس'),
  BizType('biz_consult', 'pro', 'biz_consult', 'مشاور کسب‌وکار',
      'Business consultant', 'مستشار أعمال'),
  BizType('lawyer', 'pro', 'lawyer', 'وکیل', 'Lawyer', 'محامٍ'),
  BizType('fin_consult', 'pro', 'fin_consult', 'مشاور مالی',
      'Financial advisor', 'مستشار مالي'),
  BizType('translation', 'pro', 'translation', 'ترجمه', 'Translation',
      'الترجمة'),
  // آموزش و ورزش
  BizType('gym', 'edu', 'gym', 'باشگاه ورزشی', 'Gym / sports club',
      'نادٍ رياضي'),
  BizType('private_coach', 'edu', 'private_coach', 'مربی خصوصی',
      'Private coach', 'مدرب خاص'),
  BizType('music_school', 'edu', 'music_school', 'آموزشگاه موسیقی',
      'Music school', 'معهد موسيقى'),
  BizType('language_class', 'edu', 'language_class', 'کلاس زبان',
      'Language class', 'دورة لغة'),
  BizType('driving_class', 'edu', 'driving_class', 'کلاس رانندگی',
      'Driving school', 'مدرسة قيادة'),
  BizType('private_class', 'edu', 'private_class', 'کلاس خصوصی',
      'Private lessons', 'دروس خصوصية'),
  // حیوانات خانگی
  BizType('pet_grooming', 'pets', 'pet_grooming', 'آرایشگاه حیوانات',
      'Pet grooming', 'تجميل الحيوانات'),
  BizType('vet', 'pets', 'vet', 'دامپزشکی', 'Veterinary', 'عيادة بيطرية'),
  BizType('pet_care', 'pets', 'pet_care', 'نگهداری حیوانات', 'Pet boarding',
      'رعاية الحيوانات'),
  BizType('pet_training', 'pets', 'pet_training', 'آموزش حیوانات',
      'Pet training', 'تدريب الحيوانات'),
];

BizType? bizTypeByKey(String key) {
  for (final t in kBizTypes) {
    if (t.key == key) return t;
  }
  return null;
}

List<BizType> bizTypesOf(String group) =>
    [for (final t in kBizTypes) if (t.group == group) t];

BizGroup? bizGroupByKey(String key) {
  for (final g in kBizGroups) {
    if (g.key == key) return g;
  }
  return null;
}

/// نوع کسب‌وکار یک آرایشگاه؛ اگر سرور چیزی نفرستاده باشد از روی جنسیت حدس می‌زنیم
String bizKeyOf(Map<String, dynamic> m) {
  final k = '${m['biz_type'] ?? ''}'.trim();
  if (bizTypeByKey(k) != null) return k;
  return '${m['gender'] ?? ''}' == 'women' ? 'salon' : 'barber';
}

/// آیا تبلیغ کسب‌وکارِ [own] در صفحه‌ی کسب‌وکارِ [target] «توصیه نمی‌شود»؟
bool bizNotRecommended(String own, String target) {
  final a = bizTypeByKey(own);
  final b = bizTypeByKey(target);
  if (a == null || b == null) return false;
  return a.family == b.family;
}
