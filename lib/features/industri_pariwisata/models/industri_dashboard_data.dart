// Hasil POST /filter: 3 kartu KPI + 4 grafik + waktu pembaruan data.

import 'industri_parse.dart';

/// 3 kartu ringkasan di bagian atas dashboard.
class IndustriKpi {
  const IndustriKpi({
    this.totalUsaha = 0,
    this.usahaBaru = 0,
    this.usahaBaruLabel = 'Usaha Baru YTD',
    this.usahaBaruDetail = '1 Januari sampai hari ini',
    this.totalNib = 0,
  });

  final int totalUsaha;
  final int usahaBaru;
  final String usahaBaruLabel; // berubah sesuai filter tahun
  final String usahaBaruDetail; // keterangan periode
  final int totalNib;

  factory IndustriKpi.fromJson(Map<String, dynamic> json) {
    return IndustriKpi(
      totalUsaha: parseInt(json['total_usaha']),
      usahaBaru: parseInt(json['usaha_baru']),
      // Nilai bawaan sama persis dengan di web (updateSummary)
      usahaBaruLabel: parseString(json['usaha_baru_label'], 'Usaha Baru YTD'),
      usahaBaruDetail: parseString(
        json['usaha_baru_detail'],
        '1 Januari sampai hari ini',
      ),
      totalNib: parseInt(json['total_nib']),
    );
  }
}

/// Data satu grafik: label (sumbu X / irisan) + nilainya.
class IndustriChartData {
  const IndustriChartData({
    this.labels = const [],
    this.values = const [],
    this.percentages = const [],
  });

  final List<String> labels;
  final List<int> values;

  /// Hanya terisi untuk grafik Tahun: pertumbuhan terhadap tahun sebelumnya
  /// (null jika tidak ada pembanding). Web belum menampilkannya.
  final List<double?> percentages;

  bool get isEmpty => labels.isEmpty;

  /// Jumlah seluruh nilai (dipakai untuk baris total di tabel).
  int get total => values.fold(0, (sum, v) => sum + v);

  factory IndustriChartData.fromJson(Map<String, dynamic> json) {
    return IndustriChartData(
      labels: parseList(json['labels']).map((e) => parseString(e)).toList(),
      // Di JSON, nilai grafik ada di kunci "data"
      values: parseList(json['data']).map(parseInt).toList(),
      percentages: parseList(
        json['percentages'],
      ).map((e) => e == null ? null : double.tryParse('$e')).toList(),
    );
  }
}

/// Gabungan seluruh hasil POST /filter.
class IndustriDashboardData {
  const IndustriDashboardData({
    this.kpi = const IndustriKpi(),
    this.tahun = const IndustriChartData(),
    this.skala = const IndustriChartData(),
    this.risiko = const IndustriChartData(),
    this.modal = const IndustriChartData(),
    this.lastUpdated,
  });

  final IndustriKpi kpi;
  final IndustriChartData tahun; // Perkembangan Total Usaha (bar)
  final IndustriChartData skala; // Skala Usaha (doughnut)
  final IndustriChartData risiko; // Tingkat Risiko Proyek (doughnut)
  final IndustriChartData modal; // Status Penanaman Modal (doughnut)

  /// Waktu tabel ringkasan terakhir dihitung.
  /// null = belum pernah dihitung ("Data ringkasan belum pernah dihitung").
  final DateTime? lastUpdated;

  factory IndustriDashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> charts = parseMap(json['charts']);

    IndustriChartData chart(String key) =>
        IndustriChartData.fromJson(parseMap(charts[key]));

    final String? rawUpdated = json['last_updated']?.toString();

    return IndustriDashboardData(
      kpi: IndustriKpi.fromJson(parseMap(json['summary'])),
      // Nama kunci harus SAMA dengan getCharts() di controller
      tahun: chart('tahun'),
      skala: chart('uraian_skala_usaha'),
      risiko: chart('uraian_risiko_proyek'),
      modal: chart('status_penanaman_modal'),
      // Server mengirim "2026-10-20 08:00:00"; spasi diganti 'T' agar bisa
      // dibaca DateTime.tryParse (sama seperti di JavaScript web).
      lastUpdated: rawUpdated == null || rawUpdated.isEmpty
          ? null
          : DateTime.tryParse(rawUpdated.replaceFirst(' ', 'T')),
    );
  }
}
