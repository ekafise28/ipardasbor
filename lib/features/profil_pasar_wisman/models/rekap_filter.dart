// Pilihan filter dashboard Profil Pasar Wisman + daftar opsinya.
// Semua nilai disimpan sebagai String; server yang mengubahnya ke angka.

class RekapFilter {
  const RekapFilter({
    this.tahun = const <String>[],
    this.bulan = const <String>[],
    this.kewarganegaraan = const <String>[],
    this.namaPintu = const <String>[],
  });

  final List<String> tahun;
  final List<String> bulan;
  final List<String> kewarganegaraan;
  final List<String> namaPintu;

  RekapFilter copyWith({
    List<String>? tahun,
    List<String>? bulan,
    List<String>? kewarganegaraan,
    List<String>? namaPintu,
  }) {
    return RekapFilter(
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      kewarganegaraan: kewarganegaraan ?? this.kewarganegaraan,
      namaPintu: namaPintu ?? this.namaPintu,
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
    tambah('kewarganegaraan', kewarganegaraan);
    tambah('nama_pintu', namaPintu);
    return params;
  }
}

class RekapFilterOptions {
  const RekapFilterOptions({
    this.tahun = const <String>[],
    this.kewarganegaraan = const <String>[],
    this.pintu = const <String>[],
  });

  final List<String> tahun;
  final List<String> kewarganegaraan;
  final List<String> pintu;

  static List<String> _daftar(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .where((dynamic e) => e != null)
        .map((dynamic e) => e.toString())
        .toList();
  }

  factory RekapFilterOptions.fromJson(Map<String, dynamic> json) {
    return RekapFilterOptions(
      tahun: _daftar(json['tahun']),
      kewarganegaraan: _daftar(json['kewarganegaraan']),
      pintu: _daftar(json['pintu']),
    );
  }
}
