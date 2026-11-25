import 'business_types.dart';

String _w(String l, String fa, String en, String ar) =>
    l == 'fa' ? fa : (l == 'ar' ? ar : en);

/// گروه کسب‌وکار از روی نوع (پیش‌فرض: زیبایی)
String bwGroup(String? type) => bizTypeByKey(type ?? '')?.group ?? 'beauty';

bool bwBeauty(String? type) => bwGroup(type) == 'beauty';

/// عنوان یک نفر از پرسنل، متناسب با نوع کسب‌وکار
String bwStaff(String? type, String l) {
  final k = type ?? '';
  if (k.isEmpty || k == 'barber') {
    return _w(l, 'آرایشگر', 'Barber', 'حلاق');
  }
  final g = bwGroup(k);
  if (g == 'beauty') return _w(l, 'آرایشگر', 'Stylist', 'مصفّف');
  if (g == 'edu') return _w(l, 'مربی', 'Instructor', 'مدرّب');
  return _w(l, 'نفر پرسنل', 'Staff member', 'موظف');
}

/// جمع
String bwStaffs(String? type, String l) {
  final k = type ?? '';
  if (k.isEmpty || k == 'barber') {
    return _w(l, 'آرایشگرها', 'Barbers', 'الحلاقون');
  }
  final g = bwGroup(k);
  if (g == 'beauty') return _w(l, 'آرایشگرها', 'Stylists', 'المصفّفون');
  if (g == 'edu') return _w(l, 'مربی‌ها', 'Instructors', 'المدرّبون');
  return _w(l, 'پرسنل', 'Staff', 'الموظفون');
}

/// «آرایشگاه» برای گروه زیبایی، «کسب‌وکار» برای بقیه
String bwShop(String? type, String l) {
  if (bwBeauty(type)) return _w(l, 'آرایشگاه', 'shop', 'الصالون');
  return _w(l, 'کسب‌وکار', 'business', 'النشاط التجاري');
}
