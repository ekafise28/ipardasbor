// Pilihan filter dashboard Okupansi + daftar opsinya.
// Semua nilai disimpan sebagai String; server yang mengubahnya ke angka.

class OkupansiFilter {
  const OkupansiFilter({
    this.tahun = const <String>[],
    this.bulan = const <String>[],
    this.provinsi = const <String>[],
  });

  final List<String> tahun;
  final List<String> bulan;
  final List<String> provinsi;

  OkupansiFilter copyWith({
    List<String>? tahun,
    List<String>? bulan,
    List<String>? provinsi,
  }) {
    return OkupansiFilter(
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      provinsi: provinsi ?? this.provinsi,
    );
  }

  /// Format query yang dibaca Laravel sebagai array: tahun[0]=2025&tahun[1]=...
  Map<String, String> toQueryParams() {
    final Map<String, String> params = <String, String>{};

    void tambah(String key, List<String> values) {
      for (int i = 0; i < values.length; i++) {
        params['$key[$i]'] = values[i];
      }
    }

    tambah('tahun', tahun);
    tambah('bulan', bulan);
    tambah('provinsi', provinsi);
    return params;
  }
}

class OkupansiFilterOptions {
  const OkupansiFilterOptions({
    this.tahun = const <String>[],
    this.provinsi = const <String>[],
  });

  final List<String> tahun;
  final List<String> provinsi;

  static List<String> _daftar(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .where((dynamic e) => e != null)
        .map((dynamic e) => e.toString())
        .toList();
  }

  factory OkupansiFilterOptions.fromJson(Map<String, dynamic> json) {
    return OkupansiFilterOptions(
      tahun: _daftar(json['tahun']),
      provinsi: _daftar(json['provinsi']),
    );
  }
}
