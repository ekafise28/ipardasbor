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

  /// Nilai status verifikasi. Harus sama dengan Rule::in() 'status_verifikasi'
  /// di backend.
  static const String statusBelum = 'BELUM';
  static const String statusSudah = 'SUDAH';
  static const String statusTidakValid = 'TIDAK_VALID';
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
    this.statusVerifikasi,
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

  /// null = semua, atau salah satu dari OssProyekOpsi.status*.
  final String? statusVerifikasi;
  final String nibNku;
  final int perPage;

  bool get hasActiveFilter =>
      kabupatenId != null ||
      kecamatanId != null ||
      kelurahanId != null ||
      statusPenanamanModal != null ||
      uraianSkalaUsaha != null ||
      uraianRisiko != null ||
      statusVerifikasi != null ||
      nibNku.trim().isNotEmpty;

  /// Jumlah filter yang diatur lewat sheet filter (untuk badge di AppBar).
  /// Status verifikasi dan pencarian punya kontrolnya sendiri di halaman.
  int get jumlahFilterSheet =>
      <Object?>[
        kabupatenId,
        kecamatanId,
        kelurahanId,
        statusPenanamanModal,
        uraianSkalaUsaha,
        uraianRisiko,
      ].where((Object? e) => e != null).length;

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
    String? statusVerifikasi,
    bool clearStatusVerifikasi = false,
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
      statusVerifikasi: clearStatusVerifikasi
          ? null
          : (statusVerifikasi ?? this.statusVerifikasi),
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
      'status_verifikasi': statusVerifikasi,
      'nib_nku': angka.isEmpty ? null : angka,
      'per_page': perPage,
      'page': page,
      // Hitungan per status hanya dibutuhkan saat memuat dari halaman pertama.
      'ringkasan': page == 1 ? 1 : null,
    };
  }
}