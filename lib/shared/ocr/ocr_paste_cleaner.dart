import 'package:ipardasbor/core/constants/kbli_constants.dart';

import 'ocr_field_type.dart';
import 'ocr_parser.dart';
import 'ocr_result.dart';

/// Membersihkan teks dari clipboard menjadi kandidat nilai satu field.
///
/// Dua jalur:
/// - Teks yang isinya murni angka (boleh dipisah spasi, titik, strip):
///   langsung diambil angkanya, TANPA koreksi huruf, karena teks digital
///   tidak salah baca.
/// - Teks campuran (ada label atau kalimat, atau banyak baris): dicari lewat
///   [OcrParser], jadi label dan aturan panjangnya sama dengan hasil scan.
class OcrPasteCleaner {
  OcrPasteCleaner._();

  static final RegExp _pureNumeric = RegExp(r'^[0-9][0-9 .\-]*$');
  static final RegExp _invisible = RegExp(r'[\u200B\uFEFF]');
  static final RegExp _oddSpaces = RegExp(r'[\u00A0\u2007\u202F]');

  static List<OcrResult> clean(String text, OcrFieldType type) {
    final String t =
        text.replaceAll(_invisible, '').replaceAll(_oddSpaces, ' ').trim();
    if (t.isEmpty) return const [];

    // KBLI yang dipisah spasi/titik bisa berarti beberapa KBLI, jangan
    // digabung jadi satu angka panjang.
    final bool kbliMultiToken =
        type == OcrFieldType.kbli && RegExp(r'[ .\-]').hasMatch(t);

    if (_pureNumeric.hasMatch(t) && !kbliMultiToken) {
      final String v = OcrParser.digitsOnly(t);
      return [
        OcrResult(
          type: type,
          value: v,
          foundByLabel: true,
          warnings: _warnings(type, v),
        ),
      ];
    }

    return OcrParser.parseText(t, targets: {type})[type] ?? const [];
  }

  static List<OcrWarning> _warnings(OcrFieldType type, String v) {
    final List<OcrWarning> w = [];
    if (v.length != type.expectedLength) w.add(OcrWarning.unusualLength);
    if (type == OcrFieldType.kbli &&
        v.length == 5 &&
        !KbliConstants.isDiizinkan(v)) {
      w.add(OcrWarning.notInAllowedList);
    }
    return w;
  }
}