/// Ringkasan hasil verifikasi terakhir suatu listing baseline OTA
/// (tbl_oss_baseline_ota_verifikasi, lewat relasi verifikasiAktif).
/// null kalau listing ini belum pernah diverifikasi sama sekali.
class BaselineOtaVerifikasi {
  const BaselineOtaVerifikasi({
    required this.statusVerifikasi,
    required this.nib,
    required this.idProyek,
    required this.verifiedAt,
  });

  final String statusVerifikasi;
  final String? nib;
  final String? idProyek;
  final DateTime? verifiedAt;

  factory BaselineOtaVerifikasi.fromJson(Map<String, dynamic> json) {
    return BaselineOtaVerifikasi(
      statusVerifikasi: json['status_verifikasi']?.toString() ?? '',
      nib: json['nib']?.toString(),
      idProyek: json['id_proyek']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
    );
  }
}

/// Satu baris listing hasil scraping OTA (tbl_oss_baseline_ota), sesuai
/// bentuk JSON dari OssBaselineOtaController::mobileIndex().
class BaselineOtaItem {
  const BaselineOtaItem({
    required this.id,
    required this.platformOta,
    required this.namaListing,
    required this.alamat,
    required this.provinsiId,
    required this.kabupatenId,
    required this.kabupaten,
    required this.kecamatan,
    required this.kelurahan,
    required this.latitude,
    required this.longitude,
    required this.sourceUrl,
    required this.urlMaps,
    required this.scrapedAt,
    required this.statusVerifikasiRingkas,
    required this.verifikasiAktif,
    this.jarakKm,
  });

  final int id;
  final String? platformOta;
  final String? namaListing;
  final String? alamat;
  final int? provinsiId;
  final int? kabupatenId;
  final String? kabupaten;
  final String? kecamatan;
  final String? kelurahan;
  final double? latitude;
  final double? longitude;
  final String? sourceUrl;
  final String? urlMaps;
  final DateTime? scrapedAt;
  final String statusVerifikasiRingkas;
  final BaselineOtaVerifikasi? verifikasiAktif;
  final double? jarakKm;

  bool get sudahDiverifikasi => statusVerifikasiRingkas == 'SUDAH';

  String get wilayahRingkas {
    final List<String> bagian = [kelurahan, kecamatan, kabupaten]
        .where((String? e) => (e ?? '').trim().isNotEmpty)
        .map((String? e) => e!)
        .toList();
    return bagian.isEmpty ? '-' : bagian.join(', ');
  }

  factory BaselineOtaItem.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());

    return BaselineOtaItem(
      id: int.parse(json['id'].toString()),
      platformOta: json['platform_ota']?.toString(),
      namaListing: json['nama_listing']?.toString(),
      alamat: json['alamat']?.toString(),
            provinsiId: json['provinsi_id'] != null ? int.tryParse(json['provinsi_id'].toString()) : null,
      kabupatenId: json['kabupaten_id'] != null ? int.tryParse(json['kabupaten_id'].toString()) : null,
      kabupaten: json['kabupaten']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      kelurahan: json['kelurahan']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      sourceUrl: json['source_url']?.toString(),
      urlMaps: json['url_maps']?.toString(),
      scrapedAt: json['scraped_at'] != null
          ? DateTime.tryParse(json['scraped_at'].toString())
          : null,
      statusVerifikasiRingkas: json['status_verifikasi_ringkas']?.toString() ?? 'BELUM',
      verifikasiAktif: json['verifikasi_aktif'] is Map
          ? BaselineOtaVerifikasi.fromJson(
              Map<String, dynamic>.from(json['verifikasi_aktif'] as Map),
            )
          : null,
      jarakKm: toDouble(json['jarak_km']),
    );
  }
}