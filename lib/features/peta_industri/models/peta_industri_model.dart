import 'package:ipardasbor/shared/utils/json_parse.dart';

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
      total: asInt(json['total']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
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
      totalNasional: asInt(json['total_nasional']),
      tidakTerpetakan: json['tidak_terpetakan'] is List
          ? (json['tidak_terpetakan'] as List)
                .map((e) => e.toString())
                .toList()
          : const <String>[],
    );
  }
}