import 'package:flutter/material.dart';
import '../../app/extra_http.dart';
import '../../app/registry.dart' show kRegistryUrl;
import '../../app/settings.dart';
import '../../app/widgets.dart';

bool get reportAvailable => kRegistryUrl.isNotEmpty;

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'btn': 'گزارش',
    'title': 'گزارش این آرایشگاه',
    'no_service': 'خدمت مورد نظر را ندارد',
    'wrong_info': 'اطلاعات اشتباه است (جنسیت، قیمت، آدرس ...)',
    'bad_contact': 'شماره یا آدرس درست نیست',
    'behavior': 'رفتار نامناسب',
    'other': 'سایر',
    'note': 'توضیح کوتاه',
    'send': 'ارسال گزارش',
    'sent': 'گزارش ارسال شد. ممنون ✅',
    'need': 'یک مورد را انتخاب کنید',
  },
  'en': {
    'btn': 'Report',
    'title': 'Report this shop',
    'no_service': 'It does not offer the service I wanted',
    'wrong_info': 'Wrong information (gender, price, address ...)',
    'bad_contact': 'Phone or address is not correct',
    'behavior': 'Inappropriate behavior',
    'other': 'Other',
    'note': 'Short description',
    'send': 'Send report',
    'sent': 'Report sent. Thank you ✅',
    'need': 'Choose one option',
  },
  'ar': {
    'btn': 'إبلاغ',
    'title': 'الإبلاغ عن هذا الصالون',
    'no_service': 'لا يقدّم الخدمة المطلوبة',
    'wrong_info': 'معلومات خاطئة (النوع، السعر، العنوان ...)',
    'bad_contact': 'الهاتف أو العنوان غير صحيح',
    'behavior': 'سلوك غير لائق',
    'other': 'أخرى',
    'note': 'وصف قصير',
    'send': 'إرسال البلاغ',
    'sent': 'تم إرسال البلاغ. شكرًا ✅',
    'need': 'اختر أحد الخيارات',
  },
};

const List<String> _reasons = ['no_service', 'wrong_info', 'bad_contact', 'behavior', 'other'];

/// دکمه‌ی «گزارش»؛ تا وقتی رجیستری راه نیفتاده چیزی نشان نمی‌دهد
class ReportButton extends StatelessWidget {
  const ReportButton({
    super.key,
    required this.st,
    required this.shopId,
    required this.shopName,
    this.plan = '',
    this.city = '',
    this.server = '',
  });

  final AppSettings st;
  final String shopId;
  final String shopName;
  final String plan;
  final String city;
  final String server;

  @override
  Widget build(BuildContext context) {
    if (!reportAvailable) return const SizedBox.shrink();
    final m = _tx[st.lang] ?? _tx['fa']!;
    return TextButton.icon(
      icon: const Icon(Icons.flag_outlined),
      label: Text(m['btn']!),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ReportBody(
          st: st,
          shopId: shopId,
          shopName: shopName,
          plan: plan,
          city: city,
          server: server,
        ),
      ),
    );
  }
}

class _ReportBody extends StatefulWidget {
  const _ReportBody({
    required this.st,
    required this.shopId,
    required this.shopName,
    required this.plan,
    required this.city,
    required this.server,
  });
  final AppSettings st;
  final String shopId;
  final String shopName;
  final String plan;
  final String city;
  final String server;

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  String _reason = '';
  bool _busy = false;
  final _note = TextEditingController();

  String get _lang => widget.st.lang;
  String _t(String k) => (_tx[_lang] ?? _tx['fa']!)[k] ?? _tx['fa']![k] ?? k;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    if (_reason.isEmpty) {
      toast(context, _t('need'));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final srv = widget.server;
      await extraPost(kRegistryUrl, {
        'action': 'report_send',
        'reason': _reason,
        'note': _note.text.trim(),
        'shop_id': widget.shopId,
        'shop_name': widget.shopName,
        'plan': widget.plan,
        'city': widget.city,
        'server': srv.isEmpty ? 'main' : srv.substring(srv.length > 14 ? srv.length - 14 : 0),
        'lang': _lang,
        'device_id': widget.st.deviceId,
      });
      messenger.showSnackBar(SnackBar(content: Text(_t('sent'))));
      nav.pop();
    } on ExtraError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, extraErrorText(e, _lang));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('title'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final r in _reasons)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: r,
                  groupValue: _reason,
                  title: Text(_t(r)),
                  onChanged: (v) => setState(() => _reason = v ?? ''),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _t('note'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: _t('send'),
                icon: Icons.send_rounded,
                loading: _busy,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
