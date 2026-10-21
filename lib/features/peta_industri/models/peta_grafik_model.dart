// lib/features/peta_industri/models/peta_grafik_model.dart

class RisikoJumlah {
  const RisikoJumlah({required this.label, required this.jumlah});

  final String label;
  final int jumlah;

  factory RisikoJumlah.fromJson(Map<String, dynamic> json) {
    return RisikoJumlah(
      label: (json['label'] ?? '').toString().trim(),
      jumlah: _asInt(json['jumlah']),
    );
  }
}

/// Satu donut chart: satu KBLI dengan sebaran risikonya.
class KbliGrafik {
  const KbliGrafik({
    required this.kbli,
    required this.nama,
    required this.total,
    required this.risiko,
  });

  final String kbli;
  final String nama;
  final int total;
  final List<RisikoJumlah> risiko;

  factory KbliGrafik.fromJson(Map<String, dynamic> json) {
    return KbliGrafik(
      kbli: (json['kbli'] ?? '').toString().trim(),
      nama: (json['nama'] ?? '').toString().trim(),
      total: _asInt(json['total']),
      risiko: _asList(json['risiko'], RisikoJumlah.fromJson),
    );
  }
}

class KategoriGrafik {
  const KategoriGrafik({
    required this.nama,
    required this.total,
    required this.kbli,
  });

  final String nama;
  final int total;
  final List<KbliGrafik> kbli;

  factory KategoriGrafik.fromJson(Map<String, dynamic> json) {
    return KategoriGrafik(
      nama: (json['nama'] ?? '').toString().trim(),
      total: _asInt(json['total']),
      kbli: _asList(json['kbli'], KbliGrafik.fromJson),
    );
  }
}

/// Hasil GET /mobile/peta-industri/{provinsi}/grafik.
class PetaGrafikData {
  const PetaGrafikData({
    required this.provinsi,
    required this.total,
    required this.kategori,
  });

  final String provinsi;
  final int total;
  final List<KategoriGrafik> kategori;

  factory PetaGrafikData.fromJson(Map<String, dynamic> json) {
    return PetaGrafikData(
      provinsi: (json['provinsi'] ?? '').toString().trim(),
      total: _asInt(json['total']),
      kategori: _asList(json['kategori'], KategoriGrafik.fromJson),
    );
  }
}

List<T> _asList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) parser,
) {
  if (raw is! List) return <T>[];
  return raw
      .whereType<Map>()
      .map((e) => parser(Map<String, dynamic>.from(e)))
      .toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}