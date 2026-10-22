// Model data dashboard Wisman. Bentuknya mengikuti JSON dari
// DashboardOperasionalWismanController@data (isi kunci "data").

int _int(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
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

List<int?> _bulan12(dynamic v) {
  final List<int?> out = _list(v).map(_intN).toList();
  while (out.length < 12) {
    out.add(null);
  }
  return out;
}

class WismanSummary {
  const WismanSummary({
    required this.total,
    required this.ytd,
    required this.ytdYear,
    required this.ytdMonth,
    required this.topGate,
    required this.topGateTotal,
  });

  final int total;
  final int ytd;
  final int ytdYear;
  final int ytdMonth;
  final String? topGate;
  final int topGateTotal;

  factory WismanSummary.fromJson(Map<String, dynamic> json) {
    final dynamic gate = json['top_gate'];
    return WismanSummary(
      total: _int(json['total']),
      ytd: _int(json['ytd']),
      ytdYear: _int(json['ytd_year']),
      ytdMonth: _int(json['ytd_month']),
      topGate: gate == null || gate.toString().trim().isEmpty
          ? null
          : gate.toString(),
      topGateTotal: _int(json['top_gate_total']),
    );
  }
}

/// Satu garis grafik "Perbandingan Kunjungan Antar-Tahun".
class WismanMonthlySeries {
  const WismanMonthlySeries({required this.tahun, required this.data});

  final int tahun;

  /// 12 nilai (Jan-Des); null = belum ada data bulan itu.
  final List<int?> data;

  factory WismanMonthlySeries.fromJson(Map<String, dynamic> json) {
    return WismanMonthlySeries(
      tahun: _int(json['tahun']),
      data: _bulan12(json['data']),
    );
  }
}

/// Satu garis grafik perbandingan pintu (provinsi/lokasi + tahun).
class WismanGateSeries {
  const WismanGateSeries({
    required this.province,
    required this.year,
    required this.label,
    required this.months,
  });

  final String province;
  final int year;
  final String label;
  final List<int?> months;

  factory WismanGateSeries.fromJson(Map<String, dynamic> json) {
    return WismanGateSeries(
      province: _str(json['province'], '-'),
      year: _int(json['year']),
      label: _str(json['label'], '-'),
      months: _bulan12(json['months']),
    );
  }
}

class WismanRank {
  const WismanRank({required this.label, required this.total});

  final String label;
  final int total;

  factory WismanRank.fromJson(Map<String, dynamic> json) {
    return WismanRank(
      label: _str(json['label'], '-'),
      total: _int(json['total']),
    );
  }
}

class WismanDashboardData {
  const WismanDashboardData({
    required this.summary,
    required this.updatedAt,
    required this.monthly,
    required this.gateLand,
    required this.gateSea,
    required this.gateAir,
    required this.topGates,
    required this.topProvinces,
  });

  final WismanSummary summary;
  final String updatedAt;
  final List<WismanMonthlySeries> monthly;
  final List<WismanGateSeries> gateLand;
  final List<WismanGateSeries> gateSea;
  final List<WismanGateSeries> gateAir;
  final List<WismanRank> topGates;
  final List<WismanRank> topProvinces;

  static List<WismanGateSeries> _gate(dynamic v) =>
      _list(v).map((dynamic e) => WismanGateSeries.fromJson(_map(e))).toList();

  static List<WismanRank> _rank(dynamic v) =>
      _list(v).map((dynamic e) => WismanRank.fromJson(_map(e))).toList();

  factory WismanDashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> charts = _map(json['charts']);
    final Map<String, dynamic> gates = _map(charts['gate_comparisons']);

    return WismanDashboardData(
      summary: WismanSummary.fromJson(_map(json['summary'])),
      updatedAt: _str(_map(json['meta'])['updated_at'], '-'),
      monthly: _list(
        charts['monthly'],
      ).map((dynamic e) => WismanMonthlySeries.fromJson(_map(e))).toList(),
      gateLand: _gate(gates['darat']),
      gateSea: _gate(gates['laut']),
      gateAir: _gate(gates['udara']),
      topGates: _rank(charts['top_gates']),
      topProvinces: _rank(charts['top_provinces']),
    );
  }
}
