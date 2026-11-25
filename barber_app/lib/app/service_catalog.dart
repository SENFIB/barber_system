class CatalogItem {
  final String key;
  final String gender; // men | women | both
  final int minutes;
  final String fa;
  final String en;
  final String ar;
  const CatalogItem(this.key, this.gender, this.minutes, this.fa, this.en, this.ar);
  String name(String lang) => lang == 'en' ? en : (lang == 'ar' ? ar : fa);
}

const List<CatalogItem> kServiceCatalog = [
  CatalogItem('full_cut', 'men', 45, 'اصلاح کامل', 'Full grooming', 'حلاقة كاملة'),
  CatalogItem('beard', 'men', 20, 'اصلاح ریش و سیبیل', 'Beard & mustache trim', 'تشذيب اللحية والشارب'),
  CatalogItem('face_groom', 'women', 30, 'اصلاح صورت', 'Facial threading', 'تنظيف الوجه بالخيط'),
  CatalogItem('eyebrow', 'women', 20, 'اصلاح ابرو', 'Eyebrow shaping', 'تهذيب الحواجب'),
  CatalogItem('blowdry', 'women', 30, 'براشینگ و سشوار', 'Blow-dry & styling', 'سشوار وتصفيف'),
  CatalogItem('highlights', 'women', 150, 'مش و هایلایت', 'Highlights', 'هايلايت'),
  CatalogItem('manicure', 'women', 60, 'مانیکور و پدیکور', 'Manicure & pedicure', 'مانيكير وباديكير'),
  CatalogItem('waxing', 'women', 40, 'اپیلاسیون', 'Waxing', 'إزالة الشعر بالشمع'),
  CatalogItem('makeup', 'women', 90, 'آرایش و میکاپ', 'Makeup', 'مكياج'),
  CatalogItem('haircut', 'both', 30, 'کوتاهی مو', 'Haircut', 'قص الشعر'),
  CatalogItem('keratin', 'both', 120, 'کراتین مو', 'Hair keratin treatment', 'علاج الكيراتين'),
  CatalogItem('hair_color', 'both', 90, 'رنگ مو', 'Hair coloring', 'صبغ الشعر'),
  CatalogItem('skin_clean', 'both', 45, 'پاکسازی پوست', 'Facial cleansing', 'تنظيف البشرة'),
  CatalogItem('hair_mask', 'both', 40, 'ماسک و احیای مو', 'Hair mask & repair', 'ماسك وترميم الشعر'),
];

/// خدمات مناسب جنسیت آرایشگاه (men | women | both)
List<CatalogItem> catalogFor(String gender) {
  return kServiceCatalog.where((c) {
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
