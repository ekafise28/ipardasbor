// Model data dashboard Profil Pasar Wisman. Bentuknya mengikuti JSON dari
// DashboardWismanRekapController@data (isi kunci "data").

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

String? _strN(dynamic v) =>
    v == null || v.toString().trim().isEmpty ? null : v.toString();

class RekapSummary {
  const RekapSummary({
    required this.total,
    required this.topNationality,
    required this.topNationalityTotal,
    required this.topPort,
    required this.topPortTotal,
  });

  final int total;
  final String? topNationality;
  final int topNationalityTotal;
  final String? topPort;
  final int topPortTotal;

  factory RekapSummary.fromJson(Map<String, dynamic> json) {
    return RekapSummary(
      total: _int(json['total']),
      topNationality: _strN(json['top_nationality']),
      topNationalityTotal: _int(json['top_nationality_total']),
      topPort: _strN(json['top_port']),
      topPortTotal: _int(json['top_port_total']),
    );
  }
}

/// Satu baris label + jumlah (tahunan, peringkat, pangsa pasar).
class RekapPoint {
  const RekapPoint({required this.label, required this.total});

  final String label;
  final int total;

  factory RekapPoint.fromJson(Map<String, dynamic> json) {
    return RekapPoint(
      label: _str(json['label'], '-'),
      total: _int(json['total']),
    );
  }
}

/// Satu garis "Perbandingan Bulanan Antar-Tahun".
class RekapMonthlySeries {
  const RekapMonthlySeries({required this.tahun, required this.data});

  final int tahun;

  /// 12 nilai (Jan-Des); null = belum ada data bulan itu.
  final List<int?> data;

  factory RekapMonthlySeries.fromJson(Map<String, dynamic> json) {
    final List<int?> out = _list(json['data']).map(_intN).toList();
    while (out.length < 12) {
      out.add(null);
    }
    return RekapMonthlySeries(tahun: _int(json['tahun']), data: out);
  }
}

class RekapDashboardData {
  const RekapDashboardData({
    required this.summary,
    required this.updatedAt,
    required this.annual,
    required this.monthly,
    required this.nationalities,
    required this.marketShare,
    required this.ports,
  });

  final RekapSummary summary;
  final String updatedAt;
  final List<RekapPoint> annual;
  final List<RekapMonthlySeries> monthly;
  final List<RekapPoint> nationalities;
  final List<RekapPoint> marketShare;
  final List<RekapPoint> ports;

  static List<RekapPoint> _points(dynamic v) =>
      _list(v).map((dynamic e) => RekapPoint.fromJson(_map(e))).toList();

  factory RekapDashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> charts = _map(json['charts']);

    return RekapDashboardData(
      summary: RekapSummary.fromJson(_map(json['summary'])),
      updatedAt: _str(_map(json['meta'])['updated_at'], '-'),
      annual: _points(charts['annual']),
      monthly: _list(
        charts['monthly'],
      ).map((dynamic e) => RekapMonthlySeries.fromJson(_map(e))).toList(),
      nationalities: _points(charts['nationalities']),
      marketShare: _points(charts['market_share']),
      ports: _points(charts['ports']),
    );
  }
}
