/// Filter Wisatawan Mancanegara (BPS). Semua multi-pilih, dikirim "A|B".
/// Tahun kosong = server memakai tahun terbaru; pintu dan provinsi
/// kosong = semua.
class WismanBpsFilter {
  const WismanBpsFilter({
    this.tahun = const <int>[],
    this.pintuMasuk = const <String>[],
    this.provinsi = const <String>[],
    this.perPage = 10,
  });

  final List<int> tahun;
  final List<String> pintuMasuk;
  final List<String> provinsi;
  final int perPage;

  /// Jumlah kelompok filter yang terisi (untuk badge tombol filter).
  int get jumlahFilterSheet =>
      (tahun.isNotEmpty ? 1 : 0) +
      (pintuMasuk.isNotEmpty ? 1 : 0) +
      (provinsi.isNotEmpty ? 1 : 0);

  bool get hasActiveFilter => jumlahFilterSheet > 0;

  /// Kembali ke default, ukuran halaman dipertahankan.
  WismanBpsFilter reset() => WismanBpsFilter(perPage: perPage);

  WismanBpsFilter copyWith({
    List<int>? tahun,
    List<String>? pintuMasuk,
    List<String>? provinsi,
    int? perPage,
  }) => WismanBpsFilter(
    tahun: tahun ?? this.tahun,
    pintuMasuk: pintuMasuk ?? this.pintuMasuk,
    provinsi: provinsi ?? this.provinsi,
    perPage: perPage ?? this.perPage,
  );

  Map<String, dynamic> toQueryParameters(int page) => <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'tahun': tahun.join('|'),
    'pintu_masuk': pintuMasuk.join('|'),
    'provinsi': provinsi.join('|'),
  };
}