import 'package:flutter/material.dart';
import 'biz_icons.dart';
import 'biz_words.dart';
import 'business_types.dart';

String _p(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

/// نقش‌های پشتیبان که نوبت نمی‌گیرند (منشی، نظافتچی)
class SupportRole {
  const SupportRole(this.key, this.fa, this.en, this.ar, this.icon);
  final String key;
  final String fa;
  final String en;
  final String ar;
  final IconData icon;
  String name(String l) => _p(l, fa, en, ar);
}

const List<SupportRole> kSupportRoles = [
  SupportRole('secretary', 'منشی', 'Receptionist', 'سكرتير',
      Icons.support_agent_rounded),
  SupportRole('cleaner', 'نظافتچی', 'Cleaner', 'عامل نظافة',
      Icons.cleaning_services_rounded),
];

/// اگر متن «تخصص/نقش» یکی از نقش‌های پشتیبان باشد همان را برمی‌گرداند
SupportRole? supportRoleOf(String text) {
  final t = text.trim().toLowerCase();
  if (t.isEmpty) return null;
  for (final r in kSupportRoles) {
    if (t == r.fa || t == r.en.toLowerCase() || t == r.ar) return r;
  }
  return null;
}

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

  // یک منبع واژه برای همه‌ی صفحه‌ها (همان فهرست biz_words)
  List<String> get _n => bwRole(type);

  String noun(String l) => _p(l, _n[0], _n[1], _n[2]);
  String plural(String l) => _p(l, _n[3], _n[4], _n[5]);

  String staffTitle(String l) => _p(l, 'مدیریت ${_n[3]}',
      'Manage ${_n[4].toLowerCase()}', 'إدارة ${_n[5]}');

  String staffDesc(String l) => _p(
      l,
      'افزودن ${_n[0]}، منشی و ...، ساعت کار و خدماتشان',
      'Add ${_n[1].toLowerCase()}, receptionists and more, their hours and services',
      'إضافة ${_n[2]} وسكرتير وغيرهم، وساعات عملهم وخدماتهم');

  String staffMine(String l) => _p(l, 'ساعت کار من', 'My schedule', 'جدولي');
  String addStaff(String l) =>
      _p(l, 'افزودن نفر', 'Add a person', 'إضافة شخص');
  String staffName(String l) => _p(l, 'نام', 'Name', 'الاسم');
  String roleLabel(String l) => _p(l, 'نقش', 'Role', 'الدور');
  String roleOther(String l) => _p(l, 'سایر', 'Other', 'أخرى');
  String roleOtherHint(String l) => _p(
      l, 'نقش را بنویس، مثلاً حسابدار', 'Type the role, e.g. accountant',
      'اكتب الدور، مثلاً محاسب');
  String addHint(String l) => _p(
      l,
      'نام را بنویس و نقش را انتخاب کن؛ بعد از ساخت می‌توانی ساعت کار و خدمات را تنظیم کنی.',
      'Type the name and pick a role; afterwards you can set working hours and services.',
      'اكتب الاسم واختر الدور؛ بعدها يمكنك ضبط ساعات العمل والخدمات.');

  /// «خودم هم مشغول کارم» (زیبایی) / «خودم هم فعالیت می‌کنم» (بقیه)
  String selfLabel(String l) => beauty
      ? _p(l, 'خودم هم مشغول کارم', 'I also work here myself',
          'أنا أيضًا مشغول بالعمل')
      : _p(l, 'خودم هم فعالیت می‌کنم', 'I am also active myself',
          'أنا أيضًا أعمل بنفسي');

  String becomeSelf(String l) => selfLabel(l);

  String becomeSelfDesc(String l) => _p(
      l,
      'اگر خودت هم کار می‌کنی، اسمت هم در فهرست قرار می‌گیرد تا مشتری‌ها از تو هم نوبت بگیرند.',
      'If you also work yourself, you will be listed too so customers can book with you.',
      'إذا كنت تعمل بنفسك فسيظهر اسمك في القائمة ليتمكن الزبائن من الحجز عندك.');

  String stopSelf(String l) => beauty
      ? _p(l, 'دیگر خودم مشغول کار نیستم', 'I no longer work here myself',
          'لم أعد أعمل بنفسي')
      : _p(l, 'دیگر خودم فعالیت نمی‌کنم', 'I am no longer active myself',
          'لم أعد أعمل بنفسي');

  String stopSelfConfirm(String l) => _p(
      l,
      'نام تو از فهرستی که مشتری‌ها از آن نوبت می‌گیرند برداشته می‌شود. ادامه می‌دهی؟',
      'Your name will be removed from the list customers book from. Continue?',
      'سيُحذف اسمك من القائمة التي يحجز منها الزبائن. هل تريد المتابعة؟');

  String ownerLabel(String l) => _p(l, 'مدیر', 'Owner', 'المدير');

  String noStaff(String l) => _p(l, 'هنوز کسی اضافه نشده',
      'No one has been added yet', 'لم تتم إضافة أحد بعد');
  String capacity(String l, String n, String max) => _p(
      l,
      'ظرفیت: $n از $max نفر',
      'Capacity: $n of $max',
      'السعة: $n من $max');

  String msgTitle(String l) => beauty
      ? _p(l, 'پیام اختصاصی آرایشگاه', 'Custom shop message',
          'رسالة خاصة بالصالون')
      : _p(l, 'پیام اختصاصی کسب‌وکار', 'Custom business message',
          'رسالة خاصة بالنشاط التجاري');
}
