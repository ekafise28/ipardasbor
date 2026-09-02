/// State filter untuk halaman Riwayat.
///
/// Immutable — gunakan [copyWith] untuk membuat versi baru saat salah satu
/// filter diubah dari UI (dropdown, date picker, search box).
class RiwayatFilter {
  const RiwayatFilter({
    this.sumberData,
    this.statusVerifikasi,
    this.kabupatenId,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.search = '',
    this.perPage = 25,
  });

  final String? sumberData;
  final String? statusVerifikasi;
  final int? kabupatenId;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String search;
  final int perPage;

  bool get hasActiveFilter =>
      sumberData != null ||
      statusVerifikasi != null ||
      kabupatenId != null ||
      tanggalMulai != null ||
      tanggalSelesai != null ||
      search.trim().isNotEmpty;

  RiwayatFilter copyWith({
    String? sumberData,
    bool clearSumberData = false,
    String? statusVerifikasi,
    bool clearStatusVerifikasi = false,
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
      sumberData: clearSumberData ? null : (sumberData ?? this.sumberData),
      statusVerifikasi: clearStatusVerifikasi
          ? null
          : (statusVerifikasi ?? this.statusVerifikasi),
      kabupatenId: clearKabupatenId ? null : (kabupatenId ?? this.kabupatenId),
      tanggalMulai:
          clearTanggalMulai ? null : (tanggalMulai ?? this.tanggalMulai),
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
      'sumber_data': sumberData,
      'status_verifikasi': statusVerifikasi,
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