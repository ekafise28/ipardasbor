import 'package:flutter/material.dart';

/// Kategori titik pada peta sebaran pengawasan.
enum MapPointType { oss, nonOss, ota }

extension MapPointTypeX on MapPointType {
  /// Warna sesuai legenda: OSS = Biru, Non-OSS = Merah, OTA = Oranye.
  Color get color {
    switch (this) {
      case MapPointType.oss:
        return const Color(0xFF1565C0);
      case MapPointType.nonOss:
        return const Color(0xFFE53935);
      case MapPointType.ota:
        return const Color(0xFFFF9500);
    }
  }

  String get label {
    switch (this) {
      case MapPointType.oss:
        return 'OSS';
      case MapPointType.nonOss:
        return 'Non-OSS';
      case MapPointType.ota:
        return 'Baseline OTA';
    }
  }

  static MapPointType fromRaw(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'OSS':
        return MapPointType.oss;
      case 'OTA':
        return MapPointType.ota;
      case 'NON_OSS':
      default:
        return MapPointType.nonOss;
    }
  }
}

/// Satu titik lokasi pada peta (hasil parsing field `titik` dari backend).
class MapPoint {
  final int id;
  final MapPointType type;
  final String title;
  final String? platform;
  final String address;
  final String district;
  final double latitude;
  final double longitude;
  final String status;
  final String nib;
  final String? sourceUrl;

  const MapPoint({
    required this.id,
    required this.type,
    required this.title,
    required this.platform,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.nib,
    required this.sourceUrl,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: _asInt(json['id']),
      type: MapPointTypeX.fromRaw(json['tipe']?.toString()),
      title: (json['judul'] ?? '').toString().trim(),
      platform: _asNullableString(json['platform']),
      address: (json['alamat'] ?? '').toString().trim(),
      district: (json['kabupaten'] ?? '').toString().trim(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      status: (json['status'] ?? '').toString().trim(),
      nib: (json['nib'] ?? '').toString().trim(),
      sourceUrl: _asNullableString(json['source_url']),
    );
  }

  /// Validasi kasar: koordinat harus berada di sekitar wilayah Indonesia.
  /// Berguna untuk menyaring data uji/dummy seperti (37.42, -122.08).
  bool get hasPlausibleIndonesianCoordinate =>
      latitude >= -11.5 &&
      latitude <= 6.5 &&
      longitude >= 94.5 &&
      longitude <= 141.5;
}

/// Konfigurasi awal peta (posisi tengah, zoom, ringkasan total).
class MapConfigData {
  final double latitude;
  final double longitude;
  final int zoom;
  final String provinceName;
  final int totalOss;
  final int totalNonOss;
  final int totalOta;

  const MapConfigData({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.provinceName,
    required this.totalOss,
    required this.totalNonOss,
    required this.totalOta,
  });

  factory MapConfigData.fromJson(Map<String, dynamic> json) {
    return MapConfigData(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      zoom: _asInt(json['zoom']) == 0 ? 8 : _asInt(json['zoom']),
      provinceName: (json['nama_provinsi'] ?? '').toString().trim(),
      totalOss: _asInt(json['total_oss']),
      totalNonOss: _asInt(json['total_non_oss']),
      totalOta: _asInt(json['total_ota']),
    );
  }
}

List<MapPoint> parseMapPoints(List<Map<String, dynamic>> raw) {
  return raw
      .map(MapPoint.fromJson)
      .where((point) => point.hasPlausibleIndonesianCoordinate)
      .toList();
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

String? _asNullableString(dynamic value) {
  final String result = (value ?? '').toString().trim();
  if (result.isEmpty || result == '-') return null;
  return result;
}