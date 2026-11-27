import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/currency.dart';
import '../../app/fmt.dart';
import 'booking_common.dart';

const Map<String, Map<String, String>> _ex = {
  'fa': {
    'tip': 'ذخیره‌ی نوبت‌های یک روز (تصویر)',
    'none': 'برای این روز نوبتی ثبت نشده است',
    'saved': 'تصویر ذخیره شد',
    'saved_n': '{n} تصویر ذخیره شد',
    'fail': 'ذخیره‌ی تصویر انجام نشد',
    'count': '{n} نوبت',
    'total': 'جمع',
    'page': 'صفحه {a} از {b}',
    'min': 'دقیقه',
    'dialog': 'ذخیره‌ی تصویر نوبت‌ها',
    'st_booked': 'ثبت‌شده',
    'st_checked_in': 'حاضر',
    'st_finished': 'انجام‌شده',
  },
  'en': {
    'tip': 'Save a day’s bookings (image)',
    'none': 'There are no bookings on this day',
    'saved': 'Image saved',
    'saved_n': '{n} images saved',
    'fail': 'Could not save the image',
    'count': '{n} bookings',
    'total': 'Total',
    'page': 'Page {a} of {b}',
    'min': 'min',
    'dialog': 'Save bookings image',
    'st_booked': 'Booked',
    'st_checked_in': 'Checked in',
    'st_finished': 'Done',
  },
  'ar': {
    'tip': 'حفظ مواعيد يوم (صورة)',
    'none': 'لا توجد مواعيد في هذا اليوم',
    'saved': 'تم حفظ الصورة',
    'saved_n': 'تم حفظ {n} صور',
    'fail': 'تعذّر حفظ الصورة',
    'count': '{n} موعد',
    'total': 'المجموع',
    'page': 'صفحة {a} من {b}',
    'min': 'د',
    'dialog': 'حفظ صورة المواعيد',
    'st_booked': 'محجوز',
    'st_checked_in': 'حاضر',
    'st_finished': 'منجز',
  },
};

String exportTx(String lang, String key,
    [Map<String, Object?> args = const <String, Object?>{}]) {
  var s = (_ex[lang] ?? _ex['fa']!)[key] ?? _ex['fa']![key] ?? key;
  args.forEach((k, v) {
    s = s.replaceAll('{$k}', '$v');
  });
  return s;
}

/// داده‌ی یک روز برای ساخت تصویر
class DayExportData {
  const DayExportData({
    required this.lang,
    required this.shopName,
    required this.weekday,
    required this.dateText,
    required this.currency,
    required this.groups,
    required this.nameOf,
    this.fontFamily,
  });
  final String lang;
  final String shopName;
  final String weekday;
  final String dateText;
  final String currency;

  /// هر گروه = یک نوبت مشتری (می‌تواند چند خدمت داشته باشد)، مرتب بر اساس ساعت
  final List<List<Map<String, dynamic>>> groups;
  final String Function(String) nameOf;
  final String? fontFamily;
}

const double _w = 1080;
const double _m = 48;
const double _gap = 22;
const double _pad = 28;
const double _pageMax = 1900;

const Color _ink = Color(0xFF1B1B1F);
const Color _mut = Color(0xFF6B6F76);
const Color _line = Color(0xFFE3E5E9);
const Color _card = Color(0xFFF6F7FA);
const Color _accent = Color(0xFF5B6CFF);

Color _stColor(String s) {
  switch (s) {
    case 'checked_in':
      return const Color(0xFFE59A12);
    case 'finished':
      return const Color(0xFF1FA463);
  }
  return const Color(0xFF3B6EF5);
}

String _groupStatus(List<Map<String, dynamic>> g) {
  final ss = g.map((b) => bStr(b['status'])).toList();
  if (ss.contains('checked_in')) return 'checked_in';
  if (ss.contains('booked')) return 'booked';
  return 'finished';
}

class _Block {
  _Block(this.h, this.draw);
  final double h;
  final void Function(Canvas c, double top) draw;
}

class _Line {
  _Line(this.svc, this.sub, this.price);
  final TextPainter svc;
  final TextPainter? sub;
  final TextPainter? price;
  double get h =>
      math.max(svc.height, price?.height ?? 0) + (sub?.height ?? 0) + 12;
}

class _R {
  _R(this.d)
      : rtl = d.lang == 'fa' || d.lang == 'ar',
        dir = (d.lang == 'fa' || d.lang == 'ar')
            ? TextDirection.rtl
            : TextDirection.ltr;

  final DayExportData d;
  final bool rtl;
  final TextDirection dir;

  TextPainter tp(
    String text,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w400,
    TextDirection? direction,
    double? width,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          fontFamily: d.fontFamily,
          height: 1.4,
        ),
      ),
      textDirection: direction ?? dir,
      maxLines: 1,
      ellipsis: '…',
    );
    if (width != null) {
      p.layout(minWidth: width, maxWidth: width);
    } else {
      p.layout();
    }
    return p;
  }

  /// شروع / پایان یک جعبه (در راست‌به‌چپ برعکس)
  double sx(double left, double boxW, double iw) =>
      rtl ? left + boxW - iw : left;
  double ex(double left, double boxW, double iw) =>
      rtl ? left : left + boxW - iw;

  int get _total {
    var t = 0;
    for (final g in d.groups) {
      for (final b in g) {
        t += parsePrice(b['price']);
      }
    }
    return t;
  }

  _Block header(int page, int pages) {
    const boxW = _w - 2 * _m;
    final pageP = pages > 1
        ? tp(
            localDigits(
                exportTx(d.lang, 'page', {'a': page, 'b': pages}), d.lang),
            26,
            _mut)
        : null;
    final nameP = tp(
      d.shopName,
      54,
      _ink,
      weight: FontWeight.w800,
      width: boxW - (pageP == null ? 0 : pageP.width + 24),
    );
    final dateP = tp('${d.weekday} · ${d.dateText}', 34, _mut, width: boxW);
    final total = _total;
    var sum = exportTx(d.lang, 'count', {'n': fmtNum(d.groups.length, d.lang)});
    if (total > 0) {
      sum +=
          ' · ${exportTx(d.lang, 'total')}: ${fmtMoney(total, d.currency, d.lang)}';
    }
    final sumP = tp(sum, 30, _ink, weight: FontWeight.w700, width: boxW);
    final h = _m + nameP.height + 4 + dateP.height + 4 + sumP.height + 22 + 4 + 28;
    return _Block(h, (c, top) {
      var y = top + _m;
      nameP.paint(c, Offset(sx(_m, boxW, nameP.width), y));
      if (pageP != null) {
        pageP.paint(c,
            Offset(ex(_m, boxW, pageP.width), y + nameP.height - pageP.height - 8));
      }
      y += nameP.height + 4;
      dateP.paint(c, Offset(_m, y));
      y += dateP.height + 4;
      sumP.paint(c, Offset(_m, y));
      y += sumP.height + 22;
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(_m, y, boxW, 4), const Radius.circular(2)),
        Paint()..color = _accent,
      );
    });
  }

  _Block block(List<Map<String, dynamic>> g) {
    const boxW = _w - 2 * _m;
    const inner = boxW - 2 * _pad;
    final first = g.first;

    var sMin = 24 * 60;
    var eMin = 0;
    var sStr = bStr(first['start_time']);
    var eStr = bStr(first['end_time']);
    for (final b in g) {
      final s = bMin(bStr(b['start_time']));
      final e = bMin(bStr(b['end_time']));
      if (s < sMin) {
        sMin = s;
        sStr = bStr(b['start_time']);
      }
      if (e >= eMin) {
        eMin = e;
        eStr = bStr(b['end_time']);
      }
    }
    final status = _groupStatus(g);

    final timeP = tp(localDigits('$sStr – $eStr', d.lang), 40, _ink,
        weight: FontWeight.w800, direction: TextDirection.ltr);
    final chipP = tp(exportTx(d.lang, 'st_$status'), 25, Colors.white,
        weight: FontWeight.w700);
    final chipW = chipP.width + 36;
    final chipH = chipP.height + 12;
    final r1 = math.max(timeP.height, chipH);

    final phone = bStr(first['customer_phone']);
    final phoneP = phone.isEmpty
        ? null
        : tp(localDigits(phone, d.lang), 30, _mut,
            direction: TextDirection.ltr);
    final nameW = inner - (phoneP == null ? 0 : phoneP.width + 24);
    final nameP = tp(d.nameOf(bStr(first['customer_name'])), 34, _ink,
        weight: FontWeight.w700, width: nameW);
    final r2 = math.max(nameP.height, phoneP?.height ?? 0);

    final rows = <_Line>[];
    var total = 0;
    for (final b in g) {
      final price = parsePrice(b['price']);
      total += price;
      final dur = bInt(b['duration_min']);
      final sub = <String>[
        if (bStr(b['staff_name']).isNotEmpty) bStr(b['staff_name']),
        if (dur > 0) '${fmtNum(dur, d.lang)} ${exportTx(d.lang, 'min')}',
      ].join(' · ');
      final priceP = price > 0
          ? tp(fmtMoney(price, d.currency, d.lang), 30, _ink,
              weight: FontWeight.w800)
          : null;
      final svcP = tp(bStr(b['service_name']), 30, _ink,
          weight: FontWeight.w700,
          width: inner - (priceP == null ? 0 : priceP.width + 24));
      final subP = sub.isEmpty ? null : tp(sub, 26, _mut, width: inner);
      rows.add(_Line(svcP, subP, priceP));
    }
    final totalP = (g.length > 1 && total > 0)
        ? tp(
            '${exportTx(d.lang, 'total')}: ${fmtMoney(total, d.currency, d.lang)}',
            30,
            _ink,
            weight: FontWeight.w800,
            width: inner)
        : null;

    var h = _pad + r1 + 12 + r2 + 16 + 2 + 14;
    for (final l in rows) {
      h += l.h;
    }
    h += (totalP?.height ?? 0) + _pad;

    return _Block(h, (c, top) {
      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(_m, top, boxW, h), const Radius.circular(24));
      c.drawRRect(rr, Paint()..color = _card);
      c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _line,
      );
      const left = _m + _pad;
      var y = top + _pad;

      timeP.paint(
          c, Offset(sx(left, inner, timeP.width), y + (r1 - timeP.height) / 2));
      final chipRect = Rect.fromLTWH(
          ex(left, inner, chipW), y + (r1 - chipH) / 2, chipW, chipH);
      c.drawRRect(
        RRect.fromRectAndRadius(chipRect, Radius.circular(chipH / 2)),
        Paint()..color = _stColor(status),
      );
      chipP.paint(c, Offset(chipRect.left + 18, chipRect.top + 6));
      y += r1 + 12;

      nameP.paint(
          c, Offset(sx(left, inner, nameP.width), y + (r2 - nameP.height) / 2));
      if (phoneP != null) {
        phoneP.paint(c,
            Offset(ex(left, inner, phoneP.width), y + (r2 - phoneP.height) / 2));
      }
      y += r2 + 16;

      c.drawLine(Offset(left, y), Offset(left + inner, y),
          Paint()..color = _line..strokeWidth = 2);
      y += 2 + 14;

      for (final l in rows) {
        final rowH = math.max(l.svc.height, l.price?.height ?? 0);
        l.svc.paint(c, Offset(sx(left, inner, l.svc.width), y + (rowH - l.svc.height) / 2));
        if (l.price != null) {
          l.price!.paint(c,
              Offset(ex(left, inner, l.price!.width), y + (rowH - l.price!.height) / 2));
        }
        y += rowH;
        if (l.sub != null) {
          l.sub!.paint(c, Offset(sx(left, inner, l.sub!.width), y));
          y += l.sub!.height;
        }
        y += 12;
      }
      if (totalP != null) {
        totalP.paint(c, Offset(sx(left, inner, totalP.width), y));
      }
    });
  }
}

/// تصویر(های) PNG یک روز؛ اگر نوبت‌ها زیاد باشند چند صفحه می‌سازد
Future<List<Uint8List>> renderDayImages(DayExportData data) async {
  final r = _R(data);
  final blocks = data.groups.map(r.block).toList();
  final hh = r.header(1, 1).h;

  final pages = <List<_Block>>[<_Block>[]];
  var used = hh;
  for (final b in blocks) {
    if (pages.last.isNotEmpty && used + b.h > _pageMax) {
      pages.add(<_Block>[]);
      used = hh;
    }
    pages.last.add(b);
    used += b.h + _gap;
  }

  final out = <Uint8List>[];
  for (var i = 0; i < pages.length; i++) {
    final hdr = r.header(i + 1, pages.length);
    var pageH = hh + _m;
    for (final b in pages[i]) {
      pageH += b.h + _gap;
    }
    pageH = math.max(pageH, 500.0);

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(Rect.fromLTWH(0, 0, _w, pageH), Paint()..color = Colors.white);
    hdr.draw(c, 0);
    var y = hh;
    for (final b in pages[i]) {
      b.draw(c, y);
      y += b.h + _gap;
    }
    final pic = rec.endRecording();
    final img = await pic.toImage(_w.toInt(), pageH.ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    if (bd == null) throw StateError('png');
    out.add(bd.buffer.asUint8List());
  }
  return out;
}

/// ذخیره‌ی تصویرها. خروجی = تعداد تصویر ذخیره‌شده (۰ = کاربر انصراف داد)
/// موبایل: برای هر تصویر یک پنجره‌ی ذخیره. ویندوز: یک تصویر = یک پنجره،
/// چند تصویر = انتخاب یک پوشه.
Future<int> saveDayImages(
    List<Uint8List> pngs, String baseName, String lang) async {
  final title = exportTx(lang, 'dialog');
  String nameOf(int i) =>
      pngs.length == 1 ? '$baseName.png' : '$baseName-${i + 1}.png';

  if (Platform.isAndroid || Platform.isIOS) {
    var n = 0;
    for (var i = 0; i < pngs.length; i++) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: title,
        fileName: nameOf(i),
        bytes: pngs[i],
      );
      if (path == null) break;
      n++;
    }
    return n;
  }

  if (pngs.length == 1) {
    var path = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName: nameOf(0),
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );
    if (path == null) return 0;
    if (!path.toLowerCase().endsWith('.png')) path = '$path.png';
    await File(path).writeAsBytes(pngs[0]);
    return 1;
  }

  final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: title);
  if (dir == null) return 0;
  for (var i = 0; i < pngs.length; i++) {
    await File('$dir${Platform.pathSeparator}${nameOf(i)}')
        .writeAsBytes(pngs[i]);
  }
  return pngs.length;
}
