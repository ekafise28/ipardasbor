import 'package:ipardasbor/shared/utils/form_validators.dart';

/// Aturan validasi URL OTA, dipakai form Tahap 1, Non-OSS, akomodasi,
/// dan pemeriksaan kelengkapan draft. Pemanggil tetap memeriksa dulu
/// apakah `terdaftar_ota == 'YA'`.
class OtaUrlRules {
  const OtaUrlRules._();

  /// Belum ada platform dipilih, atau ada platform terpilih yang URL-nya kosong.
  static bool belumLengkap(Map<String, List<String>> urls) =>
      urls.isEmpty ||
      urls.values.any((List<String> v) => v.every((String u) => u.trim().isEmpty));

  /// Ada URL terisi yang formatnya tidak valid (URL kosong diabaikan).
  static bool adaUrlTidakValid(Map<String, List<String>> urls) =>
      urls.values.any(
        (List<String> v) => v.any((String u) {
          final String t = u.trim();
          return t.isNotEmpty && FormValidators.url(t) != null;
        }),
      );
}