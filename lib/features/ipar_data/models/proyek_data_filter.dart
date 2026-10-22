/// Filter daftar Data Proyek. Padanan filter web: provinsi (satu pilihan),
/// kab/kota, KBLI, penanaman modal, dan risiko (multi pilihan), plus versi
/// KBLI dan kata kunci (NIB, KBLI, atau awalan nama perusahaan).
///
/// User dengan akses terbatas tidak perlu mengisi [provinsi]; server sudah
/// membatasi wilayahnya.
class ProyekDataFilter {
  const ProyekDataFilter({
    this.provinsi,
    this.kota = const <String>[],
    this.kbli = const <String>[],
    this.statusModal = const <String>[],
    this.risiko = const <String>[],
    this.versiKbli,
    this.search = '',
    this.perPage = 10,
  });

  final String? provinsi;
  final List<String> kota;
  final List<String> kbli;
  final List<String> statusModal;
  final List<String> risiko;
  final int? versiKbli; // 2020 / 2025 / null = semua
  final String search;
  final int perPage;

  /// Ringkasan singkat untuk label data offline, mis. "Bali · 2 kab/kota".
  String get ringkasan {
    final List<String> b = <String>[
      ?provinsi,
      if (kota.isNotEmpty) '${kota.length} kab/kota',
      if (kbli.isNotEmpty) '${kbli.length} KBLI',
      if (statusModal.isNotEmpty) statusModal.join('/'),
      if (risiko.isNotEmpty) 'Risiko ${risiko.join('/')}',
      if (versiKbli != null) 'KBLI $versiKbli',
      if (search.trim().isNotEmpty) 'Cari "${search.trim()}"',
    ];
    return b.isEmpty ? 'Semua data' : b.join(' · ');
  }

  /// Jumlah kelompok filter di sheet yang aktif (untuk badge tombol filter).
  int get jumlahFilterSheet =>
      (provinsi != null ? 1 : 0) +
      (kota.isNotEmpty ? 1 : 0) +
      (kbli.isNotEmpty ? 1 : 0) +
      (statusModal.isNotEmpty ? 1 : 0) +
      (risiko.isNotEmpty ? 1 : 0) +
      (versiKbli != null ? 1 : 0);

  bool get hasActiveFilter => jumlahFilterSheet > 0 || search.trim().isNotEmpty;

  /// Ganti provinsi sekaligus mengosongkan kab/kota (daftarnya milik
  /// provinsi lama).
  ProyekDataFilter denganProvinsi(String? baru) => ProyekDataFilter(
    provinsi: baru,
    kbli: kbli,
    statusModal: statusModal,
    risiko: risiko,
    versiKbli: versiKbli,
    search: search,
    perPage: perPage,
  );

  ProyekDataFilter copyWith({
    List<String>? kota,
    List<String>? kbli,
    List<String>? statusModal,
    List<String>? risiko,
    int? versiKbli,
    bool clearVersiKbli = false,
    String? search,
    int? perPage,
  }) {
    return ProyekDataFilter(
      provinsi: provinsi,
      kota: kota ?? this.kota,
      kbli: kbli ?? this.kbli,
      statusModal: statusModal ?? this.statusModal,
      risiko: risiko ?? this.risiko,
      versiKbli: clearVersiKbli ? null : (versiKbli ?? this.versiKbli),
      search: search ?? this.search,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Multi-nilai dikirim "A|B|C" karena ApiClient memakai toString() dan
  /// nama wilayah bisa memuat koma. Nilai kosong dibuang oleh ApiClient.
  Map<String, dynamic> toQueryParameters(int page) => <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'provinsi': provinsi,
    'kota': kota.join('|'),
    'kbli': kbli.join('|'),
    'status_penanaman_modal': statusModal.join('|'),
    'uraian_risiko_proyek': risiko.join('|'),
    'versi_kbli': versiKbli,
    'search': search.trim(),
  };
}
