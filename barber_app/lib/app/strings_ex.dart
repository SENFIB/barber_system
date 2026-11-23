/// متن‌های جدید برنامه (فارسی، انگلیسی، عربی) — ترتیب: [fa, en, ar]
class X {
  const X(this.lang);
  final String lang;

  int get _i => lang == 'en' ? 1 : (lang == 'ar' ? 2 : 0);

  String t(String key, [Map<String, Object>? args]) {
    final v = _m[key];
    var r = v == null ? key : v[_i];
    if (args != null) {
      args.forEach((k, val) {
        r = r.replaceAll('{$k}', '$val');
      });
    }
    return r;
  }
}

const Map<String, List<String>> _m = {
  'version': ['نسخه', 'Version', 'الإصدار'],
  'appearance': ['ظاهر', 'Appearance', 'المظهر'],
  'appearance_desc': [
    'شخصی‌سازی رنگ، پس‌زمینه و فونت',
    'Customize colors, background and fonts',
    'تخصيص الألوان والخلفية والخطوط'
  ],
  'sd_look': ['ظاهر', 'Appearance', 'المظهر'],
  'sd_look_default': ['پیش‌فرض', 'Default', 'افتراضي'],
  'sd_look_custom': ['سفارشی', 'Custom', 'مخصص'],

  'ap_title': ['شخصی‌سازی برنامه', 'Personalize the app', 'تخصيص التطبيق'],
  'ap_sample': ['نمونه', 'Preview', 'معاينة'],
  'ap_sample_title': ['آرایشگاه نمونه', 'Sample Barber', 'صالون نموذجي'],
  'ap_sample_sub': ['اصلاح و مدل مو', 'Haircut & styling', 'قص وتصفيف'],
  'ap_sample_pill': ['★ 4.8', '★ 4.8', '★ 4.8'],
  'ap_sample_btn': ['رزرو نوبت', 'Book now', 'احجز الآن'],
  'ap_presets': ['طرح‌های آماده', 'Preset designs', 'تصاميم جاهزة'],
  'ap_presets_hint': [
    'انتخاب طرح، رنگ‌های دستی را پاک می‌کند.',
    'Choosing a design clears your manual colors.',
    'اختيار تصميم يمسح الألوان اليدوية.'
  ],
  'ap_background': ['پس‌زمینه', 'Background', 'الخلفية'],
  'ap_colors': ['رنگ‌ها', 'Colors', 'الألوان'],
  'ap_font': ['فونت', 'Font', 'الخط'],
  'ap_glass': ['شیشه و گوشه‌ها', 'Glass & corners', 'الزجاج والزوايا'],

  'p_aurora': ['شفق', 'Aurora', 'الشفق'],
  'p_ocean': ['اقیانوس', 'Ocean', 'المحيط'],
  'p_sunset': ['غروب', 'Sunset', 'الغروب'],
  'p_forest': ['جنگل', 'Forest', 'الغابة'],
  'p_rose': ['رز', 'Rose', 'وردي'],
  'p_gold': ['طلایی', 'Gold', 'ذهبي'],
  'p_mono': ['مینیمال', 'Minimal', 'بسيط'],
  'p_neon': ['نئون', 'Neon', 'نيون'],

  'bg_blobs': ['حباب‌های متحرک', 'Moving blobs', 'فقاعات متحركة'],
  'bg_gradient': ['گرادیان', 'Gradient', 'تدرج'],
  'bg_waves': ['موج', 'Waves', 'أمواج'],
  'bg_dots': ['نقطه‌ای', 'Dots', 'نقاط'],
  'bg_stripes': ['راه‌راه آرایشگاه', 'Barber stripes', 'خطوط الحلاق'],
  'bg_solid': ['ساده', 'Solid', 'سادة'],
  'bg_image': ['عکس خودم', 'My photo', 'صورتي'],
  'ap_pick_image': ['انتخاب عکس', 'Choose photo', 'اختيار صورة'],
  'ap_change_image': ['تغییر عکس', 'Change photo', 'تغيير الصورة'],
  'ap_remove_image': ['حذف عکس', 'Remove photo', 'حذف الصورة'],
  'ap_blur': ['تاری عکس', 'Photo blur', 'تمويه الصورة'],
  'ap_dim': ['پوشش روی عکس', 'Photo overlay', 'طبقة فوق الصورة'],
  'ap_img_big': [
    'عکس خیلی بزرگ است (حداکثر ۲۰ مگابایت)',
    'Image is too large (max 20 MB)',
    'الصورة كبيرة جدًا (الحد 20 ميجابايت)'
  ],
  'ap_img_fail': [
    'این عکس قابل استفاده نبود',
    'Could not use that image',
    'تعذر استخدام هذه الصورة'
  ],

  'ap_editing_dark': [
    'در حال ویرایش رنگ‌های حالت تیره',
    'Editing dark-mode colors',
    'تعديل ألوان الوضع الداكن'
  ],
  'ap_editing_light': [
    'در حال ویرایش رنگ‌های حالت روشن',
    'Editing light-mode colors',
    'تعديل ألوان الوضع الفاتح'
  ],
  'ap_editing_hint': [
    'رنگ پس‌زمینه، کارت و متن برای حالت تیره و روشن جدا ذخیره می‌شود. حالت دیگر را از بخش «پوسته» بالای همین صفحه عوض کن.',
    'Background, card and text colors are stored separately for dark and light. Switch the mode with the Theme picker above.',
    'ألوان الخلفية والبطاقة والنص تُحفظ منفصلة للداكن والفاتح. بدّل الوضع من «السمة» أعلاه.'
  ],
  'c_primary': [
    'رنگ اصلی (دکمه‌ها و آیکن‌ها)',
    'Main color (buttons, icons)',
    'اللون الأساسي (الأزرار والأيقونات)'
  ],
  'c_secondary': [
    'رنگ دوم گرادیان',
    'Gradient second color',
    'اللون الثاني للتدرج'
  ],
  'c_accent': ['رنگ تأکیدی', 'Accent color', 'لون التمييز'],
  'c_danger': ['رنگ حذف و خطر', 'Delete & danger color', 'لون الحذف والخطر'],
  'c_bg1': ['پس‌زمینه ۱ (بالا)', 'Background 1 (top)', 'الخلفية 1 (أعلى)'],
  'c_bg2': ['پس‌زمینه ۲ (وسط)', 'Background 2 (middle)', 'الخلفية 2 (وسط)'],
  'c_bg3': ['پس‌زمینه ۳ (پایین)', 'Background 3 (bottom)', 'الخلفية 3 (أسفل)'],
  'c_card': ['رنگ کارت‌های شیشه‌ای', 'Glass card color', 'لون البطاقات الزجاجية'],
  'c_text': ['رنگ متن', 'Text color', 'لون النص'],
  'ap_reset_colors': ['بازنشانی همه‌ی رنگ‌ها', 'Reset all colors', 'إعادة ضبط الألوان'],

  'f_system': ['فونت سیستم', 'System font', 'خط النظام'],
  'ap_font_size': ['اندازه‌ی نوشته‌ها', 'Text size', 'حجم النص'],
  'ap_font_hint': [
    'فونت‌ها یک بار از اینترنت دانلود و روی گوشی ذخیره می‌شوند؛ بار اول ممکن است چند ثانیه طول بکشد.',
    'Fonts are downloaded once and cached on the device; the first use needs internet and may take a few seconds.',
    'تُنزَّل الخطوط مرة واحدة وتُحفظ على الجهاز؛ أول استخدام يحتاج إنترنت وقد يستغرق ثوانٍ.'
  ],
  'ap_glass_blur': ['میزان محوشدگی شیشه', 'Glass blur', 'تمويه الزجاج'],
  'ap_glass_opacity': ['غلظت شیشه', 'Glass opacity', 'كثافة الزجاج'],
  'ap_radius': ['گردی گوشه‌ها', 'Corner roundness', 'استدارة الزوايا'],

  'ap_reset_all': ['بازنشانی همه‌ی تنظیمات ظاهر', 'Reset all appearance', 'إعادة ضبط كل المظهر'],
  'ap_reset_confirm': [
    'همه‌ی تغییرات ظاهر و عکس پس‌زمینه پاک می‌شود. ادامه می‌دهی؟',
    'All appearance changes and the background photo will be removed. Continue?',
    'سيتم حذف كل تغييرات المظهر وصورة الخلفية. هل تريد المتابعة؟'
  ],
  'ap_reset_ok': ['بازنشانی', 'Reset', 'إعادة ضبط'],

  'pk_hue': ['رنگ', 'Hue', 'درجة اللون'],
  'pk_sat': ['خلوص', 'Saturation', 'التشبع'],
  'pk_val': ['روشنایی', 'Brightness', 'السطوع'],
  'pk_alpha': ['شفافیت', 'Opacity', 'الشفافية'],
  'pk_hex': ['کد رنگ', 'Hex code', 'رمز اللون'],
  'pk_apply': ['اعمال', 'Apply', 'تطبيق'],
  'pk_default': ['پیش‌فرض', 'Default', 'الافتراضي'],
  'pk_cancel': ['انصراف', 'Cancel', 'إلغاء'],
};
