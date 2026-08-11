class DashboardData {
  final DashboardProvince province;
  final DashboardPeriod period;
  final DashboardActiveFilter activeFilter;
  final DashboardFilterOptions filterOptions;
  final DashboardSummary summary;

  final List<Map<String, dynamic>> districtRecap;
  final List<Map<String, dynamic>> platformRecap;
  final List<Map<String, dynamic>> productTypeRecap;

  final int totalDistrict;
  final int totalPlatform;
  final int totalProductType;

  final DashboardCharts charts;
  final DashboardMapData map;

  const DashboardData({
    required this.province,
    required this.period,
    required this.activeFilter,
    required this.filterOptions,
    required this.summary,
    required this.districtRecap,
    required this.platformRecap,
    required this.productTypeRecap,
    required this.totalDistrict,
    required this.totalPlatform,
    required this.totalProductType,
    required this.charts,
    required this.map,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      province: DashboardProvince.fromJson(_asMap(json['provinsi'])),
      period: DashboardPeriod.fromJson(_asMap(json['periode'])),
      activeFilter: DashboardActiveFilter.fromJson(
        _asMap(json['filter_aktif']),
      ),
      filterOptions: DashboardFilterOptions.fromJson(
        _asMap(json['opsi_filter']),
      ),
      summary: DashboardSummary.fromJson(_asMap(json['ringkasan'])),
      districtRecap: _asMapList(json['rekap_kabupaten']),
      platformRecap: _asMapList(json['rekap_platform']),
      productTypeRecap: _asMapList(json['rekap_jenis_produk']),
      totalDistrict: _asInt(json['total_kabupaten']),
      totalPlatform: _asInt(json['total_platform']),
      totalProductType: _asInt(json['total_jenis_produk']),
      charts: DashboardCharts.fromJson(_asMap(json['chart'])),
      map: DashboardMapData.fromJson(_asMap(json['peta'])),
    );
  }
}

class DashboardProvince {
  final int id;
  final String slug;
  final String name;

  const DashboardProvince({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory DashboardProvince.fromJson(Map<String, dynamic> json) {
    return DashboardProvince(
      id: _asInt(json['id']),
      slug: _asString(json['slug']),
      name: _asString(json['nama']),
    );
  }
}

class DashboardPeriod {
  final String? startDate;
  final String? endDate;
  final String label;

  const DashboardPeriod({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      startDate: _asNullableString(json['tanggal_dari']),
      endDate: _asNullableString(json['tanggal_sampai']),
      label: _asString(json['label']),
    );
  }
}

class DashboardActiveFilter {
  final int? districtId;
  final String? dataSource;
  final String? verificationStatus;

  const DashboardActiveFilter({
    required this.districtId,
    required this.dataSource,
    required this.verificationStatus,
  });

  factory DashboardActiveFilter.fromJson(Map<String, dynamic> json) {
    return DashboardActiveFilter(
      districtId: _asNullableInt(json['kabupaten_id']),
      dataSource: _asNullableString(json['sumber_data']),
      verificationStatus: _asNullableString(json['status_verifikasi']),
    );
  }
}

class DashboardFilterOptions {
  final List<ProvinceOption> provinces;
  final List<DistrictOption> districts;
  final List<String> dataSources;
  final List<String> verificationStatuses;

  const DashboardFilterOptions({
    required this.provinces,
    required this.districts,
    required this.dataSources,
    required this.verificationStatuses,
  });

  factory DashboardFilterOptions.fromJson(Map<String, dynamic> json) {
    return DashboardFilterOptions(
      provinces: _asMapList(
        json['provinsi'],
      ).map(ProvinceOption.fromJson).toList(),
      districts: _asMapList(
        json['kabupaten'],
      ).map(DistrictOption.fromJson).toList(),
      dataSources: _asStringList(json['sumber_data']),
      verificationStatuses: _asStringList(json['status_verifikasi']),
    );
  }
}

class ProvinceOption {
  final String slug;
  final String name;

  const ProvinceOption({required this.slug, required this.name});

  factory ProvinceOption.fromJson(Map<String, dynamic> json) {
    return ProvinceOption(
      slug: _asString(json['slug']),
      name: _asString(json['nama']),
    );
  }
}

class DistrictOption {
  final int id;
  final String name;

  const DistrictOption({required this.id, required this.name});

  factory DistrictOption.fromJson(Map<String, dynamic> json) {
    return DistrictOption(
      id: _asInt(json['id']),
      name: _asString(json['nama']),
    );
  }
}

class DashboardSummary {
  final int total;
  final int oss;
  final int nonOss;
  final int completed;
  final int draft;
  final int ota;

  const DashboardSummary({
    required this.total,
    required this.oss,
    required this.nonOss,
    required this.completed,
    required this.draft,
    required this.ota,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      total: _readInt(json, ['total', 'total_pengawasan']),
      oss: _readInt(json, ['oss', 'total_oss', 'data_oss']),
      nonOss: _readInt(json, ['non_oss', 'total_non_oss', 'data_non_oss']),
      completed: _readInt(json, [
        'selesai',
        'total_selesai',
        'verifikasi_selesai',
      ]),
      draft: _readInt(json, ['draft', 'total_draft']),
      ota: _readInt(json, ['ota', 'total_ota']),
    );
  }

  double get completedPercentage {
    if (total <= 0) return 0;

    return (completed / total * 100).clamp(0, 100).toDouble();
  }

  double get draftPercentage {
    if (total <= 0) return 0;

    return (draft / total * 100).clamp(0, 100).toDouble();
  }
}

class DashboardCharts {
  final dynamic district;
  final dynamic platform;
  final dynamic productType;

  const DashboardCharts({
    required this.district,
    required this.platform,
    required this.productType,
  });

  factory DashboardCharts.fromJson(Map<String, dynamic> json) {
    return DashboardCharts(
      district: json['kabupaten'],
      platform: json['platform'],
      productType: json['jenis_produk'],
    );
  }
}

class DashboardMapData {
  final bool displayed;
  final Map<String, dynamic> configuration;
  final List<Map<String, dynamic>> points;

  const DashboardMapData({
    required this.displayed,
    required this.configuration,
    required this.points,
  });

  factory DashboardMapData.fromJson(Map<String, dynamic> json) {
    return DashboardMapData(
      displayed: _asBool(json['ditampilkan']),
      configuration: _asMap(json['konfigurasi']),
      points: _asMapList(json['titik']),
    );
  }
}

/*
|--------------------------------------------------------------------------
| JSON HELPERS
|--------------------------------------------------------------------------
*/

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value.map(_asMap).toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _asString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _asNullableString(dynamic value) {
  final String result = _asString(value);

  return result.isEmpty ? null : result;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final String normalized = value?.toString().toLowerCase() ?? '';

  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'ya';
}

int _readInt(Map<String, dynamic> json, List<String> possibleKeys) {
  for (final String key in possibleKeys) {
    if (json.containsKey(key) && json[key] != null) {
      return _asInt(json[key]);
    }
  }

  return 0;
}
