/// State filter untuk daftar proyek OSS.
///
/// Immutable, mengikuti pola [RiwayatFilter]. Nama wilayah tidak dikirim,
/// hanya ID; backend yang mengubahnya menjadi variasi nama di tbl_proyek_akomodasi.
class OssProyekFilter {
  const OssProyekFilter({
    this.provinsiId,
    this.kabupatenId,
    this.kecamatanId,
    this.kelurahanId,
    this.nibNku = '',
    this.perPage = 20,
  });

  /// Null = biarkan backend memilih provinsi default sesuai akses user.
  final int? provinsiId;
  final int? kabupatenId;
  final int? kecamatanId;
  final int? kelurahanId;
  final String nibNku;
  final int perPage;

  /// Provinsi tidak dihitung: itu cakupan data, bukan penyaring.
  bool get hasActiveFilter =>
      kabupatenId != null ||
      kecamatanId != null ||
      kelurahanId != null ||
      nibNku.trim().isNotEmpty;

  OssProyekFilter copyWith({
    int? provinsiId,
    bool clearProvinsiId = false,
    int? kabupatenId,
    bool clearKabupatenId = false,
    int? kecamatanId,
    bool clearKecamatanId = false,
    int? kelurahanId,
    bool clearKelurahanId = false,
    String? nibNku,
    int? perPage,
  }) {
    return OssProyekFilter(
      provinsiId: clearProvinsiId ? null : (provinsiId ?? this.provinsiId),
      kabupatenId: clearKabupatenId ? null : (kabupatenId ?? this.kabupatenId),
      kecamatanId: clearKecamatanId ? null : (kecamatanId ?? this.kecamatanId),
      kelurahanId: clearKelurahanId ? null : (kelurahanId ?? this.kelurahanId),
      nibNku: nibNku ?? this.nibNku,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Nilai null/kosong dibuang otomatis oleh ApiClient.
  Map<String, dynamic> toQueryParameters(int page) {
    return <String, dynamic>{
      'provinsi_id': provinsiId,
      'kabupaten_id': kabupatenId,
      'kecamatan_id': kecamatanId,
      'kelurahan_id': kelurahanId,
      'nib_nku': nibNku.trim().isEmpty ? null : nibNku.trim(),
      'per_page': perPage,
      'page': page,
    };
  }
}