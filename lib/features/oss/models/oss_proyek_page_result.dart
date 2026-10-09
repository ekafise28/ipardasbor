import '../../non_oss/models/region_option.dart';
import '../../riwayat/models/riwayat_page_result.dart' show RiwayatPagination;
import 'oss_proyek_item.dart';

/// Hitungan usaha per status verifikasi. Dihitung backend untuk filter yang
/// sedang aktif, TANPA memperhitungkan filter status itu sendiri, sehingga
/// angka pada chip status tetap utuh saat salah satu chip dipilih.
class OssProyekRingkasan {
  const OssProyekRingkasan({
    required this.total,
    required this.belum,
    required this.sudah,
    required this.tidakValid,
  });

  final int total;
  final int belum;

  /// Sudah diverifikasi dan tidak ada hasil TIDAK_VALID.
  final int sudah;
  final int tidakValid;

  static OssProyekRingkasan? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;

    int angka(String key) => (raw[key] as num?)?.toInt() ?? 0;

    return OssProyekRingkasan(
      total: angka('total'),
      belum: angka('belum'),
      sudah: angka('sudah'),
      tidakValid: angka('tidak_valid'),
    );
  }
}

/// Hasil satu kali panggilan GET /mobile/oss/proyek.
class OssProyekPageResult {
  const OssProyekPageResult({
    required this.items,
    required this.pagination,
    required this.provinsiId,
    required this.provinsiNama,
    required this.provinsiOptions,
    required this.kabupatenOptions,
    this.ringkasan,
  });

  final List<OssProyekItem> items;
  final RiwayatPagination pagination;

  /// Provinsi yang sedang dipakai backend (default sesuai akses user).
  final int? provinsiId;
  final String provinsiNama;

  /// Provinsi yang boleh diakses user. Dropdown provinsi baru ditampilkan
  /// kalau jumlahnya lebih dari satu.
  final List<RegionOption> provinsiOptions;

  /// Kabupaten/kota yang boleh diakses user pada provinsi ini (sudah dibatasi
  /// backend). Kecamatan dan kelurahan diambil dari SQLite lokal.
  final List<RegionOption> kabupatenOptions;

  /// Hitungan per status. Null kalau backend tidak mengirimnya (halaman
  /// selain pertama, atau backend versi lama).
  final OssProyekRingkasan? ringkasan;

  factory OssProyekPageResult.fromJson(Map<String, dynamic> json) {
    List<RegionOption> opsi(dynamic raw) {
      return ((raw as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic e) => RegionOption.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false);
    }

    final Map<String, dynamic> provinsi =
        (json['provinsi'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final Map<String, dynamic> filterOpsi =
        (json['filter_opsi'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    return OssProyekPageResult(
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic e) => OssProyekItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      pagination: RiwayatPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      provinsiId: (provinsi['id'] as num?)?.toInt(),
      provinsiNama: provinsi['nama']?.toString() ?? '-',
      provinsiOptions: opsi(filterOpsi['provinsi']),
      kabupatenOptions: opsi(filterOpsi['kabupaten']),
      ringkasan: OssProyekRingkasan.fromJson(json['ringkasan']),
    );
  }
}