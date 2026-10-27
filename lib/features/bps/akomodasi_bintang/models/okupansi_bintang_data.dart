import 'package:ipardasbor/features/hotel/data_hotel/models/hotel_page_result.dart'
    show HotelPagination;
import 'package:ipardasbor/features/hotel/okupansi_hotel/models/okupansi_hotel_data.dart'
    show OkupansiSeries;

List<double?> _duaBelas(dynamic v) {
  final List<dynamic> src = v as List<dynamic>? ?? const <dynamic>[];
  return List<double?>.generate(
    12,
    (int i) =>
        i < src.length && src[i] != null ? (src[i] as num).toDouble() : null,
  );
}

/// Satu kartu rincian: satu provinsi pada satu tahun, 12 bulan.
/// [bulan] selalu 12 elemen, null = belum ada data bulan itu.
class OkupansiBintangRow {
  const OkupansiBintangRow({
    required this.provinsi,
    required this.tahun,
    required this.nasional,
    required this.bulan,
    required this.rataRata,
  });

  final String provinsi;
  final int tahun;
  final bool nasional;
  final List<double?> bulan;
  final double? rataRata;

  /// Kunci unik baris (dipakai untuk ValueKey dan idOf).
  String get kunci => '$provinsi|$tahun';

  factory OkupansiBintangRow.fromJson(Map<String, dynamic> j) =>
      OkupansiBintangRow(
        provinsi: '${j['provinsi'] ?? '-'}',
        tahun: (j['tahun'] as num?)?.toInt() ?? 0,
        nasional: j['nasional'] == true,
        bulan: _duaBelas(j['bulan']),
        rataRata: (j['rata_rata'] as num?)?.toDouble(),
      );
}

class OkupansiBintangResult {
  const OkupansiBintangResult({
    required this.tahun,
    required this.provinsi,
    required this.series,
    required this.seriesDipotong,
    required this.totalSeries,
    required this.items,
    required this.pagination,
  });

  /// Tahun yang benar-benar dipakai server (penting saat filter tahun kosong).
  final List<int> tahun;
  final List<String> provinsi;
  final List<OkupansiSeries> series;
  final bool seriesDipotong;

  /// Jumlah deret selain INDONESIA sebelum dipotong.
  final int totalSeries;
  final List<OkupansiBintangRow> items;
  final HotelPagination pagination;

  factory OkupansiBintangResult.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> daftar(dynamic v) =>
        (v as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    final Map<String, dynamic> meta =
        (j['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> chart =
        (j['chart'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return OkupansiBintangResult(
      tahun: (meta['tahun'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(),
      provinsi: (meta['provinsi'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(),
      series: daftar(chart['series']).map(OkupansiSeries.fromJson).toList(),
      seriesDipotong: chart['series_dipotong'] == true,
      totalSeries: (chart['total_series'] as num?)?.toInt() ?? 0,
      items: daftar(j['items']).map(OkupansiBintangRow.fromJson).toList(),
      pagination: HotelPagination.fromJson(
        (j['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}