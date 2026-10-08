/// Filter untuk listing baseline OTA. Mutable (sama gaya dengan
/// OssFormData/AkomodasiItemData), dipakai bersama di halaman listing
/// dan bottom sheet filter.
class BaselineOtaFilter {
  BaselineOtaFilter({
    this.provinsiId,
    this.kabupatenId,
    this.kecamatanId,
    this.kelurahanId,
    this.platformOta,
    this.namaListing,
    this.status,
    this.perPage = 50,
    this.lat,
    this.lng,
  });

  int? provinsiId;
  int? kabupatenId;
  int? kecamatanId;
  int? kelurahanId;
  String? platformOta;
  String? namaListing;

  /// null = semua status, atau 'BELUM' / 'SUDAH'.
  String? status;
  int perPage;

  bool get isActive =>
      kabupatenId != null ||
      kecamatanId != null ||
      kelurahanId != null ||
      (platformOta ?? '').trim().isNotEmpty ||
      (namaListing ?? '').trim().isNotEmpty ||
      status != null;

  double? lat;
  double? lng;

  /// true = mode "Dekat saya" aktif (server mengurutkan menurut jarak).
  bool get urutJarak => lat != null && lng != null;

  BaselineOtaFilter copyWith({
    int? provinsiId,
    int? kabupatenId,
    bool clearKabupaten = false,
    int? kecamatanId,
    bool clearKecamatan = false,
    int? kelurahanId,
    bool clearKelurahan = false,
    String? platformOta,
    bool clearPlatformOta = false,
    String? namaListing,
    String? status,
    bool clearStatus = false,
    int? perPage,
    double? lat, double? lng,
  }) {
    return BaselineOtaFilter(
      provinsiId: provinsiId ?? this.provinsiId,
      kabupatenId: clearKabupaten ? null : (kabupatenId ?? this.kabupatenId),
      kecamatanId: clearKecamatan ? null : (kecamatanId ?? this.kecamatanId),
      kelurahanId: clearKelurahan ? null : (kelurahanId ?? this.kelurahanId),
      platformOta: clearPlatformOta ? null : (platformOta ?? this.platformOta),
      namaListing: namaListing ?? this.namaListing,
      status: clearStatus ? null : (status ?? this.status),
      perPage: perPage ?? this.perPage,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  BaselineOtaFilter reset() =>
    BaselineOtaFilter(provinsiId: provinsiId, perPage: perPage, lat: lat, lng: lng);

  /// _buildUri() di ApiClient sudah otomatis membuang value null/kosong,
  /// jadi di sini tidak perlu filter manual.
  Map<String, dynamic> toQueryParams(int page) {
    return {
      'page': page,
      'per_page': perPage,
      'provinsi_id': provinsiId,
      'kabupaten_id': kabupatenId,
      'kecamatan_id': kecamatanId,
      'kelurahan_id': kelurahanId,
      'platform_ota': platformOta,
      'nama_listing': namaListing,
      'status': status,
      'lat': lat,
'lng': lng,
    };
  }
}
