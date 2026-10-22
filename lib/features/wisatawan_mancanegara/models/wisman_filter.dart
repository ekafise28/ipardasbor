// Pilihan filter dashboard Wisman + daftar opsinya.
// Semua nilai disimpan sebagai String; server yang mengubahnya ke angka.

class WismanOption {
  const WismanOption(this.value, this.label);

  final String value;
  final String label;
}

class WismanFilter {
  const WismanFilter({
    this.tahun = const <String>[],
    this.bulan = const <String>[],
    this.provinsi = const <String>[],
    this.pintuMasuk = const <String>[],
    this.namaPintu = const <String>[],
  });

  final List<String> tahun;
  final List<String> bulan;
  final List<String> provinsi;
  final List<String> pintuMasuk;
  final List<String> namaPintu;

  WismanFilter copyWith({
    List<String>? tahun,
    List<String>? bulan,
    List<String>? provinsi,
    List<String>? pintuMasuk,
    List<String>? namaPintu,
  }) {
    return WismanFilter(
      tahun: tahun ?? this.tahun,
      bulan: bulan ?? this.bulan,
      provinsi: provinsi ?? this.provinsi,
      pintuMasuk: pintuMasuk ?? this.pintuMasuk,
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
    tambah('provinsi', provinsi);
    tambah('pintu_masuk', pintuMasuk);
    tambah('nama_pintu', namaPintu);
    return params;
  }
}

class WismanFilterOptions {
  const WismanFilterOptions({
    this.tahun = const <String>[],
    this.provinsi = const <String>[],
    this.pintuMasuk = const <String>[],
    this.namaPintu = const <String>[],
  });

  final List<String> tahun;
  final List<String> provinsi;
  final List<String> pintuMasuk;
  final List<String> namaPintu;

  static List<String> _daftar(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .where((dynamic e) => e != null)
        .map((dynamic e) => e.toString())
        .toList();
  }

  factory WismanFilterOptions.fromJson(Map<String, dynamic> json) {
    return WismanFilterOptions(
      tahun: _daftar(json['tahun']),
      provinsi: _daftar(json['provinsi']),
      pintuMasuk: _daftar(json['pintu_masuk']),
      namaPintu: _daftar(json['nama_pintu']),
    );
  }
}
