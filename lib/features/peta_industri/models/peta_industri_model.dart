// lib/features/peta_industri/models/peta_industri_model.dart

/// Satu marker provinsi pada Peta Industri.
class PetaProvinsi {
  const PetaProvinsi({
    required this.nama,
    required this.total,
    required this.latitude,
    required this.longitude,
  });

  final String nama;
  final int total;
  final double latitude;
  final double longitude;

  factory PetaProvinsi.fromJson(Map<String, dynamic> json) {
    return PetaProvinsi(
      nama: (json['provinsi'] ?? '').toString().trim(),
      total: _asInt(json['total']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }
}

/// Hasil GET /mobile/peta-industri.
class PetaIndustriData {
  const PetaIndustriData({
    required this.provinsi,
    required this.totalNasional,
    required this.tidakTerpetakan,
  });

  final List<PetaProvinsi> provinsi;
  final int totalNasional;

  /// Nama provinsi di database yang belum punya koordinat di server.
  final List<String> tidakTerpetakan;

  factory PetaIndustriData.fromJson(Map<String, dynamic> json) {
    final dynamic rawList = json['provinsi'];

    return PetaIndustriData(
      provinsi: rawList is List
          ? rawList
                .whereType<Map>()
                .map((e) => PetaProvinsi.fromJson(Map<String, dynamic>.from(e)))
                .where((p) => p.nama.isNotEmpty)
                .toList()
          : const <PetaProvinsi>[],
      totalNasional: _asInt(json['total_nasional']),
      tidakTerpetakan: json['tidak_terpetakan'] is List
          ? (json['tidak_terpetakan'] as List)
                .map((e) => e.toString())
                .toList()
          : const <String>[],
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}