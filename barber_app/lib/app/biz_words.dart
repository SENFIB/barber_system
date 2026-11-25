import 'business_types.dart';

String _w(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

const List<String> _stylist = [
  'آرایشگر', 'Stylist', 'مصفّف',
  'آرایشگرها', 'Stylists', 'المصفّفون'
];
const List<String> _instr = [
  'مربی', 'Instructor', 'مدرّب',
  'مربی‌ها', 'Instructors', 'المدرّبون'
];
const List<String> _staff = [
  'نفر پرسنل', 'Staff member', 'موظف',
  'پرسنل', 'Staff', 'الموظفون'
];

/// عنوان اختصاصی هر نوع کسب‌وکار
/// [مفرد فارسی, انگلیسی, عربی, جمع فارسی, انگلیسی, عربی]
const Map<String, List<String>> _roles = {
  'barber': [
    'آرایشگر', 'Barber', 'حلاق',
    'آرایشگرها', 'Barbers', 'الحلاقون'
  ],
  'nails': [
    'ناخن‌کار', 'Nail technician', 'فنية أظافر',
    'ناخن‌کارها', 'Nail technicians', 'فنيات الأظافر'
  ],
  'makeup': [
    'میکاپ‌آرتیست', 'Makeup artist', 'خبيرة مكياج',
    'میکاپ‌آرتیست‌ها', 'Makeup artists', 'خبيرات المكياج'
  ],
  'skin': [
    'کارشناس پوست', 'Skin therapist', 'أخصائية بشرة',
    'کارشناس‌های پوست', 'Skin therapists', 'أخصائيات البشرة'
  ],
  'massage': [
    'ماساژور', 'Masseur', 'مدلّك',
    'ماساژورها', 'Masseurs', 'المدلّكون'
  ],
  'yoga': _instr,
  'meditation': _instr,
  'fitness_pt': _instr,
  'garage': [
    'مکانیک', 'Mechanic', 'ميكانيكي',
    'مکانیک‌ها', 'Mechanics', 'الميكانيكيون'
  ],
  'car_inspect': [
    'کارشناس فنی', 'Inspector', 'فاحص',
    'کارشناس‌های فنی', 'Inspectors', 'الفاحصون'
  ],
  'photo_studio': [
    'عکاس', 'Photographer', 'مصوّر',
    'عکاس‌ها', 'Photographers', 'المصوّرون'
  ],
  'wedding_photo': [
    'عکاس', 'Photographer', 'مصوّر',
    'عکاس‌ها', 'Photographers', 'المصوّرون'
  ],
  'biz_consult': [
    'مشاور', 'Consultant', 'مستشار',
    'مشاورها', 'Consultants', 'المستشارون'
  ],
  'fin_consult': [
    'مشاور', 'Consultant', 'مستشار',
    'مشاورها', 'Consultants', 'المستشارون'
  ],
  'lawyer': [
    'وکیل', 'Lawyer', 'محامٍ',
    'وکلا', 'Lawyers', 'المحامون'
  ],
  'translation': [
    'مترجم', 'Translator', 'مترجم',
    'مترجم‌ها', 'Translators', 'المترجمون'
  ],
  'language_class': [
    'مدرس', 'Teacher', 'معلّم',
    'مدرس‌ها', 'Teachers', 'المعلّمون'
  ],
  'private_class': [
    'معلم', 'Teacher', 'معلّم',
    'معلم‌ها', 'Teachers', 'المعلّمون'
  ],
  'vet': [
    'دامپزشک', 'Vet', 'طبيب بيطري',
    'دامپزشک‌ها', 'Vets', 'الأطباء البيطريون'
  ],
  'pet_grooming': [
    'آرایشگر حیوانات', 'Pet groomer', 'مصفّف حيوانات',
    'آرایشگرهای حیوانات', 'Pet groomers', 'مصفّفو الحيوانات'
  ],
  'pet_care': [
    'مراقب حیوانات', 'Pet carer', 'مُعتني بالحيوانات',
    'مراقب‌های حیوانات', 'Pet carers', 'المعتنون بالحيوانات'
  ],
  'pet_training': [
    'مربی حیوانات', 'Pet trainer', 'مدرّب حيوانات',
    'مربی‌های حیوانات', 'Pet trainers', 'مدرّبو الحيوانات'
  ],
};

/// گروه کسب‌وکار از روی نوع (پیش‌فرض: زیبایی)
String bwGroup(String? type) => bizTypeByKey(type ?? '')?.group ?? 'beauty';

bool bwBeauty(String? type) => bwGroup(type) == 'beauty';

/// شش واژه‌ی عنوان پرسنل برای این نوع
List<String> bwRole(String? type) {
  final k = type ?? '';
  if (k.isEmpty) return _roles['barber']!;
  final r = _roles[k];
  if (r != null) return r;
  final g = bwGroup(k);
  if (g == 'beauty') return _stylist;
  if (g == 'edu') return _instr;
  return _staff;
}

/// true یعنی برای این نوع عنوان اختصاصی نداریم («نفر پرسنل»)
bool bwGeneric(String? type) => identical(bwRole(type), _staff);

/// عنوان یک نفر از پرسنل
String bwStaff(String? type, String l) {
  final r = bwRole(type);
  return _w(l, r[0], r[1], r[2]);
}

/// جمع
String bwStaffs(String? type, String l) {
  final r = bwRole(type);
  return _w(l, r[3], r[4], r[5]);
}

String _art(String n) => 'AEIOUaeiou'.contains(n[0]) ? 'an' : 'a';

/// «خودم هم دامپزشکم» و مانند آن
String bwSelf(String? type, String l) {
  if (bwGeneric(type)) {
    return _w(l, 'خودم هم خدمت می‌دهم', 'I also provide services myself',
        'أقدّم الخدمات بنفسي أيضًا');
  }
  final r = bwRole(type);
  final fa = r[0].endsWith('ی') ? '${r[0]}‌ام' : '${r[0]}م';
  final en = r[1].toLowerCase();
  return _w(l, 'خودم هم $fa', 'I\'m also ${_art(en)} $en',
      'أنا أيضًا ${r[2]}');
}

/// «آرایشگاه» برای گروه زیبایی، «کسب‌وکار» برای بقیه
String bwShop(String? type, String l) {
  if (bwBeauty(type)) return _w(l, 'آرایشگاه', 'shop', 'الصالون');
  return _w(l, 'کسب‌وکار', 'business', 'النشاط التجاري');
}
