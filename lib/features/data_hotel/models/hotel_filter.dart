/// Filter daftar Data Hotel. Provinsi multi-pilih (dari ketukan batang
/// grafik atau sheet filter), dikirim "A|B|C" seperti fitur Data Proyek.
class HotelFilter {
  const HotelFilter({
    this.provinsi = const <String>[],
    this.search = '',
    this.perPage = 10,
  });

  final List<String> provinsi;
  final String search;
  final int perPage;

  bool get hasActiveFilter => provinsi.isNotEmpty || search.trim().isNotEmpty;

  HotelFilter copyWith({
    List<String>? provinsi,
    String? search,
    int? perPage,
  }) => HotelFilter(
    provinsi: provinsi ?? this.provinsi,
    search: search ?? this.search,
    perPage: perPage ?? this.perPage,
  );

  Map<String, dynamic> toQueryParameters(int page) => <String, dynamic>{
    'page': page,
    'per_page': perPage,
    'provinsi': provinsi.join('|'),
    'search': search.trim(),
  };
}