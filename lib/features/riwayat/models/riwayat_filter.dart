/// State filter untuk halaman Riwayat.
///
/// Immutable - gunakan [copyWith] untuk membuat versi baru saat salah satu
/// filter diubah dari UI (dropdown, date picker, search box).
class RiwayatFilter {
  const RiwayatFilter({
    this.sumberData = const <String>[],
    this.statusVerifikasi,
    this.bidangUsaha,
    this.hasilValidasi,
    this.memilikiNib = const <String>[],
    this.terdaftarOta,
    this.kabupatenId,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.search = '',
    this.perPage = 25,
  });

  final List<String> sumberData;
  final String? statusVerifikasi;
  final String? bidangUsaha;
  final String? hasilValidasi;
  final List<String> memilikiNib;
  final String? terdaftarOta;

  final int? kabupatenId;

  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;

  final String search;
  final int perPage;

  bool get hasActiveFilter =>
      sumberData.isNotEmpty ||
      statusVerifikasi != null ||
      bidangUsaha != null ||
      kabupatenId != null ||
      tanggalMulai != null ||
      tanggalSelesai != null ||
      hasilValidasi != null ||
      memilikiNib.isNotEmpty ||
      terdaftarOta != null ||
      search.trim().isNotEmpty;

  /// Jumlah filter dari sheet (tanpa pencarian teks dan status, yang
  /// punya kontrol sendiri). Rentang tanggal dihitung satu, sama seperti
  /// chipnya.
  int get jumlahFilterSheet =>
      (sumberData.isNotEmpty ? 1 : 0) +
      (bidangUsaha != null ? 1 : 0) +
      (kabupatenId != null ? 1 : 0) +
      (hasilValidasi != null ? 1 : 0) +
      (memilikiNib.isNotEmpty ? 1 : 0) +
      (terdaftarOta != null ? 1 : 0) +
      ((tanggalMulai != null || tanggalSelesai != null) ? 1 : 0);

  RiwayatFilter copyWith({
    List<String>? sumberData,
    bool clearSumberData = false,
    String? statusVerifikasi,
    bool clearStatusVerifikasi = false,
    String? bidangUsaha,
    bool clearBidangUsaha = false,
    String? hasilValidasi,
    bool clearHasilValidasi = false,
    List<String>? memilikiNib,
    bool clearMemilikiNib = false,
    String? terdaftarOta,
    bool clearTerdaftarOta = false,
    int? kabupatenId,
    bool clearKabupatenId = false,
    DateTime? tanggalMulai,
    bool clearTanggalMulai = false,
    DateTime? tanggalSelesai,
    bool clearTanggalSelesai = false,
    String? search,
    int? perPage,
  }) {
    return RiwayatFilter(
      sumberData: clearSumberData
          ? const <String>[]
          : (sumberData ?? this.sumberData),
      statusVerifikasi: clearStatusVerifikasi
          ? null
          : (statusVerifikasi ?? this.statusVerifikasi),
      bidangUsaha: clearBidangUsaha ? null : (bidangUsaha ?? this.bidangUsaha),
      hasilValidasi: clearHasilValidasi
          ? null
          : (hasilValidasi ?? this.hasilValidasi),
      memilikiNib: clearMemilikiNib
          ? const <String>[]
          : (memilikiNib ?? this.memilikiNib),
      terdaftarOta: clearTerdaftarOta
          ? null
          : (terdaftarOta ?? this.terdaftarOta),
      kabupatenId: clearKabupatenId ? null : (kabupatenId ?? this.kabupatenId),
      tanggalMulai: clearTanggalMulai
          ? null
          : (tanggalMulai ?? this.tanggalMulai),
      tanggalSelesai: clearTanggalSelesai
          ? null
          : (tanggalSelesai ?? this.tanggalSelesai),
      search: search ?? this.search,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Mengubah filter menjadi query parameter untuk [ApiClient.get].
  ///
  /// Nilai null akan otomatis dibuang oleh ApiClient/ApiEndpoints.uri(),
  /// jadi tidak perlu difilter manual di sini.
  Map<String, dynamic> toQueryParameters(int page) {
    return <String, dynamic>{
      'sumber_data': sumberData.join('|'),
      'status_verifikasi': statusVerifikasi,
      'bidang_usaha': bidangUsaha,
      'hasil_validasi': hasilValidasi,
      'memiliki_nib': memilikiNib.join('|'),
      'terdaftar_ota': terdaftarOta,
      'kabupaten_id': kabupatenId,
      'tanggal_mulai': _formatTanggal(tanggalMulai),
      'tanggal_selesai': _formatTanggal(tanggalSelesai),
      'search': search.trim().isEmpty ? null : search.trim(),
      'per_page': perPage,
      'page': page,
    };
  }

  static String? _formatTanggal(DateTime? tanggal) {
    if (tanggal == null) {
      return null;
    }

    final String tahun = tanggal.year.toString().padLeft(4, '0');
    final String bulan = tanggal.month.toString().padLeft(2, '0');
    final String hari = tanggal.day.toString().padLeft(2, '0');

    return '$tahun-$bulan-$hari';
  }
}
