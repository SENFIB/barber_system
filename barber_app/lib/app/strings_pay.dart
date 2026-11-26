import 'package:barber_core/barber_core.dart';
import 'strings.dart';

/// متن‌های پرداخت (تتر و کارت‌به‌کارت) و خرید پلن ویژه (فارسی، انگلیسی، عربی)
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

  // ---- ایمیل خرید پلن ویژه: همیشه فارسی (برای خواندن راحت‌تر توسط توسعه‌دهنده) ----
  static String _faPlan(String key) {
    switch (key) {
      case 'basic':
        return 'پایه';
      case 'pro':
        return 'پرو';
      case 'special':
        return 'ویژه';
    }
    return key;
  }

  static String mailSubject(String planKey) =>
      'درخواست خرید پلن ${_faPlan(planKey)}';

  static String mailBody({
    required String planKey,
    required String shopName,
    required String phone,
    required String username,
  }) =>
      'سلام،\n'
      'می‌خواهم پلن ${_faPlan(planKey)} را بخرم.\n\n'
      'نام کسب‌وکار: $shopName\n'
      'شماره تلفن: $phone\n'
      'نام کاربری: $username\n'
      'پلن: ${_faPlan(planKey)}\n';

  static const Map<String, List<String>> _d = {
    // ---- عمومی ----
    'title': ['پرداخت', 'Payment', 'الدفع'],
    'title_usdt': ['پرداخت با تتر', 'Pay with USDT', 'الدفع بعملة USDT'],
    'title_card': [
      'پرداخت کارت‌به‌کارت',
      'Card-to-card payment',
      'الدفع بالتحويل بين البطاقات'
    ],
    'buy_usdt': ['خرید با تتر', 'Buy with USDT', 'الشراء بعملة USDT'],
    'buy_card': [
      'خرید کارت‌به‌کارت (تومان)',
      'Buy by card-to-card (Toman)',
      'الشراء بتحويل بطاقة (تومان)'
    ],
    'method_title': [
      'روش پرداخت',
      'Payment method',
      'طريقة الدفع'
    ],
    'cancel': ['انصراف', 'Cancel', 'إلغاء'],
    'retry': ['تلاش دوباره', 'Try again', 'حاول مجددًا'],
    'copied': ['کپی شد', 'Copied', 'تم النسخ'],
    'order_id': ['شناسه‌ی سفارش', 'Order ID', 'رقم الطلب'],
    'new_order': ['سفارش جدید', 'New order', 'طلب جديد'],
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
    'time_left': [
      'مهلت پرداخت: {m}',
      'Time left: {m}',
      'الوقت المتبقي: {m}'
    ],

    // ---- تتر ----
    'send_exact': [
      'این مبلغ را دقیقاً به آدرس زیر بفرستید',
      'Send exactly this amount to the address below',
      'أرسل هذا المبلغ بالضبط إلى العنوان التالي'
    ],
    'amount': ['مبلغ (USDT)', 'Amount (USDT)', 'المبلغ (USDT)'],
    'address': ['آدرس کیف پول', 'Wallet address', 'عنوان المحفظة'],
    'network': ['شبکه', 'Network', 'الشبكة'],
    'net_name': ['ترون (TRC20)', 'TRON (TRC20)', 'ترون (TRC20)'],
    'expired_note': [
      'مهلت سفارش تمام شد. اگر قبل از آن پرداخت کرده‌اید TXID را بفرستید؛ وگرنه سفارش جدید بسازید.',
      'The order time is over. If you paid before that, send the TXID; otherwise create a new order.',
      'انتهت مهلة الطلب. إذا دفعت قبل ذلك أرسل معرّف المعاملة، وإلا فأنشئ طلبًا جديدًا.'
    ],
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
    'review': [
      'پرداخت شما ثبت شد و در حال بررسی است. شناسه‌ی سفارش: {id}',
      'Your payment is recorded and under review. Order ID: {id}',
      'تم تسجيل دفعتك وهي قيد المراجعة. رقم الطلب: {id}'
    ],

    // ---- کارت‌به‌کارت ----
    'card_send': [
      'مبلغ زیر را به کارت زیر واریز کنید',
      'Transfer the amount below to the card below',
      'حوّل المبلغ التالي إلى البطاقة التالية'
    ],
    'amount_toman': ['مبلغ (تومان)', 'Amount (Toman)', 'المبلغ (تومان)'],
    'card_number': ['شماره کارت', 'Card number', 'رقم البطاقة'],
    'card_holder': ['به نام', 'Card holder', 'باسم'],
    'card_form_title': [
      'بعد از واریز، اطلاعات پرداخت را وارد کنید',
      'After transferring, enter the payment details',
      'بعد التحويل أدخل بيانات الدفع'
    ],
    'card_last4': [
      '۴ رقم آخر کارت شما',
      'Last 4 digits of your card',
      'آخر 4 أرقام من بطاقتك'
    ],
    'payer_name': [
      'نام صاحب کارت (واریزکننده)',
      'Name of the card owner (payer)',
      'اسم صاحب البطاقة (الدافع)'
    ],
    'ref_no': [
      'شماره پیگیری / مرجع تراکنش',
      'Tracking / reference number',
      'رقم التتبع / المرجع'
    ],
    'card_note': [
      'فقط ۴ رقم آخر کارت را وارد کنید. شماره کامل کارت شما را نمی‌خواهیم و ذخیره نمی‌کنیم.',
      'Enter only the last 4 digits of your card. We do not ask for or store your full card number.',
      'أدخل آخر 4 أرقام فقط. لا نطلب رقم بطاقتك الكامل ولا نخزنه.'
    ],
    'card_submit': ['ثبت پرداخت', 'Submit payment', 'تسجيل الدفع'],
    'card_need_last4': [
      '۴ رقم آخر کارت را وارد کنید',
      'Enter the last 4 digits of the card',
      'أدخل آخر 4 أرقام من البطاقة'
    ],
    'card_need_name': [
      'نام صاحب کارت را وارد کنید',
      'Enter the card owner name',
      'أدخل اسم صاحب البطاقة'
    ],
    'card_need_ref': [
      'شماره پیگیری را وارد کنید',
      'Enter the reference number',
      'أدخل رقم المرجع'
    ],
    'card_wait_title': [
      'در انتظار تأیید ⏳',
      'Waiting for approval ⏳',
      'بانتظار الموافقة ⏳'
    ],
    'card_wait': [
      'پرداخت شما ثبت شد و پس از بررسی تأیید می‌شود. این صفحه را باز نگه دارید و با دکمه‌ی زیر وضعیت را بررسی کنید. شناسه‌ی سفارش: {id}',
      'Your payment is recorded and will be approved after review. Keep this page open and check the status with the button below. Order ID: {id}',
      'تم تسجيل دفعتك وستتم الموافقة بعد المراجعة. أبقِ هذه الصفحة مفتوحة وتحقق من الحالة بالزر أدناه. رقم الطلب: {id}'
    ],
    'card_rejected': [
      'این پرداخت تأیید نشد. اگر اشتباهی رخ داده با پشتیبانی تماس بگیرید و شناسه‌ی سفارش را بدهید: {id}',
      'This payment was not approved. If this is a mistake, contact support with the order ID: {id}',
      'لم تتم الموافقة على هذه الدفعة. إذا كان هناك خطأ فتواصل مع الدعم مع رقم الطلب: {id}'
    ],

    // ---- پس از پرداخت ----
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

    // ---- خرید پلن ویژه با ایمیل ----
    'mail_btn': [
      'برای خرید به توسعه‌دهنده پیام بدهید',
      'To buy, message the developer',
      'للشراء، راسل المطوّر'
    ],
    'mail_copied': [
      'برنامه‌ی ایمیل پیدا نشد. آدرس کپی شد: {e}',
      'No mail app found. Address copied: {e}',
      'لم يتم العثور على تطبيق بريد. تم نسخ العنوان: {e}'
    ],

    // ---- خطاها ----
    'err_NETWORK': [
      'اتصال برقرار نشد. اینترنت را بررسی کنید',
      'Could not connect. Check your internet',
      'تعذر الاتصال. تحقق من الإنترنت'
    ],
    'err_PAY_DISABLED': [
      'پرداخت فعلاً فعال نیست. بعداً امتحان کنید',
      'Payment is not available right now',
      'الدفع غير متاح حاليًا'
    ],
    'err_PAY_NOT_AUTO': [
      'این پلن پرداخت آنلاین ندارد؛ برای خرید به توسعه‌دهنده پیام بدهید',
      'This plan has no online payment; message the developer to buy',
      'هذه الخطة بلا دفع إلكتروني؛ راسل المطوّر للشراء'
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
    'err_PAY_CARD_FA_ONLY': [
      'پرداخت کارت‌به‌کارت فقط برای زبان فارسی فعال است',
      'Card-to-card payment is only available in Persian',
      'الدفع بالبطاقة متاح فقط باللغة الفارسية'
    ],
    'err_PAY_BAD_CARD': [
      '۴ رقم آخر کارت معتبر نیست',
      'The last 4 digits are not valid',
      'آخر 4 أرقام غير صالحة'
    ],
    'err_PAY_BAD_NAME': [
      'نام صاحب کارت معتبر نیست',
      'The card owner name is not valid',
      'اسم صاحب البطاقة غير صالح'
    ],
    'err_PAY_NOT_CARD': [
      'این سفارش از نوع کارت‌به‌کارت نیست',
      'This order is not a card-to-card order',
      'هذا الطلب ليس من نوع التحويل بالبطاقة'
    ],
  };
}
