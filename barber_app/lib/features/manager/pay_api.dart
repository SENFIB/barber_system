import 'package:barber_core/barber_core.dart';
import '../../app/config.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';
import 'shop_raw.dart';

num? _num(dynamic v) {
  if (v is num) return v;
  if (v == null) return null;
  return num.tryParse('$v'.trim());
}

/// ثانیه‌ی باقی‌مانده تا پایان مهلت سفارش
int _secondsLeft(Map<String, dynamic> j, String method) {
  final s = jInt(j['seconds_left']);
  if (s != null) return s < 0 ? 0 : s;
  final e = j['expires_at'];
  DateTime? d;
  final n = _num(e);
  if (n != null) {
    final v = n.toInt();
    d = DateTime.fromMillisecondsSinceEpoch(v > 100000000000 ? v : v * 1000);
  } else if (e != null) {
    d = DateTime.tryParse('$e');
  }
  if (d != null) {
    final l = d.difference(DateTime.now()).inSeconds;
    return l < 0 ? 0 : l;
  }
  return method == 'card' ? 86400 : 10800;
}

class PayOrder {
  const PayOrder({
    required this.payId,
    required this.plan,
    required this.months,
    required this.method,
    required this.currency,
    required this.amountValue,
    required this.amountText,
    required this.address,
    required this.network,
    required this.cardNumber,
    required this.cardHolder,
    required this.secondsLeft,
  });

  final String payId;
  final String plan;
  final int months;

  /// usdt | card
  final String method;

  /// USDT | TOMAN
  final String currency;
  final num amountValue;
  final String amountText;
  final String address;
  final String network;
  final String cardNumber;
  final String cardHolder;
  final int secondsLeft;

  bool get isCard => method == 'card';

  /// شماره کارت بدون فاصله (برای کپی)
  String get cardDigits => cardNumber.replaceAll(RegExp(r'\D'), '');

  factory PayOrder.fromJson(Map<String, dynamic> j, {String method = 'usdt'}) {
    final m = jStr(j['method']).isEmpty ? method : jStr(j['method']);
    final amount = _num(j['amount']) ?? 0;
    var text = jStr(j['amount_text']);
    if (text.isEmpty && amount > 0) {
      text = m == 'card' ? '${amount.round()}' : amount.toStringAsFixed(3);
    }
    var cur = jStr(j['currency']);
    if (cur.isEmpty) cur = m == 'card' ? 'TOMAN' : 'USDT';
    return PayOrder(
      payId: jStr(j['pay_id']),
      plan: jStr(j['plan']),
      months: jInt(j['months']) ?? 1,
      method: m,
      currency: cur,
      amountValue: amount,
      amountText: text,
      address: jStr(j['address']),
      network: jStr(j['network']),
      cardNumber: jStr(j['card_number']),
      cardHolder: jStr(j['card_holder']),
      secondsLeft: _secondsLeft(j, m),
    );
  }
}

class PayResult {
  const PayResult({
    required this.payId,
    required this.status,
    required this.licenseKey,
  });

  final String payId;
  final String status; // pending | review | paid | rejected
  final String licenseKey;

  bool get isPaid => status == 'paid' && licenseKey.isNotEmpty;

  factory PayResult.fromJson(Map<String, dynamic> j) => PayResult(
        payId: jStr(j['pay_id']),
        status: jStr(j['status']),
        licenseKey: jStr(j['license_key']),
      );
}

/// پرداخت (تتر و کارت‌به‌کارت). سفارش پایه روی سرور اصلی و سفارش پرو روی
/// سرور پرو ساخته می‌شود (همان سروری که لایسنس آن پلن را دارد).
class PayApi {
  PayApi(this.st);
  final AppSettings st;

  String urlForPlan(String plan) =>
      plan == 'pro' && kProApiUrl.isNotEmpty ? kProApiUrl : kDefaultApiUrl;

  Future<Map<String, dynamic>> _call(
      String url, String action, Map<String, dynamic> p) async {
    final dynamic d =
        await ApiClient(url).call(action, {...p, 'device_id': st.deviceId});
    return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
  }

  /// method: 'usdt' یا 'card'
  Future<PayOrder> create(
    String plan,
    int months, {
    String method = 'usdt',
    String? lang,
  }) async {
    final j = await _call(urlForPlan(plan), 'pay_create', {
      'plan': plan,
      'months': months,
      'method': method,
      'lang': lang ?? st.lang,
    });
    return PayOrder.fromJson(j, method: method);
  }

  /// ثبت TXID (تتر)
  Future<PayResult> submit(String plan, String payId, String txid) async =>
      PayResult.fromJson(await _call(urlForPlan(plan), 'pay_submit',
          {'pay_id': payId, 'txid': txid.trim()}));

  /// ثبت اطلاعات واریز کارت‌به‌کارت (فقط ۴ رقم آخر کارت)
  Future<PayResult> card(
    String plan,
    String payId, {
    required String last4,
    required String payerName,
    required String refNo,
    required String shopName,
    required String phone,
  }) async =>
      PayResult.fromJson(await _call(urlForPlan(plan), 'pay_card', {
        'pay_id': payId,
        'card_last4': last4,
        'payer_name': payerName,
        'ref_no': refNo,
        'shop_name': shopName,
        'phone': phone,
      }));

  Future<PayResult> status(String plan, String payId) async =>
      PayResult.fromJson(
          await _call(urlForPlan(plan), 'pay_status', {'pay_id': payId}));
}
