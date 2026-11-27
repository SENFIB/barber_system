import 'package:flutter/material.dart';

import 'fmt.dart';
import 'plans_config.dart';

const Map<String, List<String>> _tx = {
  'name': ['رایگان', 'Free', 'مجانية'],
  'price': ['{d} روز رایگان', '{d} days free', '{d} أيام مجانًا'],
  'f_staff': ['یک نفر پرسنل', 'One staff member', 'موظف واحد'],
  'f_shift': [
    'یک شیفت کاری در روز',
    'One work shift a day',
    'فترة عمل واحدة يوميًا'
  ],
  'f_cap': [
    'حداکثر {c} نوبت در روز برای کل کسب‌وکار',
    'Up to {c} bookings a day for the whole business',
    'حتى {c} حجوزات يوميًا للنشاط التجاري كله'
  ],
  'f_book': [
    'رزرو آنلاین مشتری',
    'Online customer booking',
    'حجز العملاء عبر الإنترنت'
  ],
  'f_cleanup': [
    'پاکسازی روزانه نوبت‌های گذشته',
    'Past bookings cleaned daily',
    'تنظيف الحجوزات القديمة يوميًا'
  ],
  'warn': [
    'این پلن فقط {d} روز رایگان است. بعد از {d} روز همهٔ اطلاعات کسب‌وکار شما کاملاً پاک می‌شود، مگر اینکه یکی از پلن‌های پولی را بخرید.',
    'This plan is free for {d} days only. After {d} days all your business data is permanently deleted, unless you buy a paid plan.',
    'هذه الباقة مجانية لمدة {d} أيام فقط. بعد {d} أيام تُحذف جميع بيانات نشاطك التجاري نهائيًا ما لم تشترِ باقة مدفوعة.'
  ],
  'days_left': [
    'تا پاک‌شدن اطلاعات: {n} روز مانده',
    'Your data will be deleted in {n} days',
    'سيتم حذف بياناتك بعد {n} أيام'
  ],
  'upgrade': [
    'برای نگه‌داشتن اطلاعات، یکی از پلن‌های زیر را بخرید.',
    'To keep your data, buy one of the plans below.',
    'للاحتفاظ ببياناتك، اشترِ إحدى الباقات أدناه.'
  ],
  'upgrade_btn': [
    'خرید پلن و نگه‌داشتن اطلاعات',
    'Buy a plan and keep your data',
    'اشترِ باقة واحتفظ ببياناتك'
  ],
  'ended': [
    'هفتهٔ رایگان شما تمام شد. برای نگه‌داشتن اطلاعات، یک پلن بخرید.',
    'Your free week has ended. Buy a plan to keep your data.',
    'انتهى أسبوعك المجاني. اشترِ باقة للاحتفاظ ببياناتك.'
  ],
};

/// متن پلن رایگان به زبان [lang] (fa / en / ar)
String freeTx(String lang, String key, [Map<String, Object?> args = const {}]) {
  final o = _tx[key];
  if (o == null) return key;
  var s = lang == 'fa' ? o[0] : (lang == 'ar' ? o[2] : o[1]);
  s = s
      .replaceAll('{d}', fmtNum(kFreeDays, lang))
      .replaceAll('{c}', fmtNum(kFreeMaxBookingsPerDay, lang));
  args.forEach((k, v) {
    s = s.replaceAll('{$k}', '$v');
  });
  return s;
}

/// جعبهٔ هشدار «اطلاعات پلن رایگان بعد از چند روز پاک می‌شود»
class FreeWarning extends StatelessWidget {
  const FreeWarning({super.key, required this.lang, this.text});
  final String lang;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x26FF9800),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x80FF9800)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text ?? freeTx(lang, 'warn'),
              style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
