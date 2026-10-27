/// Filter Okupansi Non-Bintang. Tahun dan provinsi multi-pilih, dikirim "A|B".
/// Tahun kosong = server memakai tahun terbaru.
/// Provinsi kosong = semua provinsi. Tidak ada default provinsi
/// (beda dengan Bintang yang defaultnya INDONESIA).
class OkupansiNonBintangFilter {
  const OkupansiNonBintangFilter({
    this.tahun = const <int>[],
    this.provinsi = const <String>[],
    this.perPage = 10,
  });

  final List<int> tahun;
  final List<String> provinsi;
  final int perPage;

  /// Jumlah kelompok di sheet filter yang aktif (untuk badge tombol filter).
  int get jumlahFilterSheet =>
      (tahun.isNotEmpty ? 1 : 0) + (provinsi.isNotEmpty ? 1 : 0);

  bool get hasActiveFilter => jumlahFilterSheet > 0;

  /// Kembali ke default, ukuran halaman dipertahankan.
  OkupansiNonBintangFilter reset() => OkupansiNonBintangFilter(perPage: perPage);

  OkupansiNonBintangFilter copyWith({
    List<int>? tahun,
    List<String>? provinsi,
    int? perPage,
  }) => OkupansiNonBintangFilter(
    tahun: tahun ?? this.tahun,
    provinsi: provinsi ?? this.provinsi,
    perPage: perPage ?? this.perPage,
  );

  Map<String, dynamic> toQueryParameters(int page) => <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'tahun': tahun.join('|'),
    'provinsi': provinsi.join('|'),
  };
}