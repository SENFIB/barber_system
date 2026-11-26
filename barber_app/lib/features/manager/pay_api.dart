import 'package:barber_core/barber_core.dart';
import '../../app/config.dart';
import '../../app/servers.dart';
import '../../app/settings.dart';
import 'shop_raw.dart';

class PayOrder {
  const PayOrder({
    required this.payId,
    required this.plan,
    required this.months,
    required this.amountText,
    required this.address,
    required this.network,
    required this.secondsLeft,
  });
  final String payId;
  final String plan;
  final int months;
  final String amountText;
  final String address;
  final String network;
  final int secondsLeft;

  factory PayOrder.fromJson(Map<String, dynamic> j) => PayOrder(
        payId: jStr(j['pay_id']),
        plan: jStr(j['plan']),
        months: jInt(j['months']) ?? 1,
        amountText: jStr(j['amount_text']),
        address: jStr(j['address']),
        network: jStr(j['network']),
        secondsLeft: jInt(j['seconds_left']) ?? 0,
      );
}

class PayResult {
  const PayResult({
    required this.payId,
    required this.status,
    required this.licenseKey,
  });
  final String payId;
  final String status; // pending | review | paid | ...
  final String licenseKey;

  bool get isPaid => status == 'paid' && licenseKey.isNotEmpty;

  factory PayResult.fromJson(Map<String, dynamic> j) => PayResult(
        payId: jStr(j['pay_id']),
        status: jStr(j['status']),
        licenseKey: jStr(j['license_key']),
      );
}

/// پرداخت با تتر. سفارش پایه روی سرور اصلی و سفارش پرو روی سرور پرو ساخته می‌شود
/// (همان سروری که لایسنس آن پلن را دارد).
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

  Future<PayOrder> create(String plan, int months) async =>
      PayOrder.fromJson(await _call(
          urlForPlan(plan), 'pay_create', {'plan': plan, 'months': months}));

  Future<PayResult> submit(String plan, String payId, String txid) async =>
      PayResult.fromJson(await _call(urlForPlan(plan), 'pay_submit',
          {'pay_id': payId, 'txid': txid.trim()}));

  Future<PayResult> status(String plan, String payId) async =>
      PayResult.fromJson(
          await _call(urlForPlan(plan), 'pay_status', {'pay_id': payId}));

  /// درخواست پلن ویژه/شخصی؛ همیشه روی سرور اصلی ثبت می‌شود
  Future<void> request({
    required String plan,
    required int months,
    required String shopName,
    required String phone,
    required String contact,
    String note = '',
  }) async {
    await _call(kDefaultApiUrl, 'pay_request', {
      'plan': plan,
      'months': months,
      'shop_name': shopName,
      'phone': phone,
      'contact': contact,
      'note': note,
    });
  }
}
