/// Filter Wisatawan Nusantara (BPS). Tahun dan provinsi multi-pilih, dikirim
/// "A|B". Tahun kosong = server memakai tahun terbaru; provinsi kosong =
/// semua provinsi.
class WisnusBpsFilter {
  const WisnusBpsFilter({
    this.tahun = const <int>[],
    this.provinsi = const <String>[],
    this.perPage = 10,
  });

  final List<int> tahun;
  final List<String> provinsi;
  final int perPage;

  int get jumlahFilterSheet =>
      (tahun.isNotEmpty ? 1 : 0) + (provinsi.isNotEmpty ? 1 : 0);

  bool get hasActiveFilter => jumlahFilterSheet > 0;

  /// Kembali ke default, ukuran halaman dipertahankan.
  WisnusBpsFilter reset() => WisnusBpsFilter(perPage: perPage);

  WisnusBpsFilter copyWith({
    List<int>? tahun,
    List<String>? provinsi,
    int? perPage,
  }) => WisnusBpsFilter(
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