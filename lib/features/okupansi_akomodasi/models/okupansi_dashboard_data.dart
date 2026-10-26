// Model data dashboard Okupansi. Bentuknya mengikuti JSON dari
// DashboardOkupansiController@data (isi kunci "data").

double _dbl(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

double? _dblN(dynamic v) {
  if (v == null || v == '') return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

int? _intN(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

String _str(dynamic v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

List<dynamic> _list(dynamic v) => v is List ? v : const <dynamic>[];

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class OkupansiSummary {
  const OkupansiSummary({
    required this.average,
    required this.latestAverage,
    required this.previousAverage,
    required this.changePoint,
    required this.growthYoy,
    required this.topProvince,
    required this.topValue,
    required this.peakMonth,
    required this.peakValue,
  });

  final double average;
  final double latestAverage;
  final double previousAverage;
  final double? changePoint;
  final double? growthYoy;
  final String? topProvince;
  final double topValue;

  /// 1-12, null = belum ada data.
  final int? peakMonth;
  final double peakValue;

  factory OkupansiSummary.fromJson(Map<String, dynamic> json) {
    final dynamic top = json['top_province'];
    return OkupansiSummary(
      average: _dbl(json['average']),
      latestAverage: _dbl(json['latest_average']),
      previousAverage: _dbl(json['previous_average']),
      changePoint: _dblN(json['change_point']),
      growthYoy: _dblN(json['growth_yoy']),
      topProvince: top == null || top.toString().trim().isEmpty
          ? null
          : top.toString(),
      topValue: _dbl(json['top_value']),
      peakMonth: _intN(json['peak_month']),
      peakValue: _dbl(json['peak_value']),
    );
  }
}

/// Satu baris label + nilai persen (tahunan, peringkat).
class OkupansiPoint {
  const OkupansiPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory OkupansiPoint.fromJson(Map<String, dynamic> json) {
    return OkupansiPoint(
      label: _str(json['label'], '-'),
      value: _dbl(json['value']),
    );
  }
}

/// Satu garis grafik "Okupansi Bulanan" (provinsi + tahun).
class OkupansiSeries {
  const OkupansiSeries({
    required this.province,
    required this.year,
    required this.label,
    required this.months,
  });

  final String province;
  final String year;
  final String label;

  /// 12 nilai (Jan-Des); null = belum ada data bulan itu.
  final List<double?> months;

  factory OkupansiSeries.fromJson(Map<String, dynamic> json) {
    final List<double?> out = _list(
      json['months'] ?? json['values'],
    ).map(_dblN).toList();
    while (out.length < 12) {
      out.add(null);
    }
    return OkupansiSeries(
      province: _str(json['province'], 'Provinsi'),
      year: _str(json['year']),
      label: _str(json['label'], '-'),
      months: out,
    );
  }
}

class OkupansiDashboardData {
  const OkupansiDashboardData({
    required this.summary,
    required this.updatedAt,
    required this.annual,
    required this.ranking,
    required this.bottom,
    required this.comparison,
  });

  final OkupansiSummary summary;
  final String updatedAt;
  final List<OkupansiPoint> annual;
  final List<OkupansiPoint> ranking;
  final List<OkupansiPoint> bottom;
  final List<OkupansiSeries> comparison;

  static List<OkupansiPoint> _points(dynamic v) =>
      _list(v).map((dynamic e) => OkupansiPoint.fromJson(_map(e))).toList();

  factory OkupansiDashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> charts = _map(json['charts']);

    return OkupansiDashboardData(
      summary: OkupansiSummary.fromJson(_map(json['summary'])),
      updatedAt: _str(_map(json['meta'])['updated_at'], '-'),
      annual: _points(charts['annual']),
      ranking: _points(charts['ranking']),
      bottom: _points(charts['bottom']),
      // Seri yang seluruh bulannya kosong dibuang (sama seperti web).
      comparison: _list(charts['province_comparison'])
          .map((dynamic e) => OkupansiSeries.fromJson(_map(e)))
          .where((OkupansiSeries s) => s.months.any((double? v) => v != null))
          .toList(),
    );
  }
}
