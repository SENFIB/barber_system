import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/legal_texts.dart';
import 'contact_box.dart';

/// ذخیرهٔ تأیید حریم خصوصی (مستقل از AppSettings)
class PolicyStore {
  static const _key = 'privacy_accepted_version';

  static Future<bool> isAccepted() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_key) ?? 0) >= kLegalVersion;
  }

  static Future<void> accept() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, kLegalVersion);
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

class LegalUi {
  static String _p(String lang, String fa, String en, String ar) =>
      lang == 'ar' ? ar : (lang == 'en' ? en : fa);

  static String title(String l) => _p(l, 'حریم خصوصی و شرایط استفاده',
      'Privacy Policy & Terms of Use', 'سياسة الخصوصية وشروط الاستخدام');
  static String intro(String l) => _p(l, 'پیش از شروع، لطفاً متن زیر را بخوانید.',
      'Please read the text below before you start.', 'يرجى قراءة النص التالي قبل البدء.');
  static String agree(String l) => _p(
      l,
      'متن حریم خصوصی و شرایط استفاده را خوانده‌ام و می‌پذیرم',
      'I have read and accept the Privacy Policy and Terms of Use',
      'قرأتُ سياسة الخصوصية وشروط الاستخدام وأوافق عليها');
  static String accept(String l) =>
      _p(l, 'می‌پذیرم و ادامه می‌دهم', 'Accept and continue', 'أوافق وأتابع');
  static String decline(String l) =>
      _p(l, 'نمی‌پذیرم، خروج', 'Decline and exit', 'لا أوافق، خروج');
  static String privacy(String l) =>
      _p(l, 'حریم خصوصی', 'Privacy Policy', 'سياسة الخصوصية');
  static String terms(String l) =>
      _p(l, 'شرایط استفاده', 'Terms of Use', 'شروط الاستخدام');
  static String shopRules(String l, String shop) =>
      _p(l, 'قوانین $shop', 'Rules of $shop', 'قواعد $shop');
  static String shopRulesNote(String l) => _p(
      l,
      'این قوانین را خود آرایشگاه نوشته و مکمل حریم خصوصی و شرایط استفادهٔ برنامه است.',
      'These rules were written by the shop itself and complement the app\'s Privacy Policy and Terms of Use.',
      'كتب الصالون هذه القواعد بنفسه وهي مكمّلة لسياسة الخصوصية وشروط استخدام التطبيق.');
}

TextDirection _dir(String lang) =>
    lang == 'en' ? TextDirection.ltr : TextDirection.rtl;

/// دور برنامه را می‌پیچد: تا تأیید نشده، فقط صفحهٔ تأیید را نشان می‌دهد.
class PrivacyGate extends StatefulWidget {
  final String lang;
  final Widget child;
  const PrivacyGate({super.key, required this.lang, required this.child});

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  bool? _ok;

  @override
  void initState() {
    super.initState();
    PolicyStore.isAccepted().then((v) {
      if (mounted) setState(() => _ok = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ok == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_ok == true) return widget.child;
    return PolicyAcceptPage(
      lang: widget.lang,
      onAccepted: () async {
        await PolicyStore.accept();
        if (mounted) setState(() => _ok = true);
      },
    );
  }
}

class PolicyAcceptPage extends StatefulWidget {
  final String lang;
  final VoidCallback onAccepted;
  const PolicyAcceptPage({super.key, required this.lang, required this.onAccepted});

  @override
  State<PolicyAcceptPage> createState() => _PolicyAcceptPageState();
}

class _PolicyAcceptPageState extends State<PolicyAcceptPage> {
  bool _checked = false;

  void _exit() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: _dir(l),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 42, color: cs.primary),
                    const SizedBox(height: 8),
                    Text(LegalUi.title(l),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(LegalUi.intro(l),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _GroupsView(groups: [
                              LegalGroup(LegalUi.privacy(l), appPolicy(l)),
                              LegalGroup(LegalUi.terms(l), appTerms(l)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(LegalUi.agree(l), style: const TextStyle(fontSize: 13.5)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _exit,
                            child: Text(LegalUi.decline(l)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _checked ? widget.onAccepted : null,
                            child: Text(LegalUi.accept(l)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نمایش یک متن (حریم خصوصی برنامه یا قوانین آرایشگاه) در صفحهٔ جدا
class PolicyViewPage extends StatelessWidget {
  final String lang;
  final String title;
  final List<LegalGroup> groups;
  final String? plain;
  final String? note;
  final bool showContact;
  const PolicyViewPage({
    super.key,
    required this.lang,
    required this.title,
    this.groups = const [],
    this.plain,
    this.note,
    this.showContact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: _dir(lang),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note != null) ...[
                        Text(note!,
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.65), fontSize: 12.5)),
                        const SizedBox(height: 12),
                      ],
                      if (plain != null)
                        Text(plain!, style: const TextStyle(height: 1.8, fontSize: 14)),
                      if (groups.isNotEmpty) _GroupsView(groups: groups),
                      if (showContact) ContactBox(lang: lang),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupsView extends StatelessWidget {
  final List<LegalGroup> groups;
  const _GroupsView({required this.groups});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (final g in groups) {
      children.add(Text(g.title,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: cs.primary)));
      children.add(const SizedBox(height: 10));
      for (final s in g.sections) {
        children.add(Text(s.h,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)));
        children.add(const SizedBox(height: 4));
        children.add(Text(s.b, style: const TextStyle(height: 1.75, fontSize: 13.5)));
        children.add(const SizedBox(height: 14));
      }
      children.add(const SizedBox(height: 8));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

/// باز کردن متن کامل حریم خصوصی + شرایط برنامه (از تنظیمات و ...)
void openAppPolicy(BuildContext context, String lang) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PolicyViewPage(
      lang: lang,
      title: LegalUi.title(lang),
      groups: [
        LegalGroup(LegalUi.privacy(lang), appPolicy(lang)),
        LegalGroup(LegalUi.terms(lang), appTerms(lang)),
      ],
      showContact: true,
    ),
  ));
}

/// باز کردن قوانین اختصاصی یک آرایشگاه
void openShopRules(BuildContext context, String lang, String shopName, String rules) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PolicyViewPage(
      lang: lang,
      title: LegalUi.shopRules(lang, shopName),
      plain: rules,
      note: LegalUi.shopRulesNote(lang),
    ),
  ));
}
