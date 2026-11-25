class StoreT {
  final String lang;
  const StoreT(this.lang);

  static const Map<String, Map<String, String>> _m = {
    'fa': {
      'title': 'فروشگاه / سایت',
      'hint':
          'یک دکمه با اسم سایتت توی صفحه‌ی آرایشگاه نمایش داده می‌شود و مشتری را به سایتت می‌برد.',
      'on': 'نمایش به مشتری',
      'url': 'آدرس سایت',
      'label': 'اسم دکمه (مثلاً اسم سایتت)',
      'items': 'محصولات (تا {n} تا)',
      'item_name': 'اسم محصول',
      'add': 'افزودن محصول',
      'remove': 'حذف',
      'pick': 'انتخاب عکس',
      'change': 'تغییر عکس',
      'save': 'ذخیره',
      'saved': 'ذخیره شد',
      'locked': 'این امکان برای پلن پرو و ویژه است.',
      'bad_url': 'آدرس سایت باید با https:// شروع شود',
      'need_label': 'اسم دکمه را بنویس',
      'too_big': 'عکس بزرگ‌تر از ۶۰۰ کیلوبایت است',
      'buy': 'از سایت خرید کنید',
      'pro_img':
          'در پلن پرو عکس همه‌ی محصولات لوگوی برنامه است. با پلن ویژه می‌توانی عکس خودت را بگذاری.',
      'retry': 'تلاش دوباره',
    },
    'en': {
      'title': 'Shop / website',
      'hint':
          'A button with your website name appears on your shop page and takes customers to your site.',
      'on': 'Show to customers',
      'url': 'Website address',
      'label': 'Button name (e.g. your site name)',
      'items': 'Products (up to {n})',
      'item_name': 'Product name',
      'add': 'Add product',
      'remove': 'Remove',
      'pick': 'Choose photo',
      'change': 'Change photo',
      'save': 'Save',
      'saved': 'Saved',
      'locked': 'This feature is for the Pro and Special plans.',
      'bad_url': 'The address must start with https://',
      'need_label': 'Write the button name',
      'too_big': 'The photo is larger than 600 KB',
      'buy': 'Buy from the website',
      'pro_img':
          'On the Pro plan every product uses the app logo as its photo. Upgrade to Special to use your own photos.',
      'retry': 'Retry',
    },
    'ar': {
      'title': 'المتجر / الموقع',
      'hint':
          'يظهر زر باسم موقعك في صفحة الصالون ويوجّه الزبائن إلى موقعك.',
      'on': 'إظهار للزبائن',
      'url': 'عنوان الموقع',
      'label': 'اسم الزر (مثلاً اسم موقعك)',
      'items': 'المنتجات (حتى {n})',
      'item_name': 'اسم المنتج',
      'add': 'إضافة منتج',
      'remove': 'حذف',
      'pick': 'اختيار صورة',
      'change': 'تغيير الصورة',
      'save': 'حفظ',
      'saved': 'تم الحفظ',
      'locked': 'هذه الميزة لباقتي برو والخاصة.',
      'bad_url': 'يجب أن يبدأ العنوان بـ https://',
      'need_label': 'اكتب اسم الزر',
      'too_big': 'حجم الصورة أكبر من 600 كيلوبايت',
      'buy': 'اشترِ من الموقع',
      'pro_img':
          'في باقة برو تكون صورة كل المنتجات هي شعار التطبيق. مع الباقة الخاصة يمكنك وضع صورك.',
      'retry': 'إعادة المحاولة',
    },
  };

  String t(String key, [Map<String, String>? params]) {
    final table = _m[lang] ?? _m['fa']!;
    var s = table[key] ?? _m['fa']![key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }
}
