import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fmt.dart';

/// رقم‌های لاتین → رقم‌های زبان (fa / ar)
String lDigits(String s, String lang) {
  if (lang == 'en') return s;
  final base = lang == 'ar' ? 0x0660 : 0x06F0;
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x30 && r <= 0x39) {
      b.writeCharCode(base + (r - 0x30));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// رقم‌های فارسی/عربی → لاتین
String latinDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + (r - 0x06F0));
    } else if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + (r - 0x0660));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

class CurrencyDef {
  final String key;
  final String fa;
  final String en;
  final String ar;
  const CurrencyDef(this.key, this.fa, this.en, this.ar);
  String name(String lang) => lang == 'en' ? en : (lang == 'ar' ? ar : fa);
}

const List<CurrencyDef> kCurrencies = [
  CurrencyDef('toman', 'تومان', 'Toman', 'تومان'),
  CurrencyDef('rial', 'ریال', 'Rial', 'ريال'),
  CurrencyDef('dollar', 'دلار', 'USD', 'دولار'),
  CurrencyDef('euro', 'یورو', 'EUR', 'يورو'),
  CurrencyDef('pound', 'پوند', 'GBP', 'جنيه إسترليني'),
  CurrencyDef('dirham', 'درهم', 'AED', 'درهم'),
  CurrencyDef('sar', 'ریال سعودی', 'SAR', 'ريال سعودي'),
  CurrencyDef('lira', 'لیر', 'TRY', 'ليرة'),
];

/// کلید واحد پول از هر متنی که ذخیره شده؛ خالی = تومان؛ ناشناخته = null
String? currencyKeyOf(String raw) {
  final r = raw.trim();
  final s = r.toLowerCase();
  if (s.isEmpty) return 'toman';
  for (final c in kCurrencies) {
    if (c.key == s ||
        c.fa == r ||
        c.en.toLowerCase() == s ||
        c.ar == r) {
      return c.key;
    }
  }
  if (s == r'$') return 'dollar';
  if (s == '€') return 'euro';
  if (s == 'تومن') return 'toman';
  return null;
}

/// نام واحد پول به زبان برنامه
String currencyName(String raw, String lang) {
  final k = currencyKeyOf(raw);
  if (k == null) return raw.trim();
  for (final c in kCurrencies) {
    if (c.key == k) return c.name(lang);
  }
  return raw.trim();
}

/// مبلغ با جداکننده‌ی هزارگان، رقم‌های زبان و واحد پول
String fmtMoney(num n, String rawCur, String lang) {
  return '${fmtNum(n, lang)} ${currencyName(rawCur, lang)}'.trim();
}

/// هر مقداری (عدد، «1,250,000»، «۱٬۲۵۰٬۰۰۰») را به عدد صحیح تبدیل می‌کند
int parsePrice(dynamic v) {
  if (v is num) return v.round();
  var s = latinDigits('${v ?? ''}').replaceAll(RegExp(r'[,\s٬،]'), '');
  s = s.replaceAll(RegExp(r'[^0-9.]'), '');
  if (s.split('.').length > 2) s = s.replaceAll('.', '');
  return (double.tryParse(s) ?? 0).round();
}

String _group(String s, String? lang) {
  final d = latinDigits(s).replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return '';
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(',');
    b.write(d[i]);
  }
  return lDigits(b.toString(), lang ?? kDigitsLang);
}

/// کنترلری که هنگام تایپ، خودش جداکننده‌ی هزارگان می‌گذارد (۱,۲۵۰,۰۰۰)
class MoneyController extends TextEditingController {
  MoneyController({String? text, this.lang})
      : super(text: text == null ? null : _group(text, lang));

  String? lang;

  int? get number {
    final d = latinDigits(text).replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? null : int.tryParse(d);
  }

  @override
  set value(TextEditingValue v) {
    final f = _group(v.text, lang);
    if (f == v.text) {
      super.value = v;
      return;
    }
    super.value = TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
      composing: TextRange.empty,
    );
  }
}

// ---------- زمان به دقیقه / ساعت / روز / هفته / ماه ----------
const List<int> kSpanMult = [1, 60, 1440, 10080, 43200];

const Map<String, List<String>> _spanOne = {
  'fa': ['دقیقه', 'ساعت', 'روز', 'هفته', 'ماه'],
  'en': ['minute', 'hour', 'day', 'week', 'month'],
  'ar': ['دقيقة', 'ساعة', 'يوم', 'أسبوع', 'شهر'],
};

/// نام واحد زمان؛ برای انگلیسی با جمع
String spanUnit(int idx, int n, String lang) {
  final l = _spanOne[lang] ?? _spanOne['fa']!;
  final w = l[idx.clamp(0, 4)];
  if (lang == 'en' && n != 1) return '${w}s';
  return w;
}

/// بزرگ‌ترین واحدی که دقیقاً مقسوم‌علیه است
int spanIndexOf(int minutes) {
  if (minutes > 0) {
    for (var i = 4; i >= 1; i--) {
      if (minutes % kSpanMult[i] == 0) return i;
    }
  }
  return 0;
}

/// ۱۲۰ → «۲ ساعت» ، ۱۰۰۸۰ → «۱ هفته»
String fmtSpan(int minutes, String lang) {
  final i = spanIndexOf(minutes);
  final n = minutes ~/ kSpanMult[i];
  return '${lDigits('$n', lang)} ${spanUnit(i, n, lang)}';
}
