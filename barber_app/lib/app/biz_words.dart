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
```

مسیر فایل: `barber_app/lib/app/biz_panel.dart`

```dart
import 'package:flutter/material.dart';
import 'biz_icons.dart';
import 'biz_words.dart';
import 'business_types.dart';

String _p(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

/// واژه‌ها و آیکون‌های پنل بر اساس نوع کسب‌وکار
class BizPanel {
  const BizPanel._(this.type, this.group);
  final String type;
  final String group;

  factory BizPanel.of(String? bizType) {
    final k = (bizType != null && bizTypeByKey(bizType) != null)
        ? bizType
        : 'barber';
    return BizPanel._(k, bizTypeByKey(k)!.group);
  }

  bool get beauty => group == 'beauty';
  IconData get icon => bizTypeIcon(type);

  IconData get staffIcon {
    switch (group) {
      case 'beauty':
        return (type == 'barber' || type == 'salon' || type == 'hair_color')
            ? Icons.content_cut_rounded
            : Icons.brush_rounded;
      case 'wellness':
        return Icons.spa_rounded;
      case 'auto':
        return Icons.build_rounded;
      case 'pro':
        return Icons.work_rounded;
      case 'edu':
        return Icons.school_rounded;
      case 'pets':
        return Icons.pets_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String typeName(String lang) => bizTypeByKey(type)?.name(lang) ?? '';

  List<String> get _n => bwRole(type);

  String noun(String l) => _p(l, _n[0], _n[1], _n[2]);
  String plural(String l) => _p(l, _n[3], _n[4], _n[5]);

  String staffTitle(String l) => _p(l, 'مدیریت ${_n[3]}',
      'Manage ${_n[4].toLowerCase()}', 'إدارة ${_n[5]}');
  String staffDesc(String l) => _p(
      l,
      'افزودن ${_n[0]}، ساعت کار و خدماتشان',
      'Add ${_n[1].toLowerCase()}, their hours and services',
      'إضافة ${_n[2]} وساعات عملهم وخدماتهم');
  String staffMine(String l) =>
      _p(l, 'ساعت کار من', 'My schedule', 'جدولي');
  String addStaff(String l) => _p(l, 'افزودن ${_n[0]}',
      'Add ${_n[1].toLowerCase()}', 'إضافة ${_n[2]}');
  String staffName(String l) =>
      _p(l, 'نام ${_n[0]}', 'Name', 'الاسم');
  String addHint(String l) => _p(
      l,
      'فقط نام را بنویس؛ بعد از ساخت می‌توانی ساعت کار و خدمات را تنظیم کنی.',
      'Just type the name; afterwards you can set working hours and services.',
      'اكتب الاسم فقط؛ بعدها يمكنك ضبط ساعات العمل والخدمات.');

  String selfLabel(String l) => bwSelf(type, l);
  String becomeSelf(String l) => bwSelf(type, l);
  String becomeSelfDesc(String l) => _p(
      l,
      'اگر خودت هم به مشتری‌ها خدمت می‌دهی، اسمت هم در فهرست قرار می‌گیرد تا مشتری‌ها از تو هم نوبت بگیرند.',
      'If you also serve customers yourself, you will be listed too so customers can book with you.',
      'إذا كنت تقدّم الخدمات بنفسك فسيظهر اسمك في القائمة ليتمكن الزبائن من الحجز عندك.');
  String stopSelf(String l) => bwGeneric(type)
      ? _p(l, 'دیگر خودم خدمت نمی‌دهم', 'I no longer provide services myself',
          'لم أعد أقدّم الخدمات بنفسي')
      : _p(l, 'نام من از فهرست ${_n[3]} حذف شود',
          'Remove me from the ${_n[4].toLowerCase()}',
          'احذفني من قائمة ${_n[5]}');
  String stopSelfConfirm(String l) => _p(
      l,
      'نام تو از فهرست ارائه‌دهندگان خدمت برداشته می‌شود. ادامه می‌دهی؟',
      'Your name will be removed from the list of service providers. Continue?',
      'سيُحذف اسمك من قائمة مقدّمي الخدمات. هل تريد المتابعة؟');
  String noStaff(String l) => _p(l, 'هنوز کسی اضافه نشده',
      'No one has been added yet', 'لم تتم إضافة أحد بعد');
  String capacity(String l, String n, String max) => _p(
      l,
      'ظرفیت: $n از $max ${_n[0]}',
      'Capacity: $n of $max',
      'السعة: $n من $max');
  String msgTitle(String l) => beauty
      ? _p(l, 'پیام اختصاصی آرایشگاه', 'Custom shop message',
          'رسالة خاصة بالصالون')
      : _p(l, 'پیام اختصاصی کسب‌وکار', 'Custom business message',
          'رسالة خاصة بالنشاط التجاري');
}
