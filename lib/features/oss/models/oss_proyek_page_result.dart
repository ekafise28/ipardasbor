import '../../non_oss/models/region_option.dart';
import '../../riwayat/models/riwayat_page_result.dart' show RiwayatPagination;
import 'oss_proyek_item.dart';

/// Hasil satu kali panggilan GET /mobile/oss/proyek.
class OssProyekPageResult {
  const OssProyekPageResult({
    required this.items,
    required this.pagination,
    required this.provinsiId,
    required this.provinsiNama,
    required this.provinsiOptions,
    required this.kabupatenOptions,
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
    );
  }
}