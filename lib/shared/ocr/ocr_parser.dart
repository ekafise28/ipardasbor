import 'package:ipardasbor/core/constants/kbli_constants.dart';

import 'ocr_field_type.dart';
import 'ocr_result.dart';

/// Mengubah teks mentah hasil OCR menjadi kandidat NIB/NKU/KBLI.
///
/// Murni logika teks (tanpa kamera/ML Kit), jadi mudah diuji.
/// Urutan kerja per jenis: cari lewat label dulu (baris yang sama atau
/// baris tepat di bawahnya), kalau tidak ada baru cadangan berbasis panjang.
class OcrParser {
  OcrParser._();

  /// Deretan karakter yang "mirip angka". Boleh dipisah spasi/titik/strip.
  static final RegExp _numberRun = RegExp(
    r'(?<![A-Za-z])[0-9OoIlSsBZz|]'
    r'(?:[0-9OoIlSsBZz|]|[ .\-](?=[0-9OoIlSsBZz|]))*'
    r'(?![A-Za-z])',
  );
  static final RegExp _separators = RegExp(r'[ .\-]+');
  static final RegExp _digit = RegExp(r'[0-9]');

  static const Map<String, String> _fixes = {
    'O': '0',
    'o': '0',
    'I': '1',
    'l': '1',
    '|': '1',
    'S': '5',
    's': '5',
    'B': '8',
    'Z': '2',
    'z': '2',
  };

  /// Versi praktis untuk teks satu blok (dipecah per baris).
  static Map<OcrFieldType, List<OcrResult>> parseText(
    String text, {
    Set<OcrFieldType>? targets,
    String bidang = 'akomodasi',
  }) => parse(text.split(RegExp(r'\r?\n')), targets: targets, bidang: bidang);

  /// [targets] kosong/null berarti ketiganya. Hasil selalu memuat kunci
  /// untuk setiap target (daftarnya kosong kalau tidak ditemukan).
  static Map<OcrFieldType, List<OcrResult>> parse(
    List<String> lines, {
    Set<OcrFieldType>? targets,
    String bidang = 'akomodasi',
  }) {
    final Set<OcrFieldType> wanted = (targets == null || targets.isEmpty)
        ? OcrFieldType.values.toSet()
        : targets;
    final List<String> clean = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1) Kandidat lewat label, per jenis.
    final Map<OcrFieldType, List<String>> byLabel = {
      for (final t in wanted) t: _byLabel(t, clean),
    };

    // 2) Satu nilai hanya boleh dimiliki satu jenis. Kalau berebut,
    //    menangkan jenis yang panjang lazimnya cocok.
    final Map<String, OcrFieldType> owners = {};
    for (final t in wanted) {
      for (final v in byLabel[t]!) {
        final OcrFieldType? current = owners[v];
        if (current == null ||
            (v.length == t.expectedLength &&
                v.length != current.expectedLength)) {
          owners[v] = t;
        }
      }
    }
    for (final t in wanted) {
      byLabel[t] = byLabel[t]!.where((v) => owners[v] == t).toList();
    }
    final Set<String> claimed = owners.keys.toSet();

    // 3) Bentuk hasil akhir.
    final Map<OcrFieldType, List<OcrResult>> result = {};
    for (final t in wanted) {
      if (t == OcrFieldType.kbli) {
        result[t] = _kbliResults(
          clean,
          byLabel[t]!.toSet(),
          bidang,
        );
        continue;
      }
      final List<String> labelValues = byLabel[t]!;
      if (labelValues.isNotEmpty) {
        result[t] = _rank(t, labelValues)
            .map(
              (v) => _build(t, v, byLabel: true, bidang: bidang),
            )
            .toList();
      } else {
        final List<String> fallback = _byFallback(t, clean, claimed);
        result[t] = _rank(t, fallback)
            .map(
              (v) => _build(t, v, byLabel: false, bidang: bidang),
            ) // <- tambah bidang
            .toList();
      }
    }
    return result;
  }

  /// Untuk tombol tempel: buang semua selain angka, TANPA koreksi huruf
  /// (huruf pada teks yang ditempel bukan salah baca OCR).
  static String digitsOnly(String input) =>
      input.split('').where(_digit.hasMatch).join();

  // ---------------------------------------------------------------------

  static List<String> _byLabel(OcrFieldType type, List<String> lines) {
    final RegExp regex = type.labelRegex;
    final List<String> found = [];
    for (int i = 0; i < lines.length; i++) {
      final List<RegExpMatch> matches = regex.allMatches(lines[i]).toList();
      if (matches.isEmpty) continue;

      final String remainder = lines[i].substring(matches.last.end);
      List<String> cands = _accept(
        type,
        _extractCandidates(remainder),
        byLabel: true,
      );
      if (cands.isEmpty && i + 1 < lines.length) {
        cands = _accept(type, _extractCandidates(lines[i + 1]), byLabel: true);
      }
      found.addAll(cands);
    }
    return _dedupe(found);
  }

  static List<String> _byFallback(
    OcrFieldType type,
    List<String> lines,
    Set<String> claimed,
  ) {
    final List<String> found = [];
    for (final line in lines) {
      found.addAll(_accept(type, _extractCandidates(line), byLabel: false));
    }
    return _dedupe(found).where((v) => !claimed.contains(v)).toList();
  }

  /// KBLI: kumpulkan semua angka 5 digit. Kalau ada yang ada di daftar
  /// diizinkan, hanya itu yang dipakai (sisanya dianggap noise seperti kode
  /// pos). Kalau tidak ada tapi ada yang ditemukan lewat label, tetap
  /// ditawarkan dengan peringatan.
  static List<OcrResult> _kbliResults(
    List<String> lines,
    Set<String> labelSet,
    String bidang,
  ) {
    final List<String> all5 = [];
    for (final line in lines) {
      all5.addAll(
        _accept(OcrFieldType.kbli, _extractCandidates(line), byLabel: false),
      );
    }
    final List<String> unique = _dedupe(all5);
    final List<String> allowed = unique
        .where((k) => KbliConstants.isDiizinkan(k, bidang: bidang))
        .toList();

    if (allowed.isNotEmpty) {
      return allowed
          .map(
            (v) => _build(
              OcrFieldType.kbli,
              v,
              byLabel: labelSet.contains(v),
              bidang: bidang,
            ),
          )
          .toList();
    }
    return labelSet
        .map((v) => _build(OcrFieldType.kbli, v, byLabel: true, bidang: bidang))
        .toList();
  }

  static List<String> _accept(
    OcrFieldType type,
    List<String> candidates, {
    required bool byLabel,
  }) => candidates
      .where((c) => type.acceptsLength(c.length, byLabel: byLabel))
      .toList();

  /// Ambil semua kandidat angka dari satu potongan teks. Deretan bersambung
  /// spasi ikut dicoba dalam bentuk gabungan DAN per potongan.
  static List<String> _extractCandidates(String text) {
    final List<String> out = [];
    for (final m in _numberRun.allMatches(text)) {
      final String raw = m.group(0)!;
      final String compact = raw.replaceAll(_separators, '');
      if (_looksNumeric(compact)) out.add(_correct(compact));

      if (compact.length != raw.length) {
        for (final token in raw.split(_separators)) {
          if (token.isNotEmpty && _looksNumeric(token))
            out.add(_correct(token));
        }
      }
    }
    return _dedupe(out);
  }

  /// Minimal 4 angka asli dan angka asli minimal separuh karakter, supaya
  /// kata biasa yang kebetulan berisi huruf mirip angka tidak lolos.
  static bool _looksNumeric(String s) {
    final int digits = _digit.allMatches(s).length;
    return digits >= 4 && digits * 2 >= s.length;
  }

  static String _correct(String s) =>
      s.split('').map((c) => _fixes[c] ?? c).join();

  static List<String> _dedupe(List<String> values) => values.toSet().toList();

  static List<String> _rank(OcrFieldType type, List<String> values) {
    if (type == OcrFieldType.kbli) return values;
    final entries = values.asMap().entries.toList();
    entries.sort((a, b) {
      final int c = _score(type, b.value).compareTo(_score(type, a.value));
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return entries.map((e) => e.value).toList();
  }

  static int _score(OcrFieldType type, String v) {
    int s = v.length;
    if (v.length == type.expectedLength) s += 100;
    if (type == OcrFieldType.nku && _hasDatePrefix(v)) s += 50;
    return s;
  }

  /// NKU tampak berawalan yyyyMMdd. Hanya bobot peringkat, bukan syarat.
  static bool _hasDatePrefix(String v) {
    if (v.length < 8) return false;
    final int y = int.parse(v.substring(0, 4));
    final int m = int.parse(v.substring(4, 6));
    final int d = int.parse(v.substring(6, 8));
    return y >= 2000 && y <= 2100 && m >= 1 && m <= 12 && d >= 1 && d <= 31;
  }

  static OcrResult _build(
    OcrFieldType type,
    String value, {
    required bool byLabel,
    String bidang = 'akomodasi',
  }) {
    final List<OcrWarning> warnings = [];
    if (value.length != type.expectedLength) {
      warnings.add(OcrWarning.unusualLength);
    }
    if (type == OcrFieldType.kbli &&
        !KbliConstants.isDiizinkan(value, bidang: bidang)) {
      warnings.add(OcrWarning.notInAllowedList);
    }
    if (!byLabel) warnings.add(OcrWarning.noLabel);

    return OcrResult(
      type: type,
      value: value,
      foundByLabel: byLabel,
      warnings: warnings,
    );
  }
}
