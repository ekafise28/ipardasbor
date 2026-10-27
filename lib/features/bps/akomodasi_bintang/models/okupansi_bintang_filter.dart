/// Default provinsi saat halaman dibuka dan saat Reset (sama dengan web).
const List<String> kOkupansiBintangProvinsiDefault = <String>['INDONESIA'];

/// Filter Okupansi Akomodasi Bintang. Tahun dan provinsi multi-pilih,
/// dikirim "A|B". Tahun kosong = server memakai tahun terbaru.
/// Provinsi kosong = semua provinsi.
class OkupansiBintangFilter {
  const OkupansiBintangFilter({
    this.tahun = const <int>[],
    this.provinsi = kOkupansiBintangProvinsiDefault,
    this.perPage = 10,
  });

  final List<int> tahun;
  final List<String> provinsi;
  final int perPage;

  bool get _provinsiDefault =>
      provinsi.length == kOkupansiBintangProvinsiDefault.length &&
      provinsi.first == kOkupansiBintangProvinsiDefault.first;

  /// Jumlah kelompok filter yang berbeda dari default (untuk badge tombol).
  int get jumlahFilterSheet =>
      (tahun.isNotEmpty ? 1 : 0) + (_provinsiDefault ? 0 : 1);

  bool get hasActiveFilter => jumlahFilterSheet > 0;

  /// Kembali ke default, ukuran halaman dipertahankan.
  OkupansiBintangFilter reset() => OkupansiBintangFilter(perPage: perPage);

  OkupansiBintangFilter copyWith({
    List<int>? tahun,
    List<String>? provinsi,
    int? perPage,
  }) => OkupansiBintangFilter(
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