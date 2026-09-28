/// Opsi tetap untuk filter proyek OSS. Harus sama persis dengan
/// Rule::in() di backend (mobileProyekIndex)
class OssProyekOpsi {
  const OssProyekOpsi._();

  static const List<String> statusPenanamanModal = <String>[
    'PMA', 'PMDN', 'Bukan PMA/PMDN',
  ];
  static const List<String> skalaUsaha = <String>[
    'Usaha Besar', 'Usaha Menengah', 'Usaha Kecil', 'Usaha Mikro',
  ];
  static const List<String> risikoProyek = <String>[
    'Rendah', 'Menengah Rendah', 'Menengah Tinggi', 'Tinggi',
  ];
}

class OssProyekFilter {
  const OssProyekFilter({
    this.provinsiId,
    this.kabupatenId,
    this.kecamatanId,
    this.kelurahanId,
    this.statusPenanamanModal,
    this.uraianSkalaUsaha,
    this.uraianRisiko,
    this.nibNku = '',
    this.perPage = 20,
  });

  final int? provinsiId;
  final int? kabupatenId;
  final int? kecamatanId;
  final int? kelurahanId;
  final String? statusPenanamanModal;
  final String? uraianSkalaUsaha;
  final String? uraianRisiko;
  final String nibNku;
  final int perPage;

  bool get hasActiveFilter =>
      kabupatenId != null ||
      kecamatanId != null ||
      kelurahanId != null ||
      statusPenanamanModal != null ||
      uraianSkalaUsaha != null ||
      uraianRisiko != null ||
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
    String? statusPenanamanModal,
    bool clearStatusPenanamanModal = false,
    String? uraianSkalaUsaha,
    bool clearUraianSkalaUsaha = false,
    String? uraianRisiko,
    bool clearUraianRisiko = false,
    String? nibNku,
    int? perPage,
  }) {
    return OssProyekFilter(
      provinsiId: clearProvinsiId ? null : (provinsiId ?? this.provinsiId),
      kabupatenId: clearKabupatenId ? null : (kabupatenId ?? this.kabupatenId),
      kecamatanId: clearKecamatanId ? null : (kecamatanId ?? this.kecamatanId),
      kelurahanId: clearKelurahanId ? null : (kelurahanId ?? this.kelurahanId),
      statusPenanamanModal: clearStatusPenanamanModal
          ? null
          : (statusPenanamanModal ?? this.statusPenanamanModal),
      uraianSkalaUsaha: clearUraianSkalaUsaha
          ? null
          : (uraianSkalaUsaha ?? this.uraianSkalaUsaha),
      uraianRisiko: clearUraianRisiko
          ? null
          : (uraianRisiko ?? this.uraianRisiko),
      nibNku: nibNku ?? this.nibNku,
      perPage: perPage ?? this.perPage,
    );
  }

  Map<String, dynamic> toQueryParameters(int page) {
    // Sanitasi di satu titik: hanya digit yang boleh keluar. "R-" pada NKU
    // dibuang di sini karena backend menambahkannya sendiri.
    final String angka = nibNku.replaceAll(RegExp(r'\D'), '');

    return <String, dynamic>{
      'provinsi_id': provinsiId,
      'kabupaten_id': kabupatenId,
      'kecamatan_id': kecamatanId,
      'kelurahan_id': kelurahanId,
      'status_penanaman_modal': statusPenanamanModal,
      'uraian_skala_usaha': uraianSkalaUsaha,
      'uraian_risiko_proyek': uraianRisiko,
      'nib_nku': angka.isEmpty ? null : angka,
      'per_page': perPage,
      'page': page,
    };
  }
}