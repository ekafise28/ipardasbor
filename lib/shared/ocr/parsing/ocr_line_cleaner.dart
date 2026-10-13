import 'package:ipardasbor/core/constants/kbli_constants.dart';

import '../models/ocr_field_type.dart';
import 'ocr_parser.dart';
import '../models/ocr_result.dart';

/// Mengubah teks satu baris yang di-tap pengguna menjadi kandidat nilai
/// untuk satu jenis field.
///
/// Urutan kerja:
/// 1. Coba [OcrParser.parseText] (label, koreksi huruf mirip angka, aturan
///    panjang) supaya hasilnya konsisten dengan hasil scan otomatis.
/// 2. Kalau parser tidak menemukan apa pun (pola baru), ambil deretan angka
///    terpanjang di baris itu. Peringatan panjang tetap muncul.
///
/// Karena pengguna sendiri yang menunjuk barisnya, hasilnya tidak diberi
/// peringatan "tanpa label".
class OcrLineCleaner {
  OcrLineCleaner._();

  static final RegExp _plainRun = RegExp(r'[0-9](?:[0-9 .\-]*[0-9])?');

  static List<OcrResult> clean(
    String lineText,
    OcrFieldType type, {
    String bidang = 'akomodasi',
  }) {
    final String text = lineText.trim();
    if (text.isEmpty) return const [];

    final List<OcrResult> parsed =
        OcrParser.parseText(text, targets: {type}, bidang: bidang)[type] ??
            const [];
    if (parsed.isNotEmpty) {
      return [
        for (final r in parsed)
          OcrResult(
            type: type,
            value: r.value,
            foundByLabel: true,
            warnings: [
              for (final w in r.warnings)
                if (w != OcrWarning.noLabel) w,
            ],
          ),
      ];
    }

    return _fallback(text, type, bidang);
  }

  /// Apakah baris ini sudah dikenali parser sebagai kandidat [type]?
  /// Dipakai untuk mewarnai kotak hijau.
  static bool isRecognized(
    String lineText,
    OcrFieldType type, {
    String bidang = 'akomodasi',
  }) {
    final String text = lineText.trim();
    if (text.isEmpty) return false;
    final List<OcrResult> parsed =
        OcrParser.parseText(text, targets: {type}, bidang: bidang)[type] ??
            const [];
    return parsed.isNotEmpty;
  }

  /// Ambil deretan angka asli (tanpa koreksi huruf) yang terpanjang.
  static List<OcrResult> _fallback(
    String text,
    OcrFieldType type,
    String bidang,
  ) {
    String best = '';
    for (final m in _plainRun.allMatches(text)) {
      final String digits = OcrParser.digitsOnly(m.group(0)!);
      if (digits.length > best.length) best = digits;
    }
    if (best.length < 4) return const [];

    final List<OcrWarning> warnings = [];
    if (best.length != type.expectedLength) {
      warnings.add(OcrWarning.unusualLength);
    }
    if (type == OcrFieldType.kbli &&
        best.length == 5 &&
        !KbliConstants.isDiizinkan(best, bidang: bidang)) {
      warnings.add(OcrWarning.notInAllowedList);
    }
    return [
      OcrResult(
        type: type,
        value: best,
        foundByLabel: true,
        warnings: warnings,
      ),
    ];
  }
}