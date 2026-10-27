import 'package:ipardasbor/features/hotel/data_hotel/models/hotel_page_result.dart'
    show HotelPagination;

/// Satu baris grafik batang: satu provinsi, satu nilai per tahun.
/// [values] sejajar dengan [OkupansiNonBintangChart.tahun];
/// null = tidak ada data provinsi itu pada tahun tersebut (bukan 0).
class OkupansiNonBintangBaris {
  const OkupansiNonBintangBaris({required this.provinsi, required this.values});

  final String provinsi;
  final List<double?> values;

  factory OkupansiNonBintangBaris.fromJson(Map<String, dynamic> j) =>
      OkupansiNonBintangBaris(
        provinsi: '${j['provinsi'] ?? '-'}',
        values: (j['values'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => e == null ? null : (e as num).toDouble())
            .toList(),
      );
}

class OkupansiNonBintangChart {
  const OkupansiNonBintangChart({required this.tahun, required this.baris});

  /// Tahun yang dipakai, urut naik.
  final List<int> tahun;
  final List<OkupansiNonBintangBaris> baris;

  factory OkupansiNonBintangChart.fromJson(Map<String, dynamic> j) =>
      OkupansiNonBintangChart(
        tahun: (j['tahun'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => (e as num).toInt())
            .toList(),
        baris: (j['baris'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OkupansiNonBintangBaris.fromJson)
            .toList(),
      );
}

/// Satu baris rincian: provinsi + tahun + persentase.
class OkupansiNonBintangRow {
  const OkupansiNonBintangRow({
    required this.provinsi,
    required this.tahun,
    required this.persentase,
  });

  final String provinsi;
  final int tahun;
  final double persentase;

  /// Kunci unik baris (dipakai untuk ValueKey dan idOf).
  String get kunci => '$provinsi|$tahun';

  factory OkupansiNonBintangRow.fromJson(Map<String, dynamic> j) =>
      OkupansiNonBintangRow(
        provinsi: '${j['provinsi'] ?? '-'}',
        tahun: (j['tahun'] as num?)?.toInt() ?? 0,
        persentase: (j['persentase'] as num?)?.toDouble() ?? 0,
      );
}

class OkupansiNonBintangResult {
  const OkupansiNonBintangResult({
    required this.tahun,
    required this.provinsi,
    required this.chart,
    required this.items,
    required this.pagination,
  });

  /// Tahun yang benar-benar dipakai server (penting saat filter tahun kosong).
  final List<int> tahun;
  final List<String> provinsi;
  final OkupansiNonBintangChart chart;
  final List<OkupansiNonBintangRow> items;
  final HotelPagination pagination;

  factory OkupansiNonBintangResult.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> meta =
        (j['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return OkupansiNonBintangResult(
      tahun: (meta['tahun'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(),
      provinsi: (meta['provinsi'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(),
      chart: OkupansiNonBintangChart.fromJson(
        (j['chart'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      items: (j['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OkupansiNonBintangRow.fromJson)
          .toList(),
      pagination: HotelPagination.fromJson(
        (j['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}