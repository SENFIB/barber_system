import 'package:barber_core/barber_core.dart';
import 'strings.dart';

/// متن‌های پرداخت با تتر و درخواست پلن (فارسی، انگلیسی، عربی)
class PayT {
  const PayT(this.lang);
  final String lang;
  int get _i => lang == 'en' ? 1 : (lang == 'ar' ? 2 : 0);
  bool has(String k) => _d.containsKey(k);
  String t(String k, [Map<String, dynamic>? a]) {
    final v = _d[k];
    if (v == null) return k;
    var s = v[_i];
    a?.forEach((key, val) {
      s = s.replaceAll('{$key}', '$val');
    });
    return s;
  }

  String errorCode(String code) =>
      has('err_$code') ? t('err_$code') : t('err_NETWORK');

  String error(ApiException e) =>
      has('err_${e.code}') ? t('err_${e.code}') : S(lang).error(e);

  static const Map<String, List<String>> _d = {
    'title': ['پرداخت با تتر', 'Pay with USDT', 'الدفع بعملة USDT'],
    'buy_usdt': ['خرید با تتر', 'Buy with USDT', 'الشراء بعملة USDT'],
    'cancel': ['انصراف', 'Cancel', 'إلغاء'],
    'retry': ['تلاش دوباره', 'Try again', 'حاول مجددًا'],
    'copied': ['کپی شد', 'Copied', 'تم النسخ'],
    'send_exact': [
      'این مبلغ را دقیقاً به آدرس زیر بفرستید',
      'Send exactly this amount to the address below',
      'أرسل هذا المبلغ بالضبط إلى العنوان التالي'
    ],
    'amount': ['مبلغ (USDT)', 'Amount (USDT)', 'المبلغ (USDT)'],
    'address': ['آدرس کیف پول', 'Wallet address', 'عنوان المحفظة'],
    'network': ['شبکه', 'Network', 'الشبكة'],
    'net_name': ['ترون (TRC20)', 'TRON (TRC20)', 'ترون (TRC20)'],
    'order_id': ['شناسه‌ی سفارش', 'Order ID', 'رقم الطلب'],
    'time_left': [
      'مهلت پرداخت: {m}',
      'Time left: {m}',
      'الوقت المتبقي: {m}'
    ],
    'expired_note': [
      'مهلت سفارش تمام شد. اگر قبل از آن پرداخت کرده‌اید TXID را بفرستید؛ وگرنه سفارش جدید بسازید.',
      'The order time is over. If you paid before that, send the TXID; otherwise create a new order.',
      'انتهت مهلة الطلب. إذا دفعت قبل ذلك أرسل معرّف المعاملة، وإلا فأنشئ طلبًا جديدًا.'
    ],
    'new_order': ['سفارش جدید', 'New order', 'طلب جديد'],
    'warn_net': [
      'فقط USDT روی شبکه‌ی ترون (TRC20) بفرستید. شبکه‌ی دیگر یعنی از دست رفتن پول.',
      'Send only USDT on the TRON (TRC20) network. Any other network means lost funds.',
      'أرسل USDT فقط على شبكة ترون (TRC20). أي شبكة أخرى تعني ضياع المبلغ.'
    ],
    'warn_amount': [
      'مبلغ باید دقیقاً همین عدد (با اعشار) باشد. اگر از صرافی می‌فرستید، کارمزد را جدا اضافه کنید تا مبلغ رسیده کم نشود.',
      'The amount must be exactly this number (with decimals). If you send from an exchange, add the fee on top so the received amount is not lower.',
      'يجب أن يكون المبلغ هذا الرقم بالضبط (مع الكسور). إذا أرسلت من منصة تداول فأضف الرسوم فوقه حتى لا ينقص المبلغ المستلم.'
    ],
    'txid_label': [
      'شناسه‌ی تراکنش (TXID)',
      'Transaction ID (TXID)',
      'معرّف المعاملة (TXID)'
    ],
    'txid_hint': [
      'بعد از ارسال، TXID را از کیف پول یا صرافی کپی کنید و اینجا بچسبانید',
      'After sending, copy the TXID from your wallet or exchange and paste it here',
      'بعد الإرسال انسخ معرّف المعاملة من محفظتك أو المنصة والصقه هنا'
    ],
    'check_btn': [
      'پرداخت کردم؛ بررسی کن',
      'I have paid, verify',
      'لقد دفعت، تحقق'
    ],
    'need_txid': ['TXID را وارد کنید', 'Enter the TXID', 'أدخل معرّف المعاملة'],
    'status_btn': [
      'بررسی وضعیت سفارش',
      'Check order status',
      'التحقق من حالة الطلب'
    ],
    'still_pending': [
      'هنوز پرداختی برای این سفارش تأیید نشده',
      'No confirmed payment for this order yet',
      'لم يتم تأكيد دفعة لهذا الطلب بعد'
    ],
    'review': [
      'پرداخت شما ثبت شد و در حال بررسی است. شناسه‌ی سفارش: {id}',
      'Your payment is recorded and under review. Order ID: {id}',
      'تم تسجيل دفعتك وهي قيد المراجعة. رقم الطلب: {id}'
    ],
    'paid_ok': [
      'پرداخت تأیید شد ✅',
      'Payment confirmed ✅',
      'تم تأكيد الدفع ✅'
    ],
    'paid_license': ['کد لایسنس شما', 'Your license code', 'رمز الترخيص الخاص بك'],
    'paid_keep': [
      'این کد را نگه دارید. اگر فعال‌سازی خودکار انجام نشد، با دکمه‌ی زیر دوباره امتحان کنید.',
      'Keep this code. If automatic activation fails, try again with the button below.',
      'احتفظ بهذا الرمز. إذا فشل التفعيل التلقائي فحاول مجددًا بالزر أدناه.'
    ],
    'activate_btn': ['فعال‌سازی پلن', 'Activate plan', 'تفعيل الخطة'],
    'activated': ['پلن فعال شد ✅', 'Plan activated ✅', 'تم تفعيل الخطة ✅'],
    // درخواست پلن ویژه / شخصی
    'req_btn': ['ثبت درخواست', 'Send request', 'إرسال الطلب'],
    'req_title': [
      'درخواست پلن {plan}',
      'Request the {plan} plan',
      'طلب خطة {plan}'
    ],
    'req_desc': [
      'این پلن با هماهنگی راه‌اندازی می‌شود. راه تماس‌تان را بنویسید تا با شما تماس بگیریم.',
      'This plan is set up together with you. Leave your contact so we can reach you.',
      'يتم إعداد هذه الخطة بالتنسيق معك. اترك وسيلة اتصال لنتواصل معك.'
    ],
    'req_contact': [
      'راه تماس (شماره یا آیدی تلگرام)',
      'Contact (phone or Telegram ID)',
      'وسيلة الاتصال (رقم أو معرّف تيليجرام)'
    ],
    'req_note': ['توضیحات (اختیاری)', 'Notes (optional)', 'ملاحظات (اختياري)'],
    'req_send': ['ارسال', 'Send', 'إرسال'],
    'req_ok': [
      'درخواست ثبت شد. به‌زودی با شما تماس می‌گیریم ✅',
      'Request sent. We will contact you soon ✅',
      'تم إرسال الطلب. سنتواصل معك قريبًا ✅'
    ],
    // خطاها
    'err_NETWORK': [
      'اتصال برقرار نشد. اینترنت را بررسی کنید',
      'Could not connect. Check your internet',
      'تعذر الاتصال. تحقق من الإنترنت'
    ],
    'err_PAY_DISABLED': [
      'پرداخت با تتر فعلاً فعال نیست. بعداً امتحان کنید',
      'USDT payment is not available right now',
      'الدفع بعملة USDT غير متاح حاليًا'
    ],
    'err_PAY_NOT_AUTO': [
      'این پلن با پرداخت خودکار فروخته نمی‌شود؛ درخواست ثبت کنید',
      'This plan is not sold with automatic payment; send a request',
      'هذه الخطة لا تُباع بالدفع التلقائي؛ أرسل طلبًا'
    ],
    'err_PAY_NOT_FOR_SALE': [
      'این پلن فعلاً رایگان است',
      'This plan is free for now',
      'هذه الخطة مجانية حاليًا'
    ],
    'err_PAY_BUSY': [
      'سفارش‌های باز زیاد است، چند دقیقه بعد امتحان کنید',
      'Too many open orders, try again in a few minutes',
      'الطلبات المفتوحة كثيرة، حاول بعد دقائق'
    ],
    'err_PAY_NOT_FOUND': ['سفارش پیدا نشد', 'Order not found', 'الطلب غير موجود'],
    'err_PAY_CLOSED': [
      'این سفارش بسته شده است',
      'This order is closed',
      'هذا الطلب مغلق'
    ],
    'err_PAY_EXPIRED': [
      'این سفارش منقضی شده است؛ سفارش جدید بسازید',
      'This order has expired; create a new one',
      'انتهى هذا الطلب؛ أنشئ طلبًا جديدًا'
    ],
    'err_PAY_BAD_TXID': [
      'TXID معتبر نیست (۶۴ حرف و عدد)',
      'Invalid TXID (64 letters and digits)',
      'معرّف المعاملة غير صالح (64 حرفًا ورقمًا)'
    ],
    'err_PAY_TXID_USED': [
      'این TXID قبلاً استفاده شده است',
      'This TXID has already been used',
      'تم استخدام هذا المعرّف سابقًا'
    ],
    'err_PAY_NOT_CONFIRMED': [
      'تراکنش هنوز در شبکه تأیید نشده؛ یک دقیقه بعد دوباره بررسی کنید',
      'The transaction is not confirmed yet; check again in a minute',
      'لم تُؤكَّد المعاملة بعد؛ تحقق مجددًا بعد دقيقة'
    ],
    'err_PAY_TX_FAILED': [
      'این تراکنش ناموفق بوده است',
      'This transaction failed',
      'فشلت هذه المعاملة'
    ],
    'err_PAY_NO_TRANSFER': [
      'در این تراکنش انتقال USDT به آدرس ما پیدا نشد',
      'No USDT transfer to our address was found in this transaction',
      'لم يتم العثور على تحويل USDT إلى عنواننا في هذه المعاملة'
    ],
    'err_PAY_TX_OLD': [
      'این تراکنش مربوط به قبل از ساخت سفارش است',
      'This transaction was made before the order was created',
      'تمت هذه المعاملة قبل إنشاء الطلب'
    ],
    'err_PAY_AMOUNT_MISMATCH': [
      'مبلغ ارسالی با مبلغ سفارش یکی نیست. پرداخت برای بررسی ثبت شد؛ شناسه‌ی سفارش را به پشتیبانی بدهید.',
      'The amount sent differs from the order amount. The payment was recorded for review; give the order ID to support.',
      'المبلغ المرسل يختلف عن مبلغ الطلب. تم تسجيل الدفعة للمراجعة؛ أعطِ رقم الطلب للدعم.'
    ],
    'err_PAY_CHAIN_BUSY': [
      'سرویس بلاک‌چین پاسخ نداد؛ کمی بعد دوباره امتحان کنید',
      'The blockchain service did not respond; try again shortly',
      'لم تستجب خدمة البلوكتشين؛ حاول بعد قليل'
    ],
  };
}
