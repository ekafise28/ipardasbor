import 'package:ipardasbor/shared/ocr/models/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/models/ocr_result.dart';

/// Menentukan nilai OCR mana yang "stabil" di kamera langsung: nilai yang
/// muncul di beberapa frame berturut-turut. Salah baca satu digit biasanya
/// berubah dari frame ke frame, jadi nilai yang bertahan jauh lebih
/// bisa dipercaya daripada satu kali baca.
///
/// Murni logika (tanpa kamera/ML Kit), jadi mudah diuji.
///
/// Setiap nilai dilacak sendiri-sendiri, bukan hanya kandidat teratas,
/// supaya daftar yang urutannya berubah-ubah (misalnya beberapa KBLI)
/// tidak mengacaukan hitungan.
class OcrStabilityTracker {
  OcrStabilityTracker({this.requiredFrames = 3, this.maxMisses = 1});

  /// Berapa kali nilai harus terbaca agar dianggap stabil.
  final int requiredFrames;

  /// Berapa frame berturut-turut nilai boleh hilang sebelum dilupakan.
  /// Satu frame buram tidak boleh langsung mengulang hitungan dari nol.
  final int maxMisses;

  final Map<OcrFieldType, Map<String, _Entry>> _entries = {};

  /// Masukkan hasil parser satu frame. Mengembalikan nilai yang saat ini
  /// stabil per jenis (jenis tanpa nilai stabil tidak disertakan).
  Map<OcrFieldType, List<OcrResult>> update(
    Map<OcrFieldType, List<OcrResult>> frame,
  ) {
    for (final MapEntry<OcrFieldType, List<OcrResult>> e in frame.entries) {
      final Map<String, OcrResult> seen = {
        for (final r in e.value) r.value: r,
      };
      final Map<String, _Entry> entries = _entries.putIfAbsent(e.key, () => {});

      for (final MapEntry<String, OcrResult> s in seen.entries) {
        final _Entry? existing = entries[s.key];
        if (existing == null) {
          entries[s.key] = _Entry(s.value);
        } else {
          existing.hit(s.value);
        }
      }

      entries.removeWhere((value, entry) {
        if (seen.containsKey(value)) return false;
        entry.misses++;
        return entry.misses > maxMisses;
      });
    }
    return stable;
  }

  /// Nilai stabil saat ini, yang paling sering terbaca lebih dulu.
  Map<OcrFieldType, List<OcrResult>> get stable {
    final Map<OcrFieldType, List<OcrResult>> out = {};
    for (final type in OcrFieldType.values) {
      final Map<String, _Entry>? entries = _entries[type];
      if (entries == null) continue;
      final List<_Entry> ok =
          entries.values.where((e) => e.count >= requiredFrames).toList()
            ..sort((a, b) => b.count.compareTo(a.count));
      if (ok.isNotEmpty) out[type] = [for (final e in ok) e.result];
    }
    return out;
  }

  void reset() => _entries.clear();
}

class _Entry {
  _Entry(this.result);

  OcrResult result;
  int count = 1;
  int misses = 0;

  void hit(OcrResult latest) {
    result = latest;
    count++;
    misses = 0;
  }
}