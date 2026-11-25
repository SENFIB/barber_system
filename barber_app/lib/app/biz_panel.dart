import 'package:flutter/material.dart';
import 'biz_icons.dart';
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

  List<String> get _n {
    if (type == 'barber') {
      return const [
        'آرایشگر', 'Barber', 'حلاق',
        'آرایشگرها', 'Barbers', 'الحلاقون'
      ];
    }
    if (group == 'beauty') {
      return const [
        'آرایشگر', 'Stylist', 'مصفّف',
        'آرایشگرها', 'Stylists', 'المصفّفون'
      ];
    }
    if (group == 'edu') {
      return const [
        'مربی', 'Instructor', 'مدرّب',
        'مربی‌ها', 'Instructors', 'المدرّبون'
      ];
    }
    return const [
      'نفر پرسنل', 'Staff member', 'موظف',
      'پرسنل', 'Staff', 'الموظفون'
    ];
  }

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

  String selfLabel(String l) => _p(
      l, 'خودم هم خدمت می‌دهم', 'I also provide services myself',
      'أقدّم الخدمات بنفسي أيضًا');

  String becomeSelf(String l) => _p(
      l, 'خودم هم خدمت می‌دهم', 'I provide services too',
      'أقدّم الخدمات أيضًا');

  String becomeSelfDesc(String l) => _p(
      l,
      'اگر خودت هم به مشتری‌ها خدمت می‌دهی، اسمت هم در فهرست قرار می‌گیرد تا مشتری‌ها از تو هم نوبت بگیرند.',
      'If you also serve customers yourself, you will be listed too so customers can book with you.',
      'إذا كنت تقدّم الخدمات بنفسك فسيظهر اسمك في القائمة ليتمكن الزبائن من الحجز عندك.');

  String stopSelf(String l) => _p(
      l, 'دیگر خودم خدمت نمی‌دهم', 'I no longer provide services myself',
      'لم أعد أقدّم الخدمات بنفسي');

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
