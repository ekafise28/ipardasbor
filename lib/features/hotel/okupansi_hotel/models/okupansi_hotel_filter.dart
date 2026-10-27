/// Filter Okupansi Hotel. Tahun dan provinsi multi-pilih, dikirim "A|B".
/// Tahun kosong = server memakai tahun terbaru.
class OkupansiHotelFilter {
  const OkupansiHotelFilter({
    this.tahun = const <int>[],
    this.provinsi = const <String>[],
    this.search = '',
    this.perPage = 10,
  });

  final List<int> tahun;
  final List<String> provinsi;
  final String search;
  final int perPage;

  /// Jumlah kelompok di sheet filter yang aktif (untuk badge tombol filter).
  int get jumlahFilterSheet =>
      (tahun.isNotEmpty ? 1 : 0) + (provinsi.isNotEmpty ? 1 : 0);

  bool get hasActiveFilter => jumlahFilterSheet > 0 || search.trim().isNotEmpty;

  OkupansiHotelFilter copyWith({
    List<int>? tahun,
    List<String>? provinsi,
    String? search,
    int? perPage,
  }) => OkupansiHotelFilter(
    tahun: tahun ?? this.tahun,
    provinsi: provinsi ?? this.provinsi,
    search: search ?? this.search,
    perPage: perPage ?? this.perPage,
  );

  Map<String, dynamic> toQueryParameters(int page) => <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'tahun': tahun.join('|'),
    'provinsi': provinsi.join('|'),
    'search': search.trim(),
  };
}