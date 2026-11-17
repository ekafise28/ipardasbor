import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart';
import 'package:ipardasbor/features/hotel/data_hotel/models/hotel_page_result.dart'
    show HotelPagination;
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/json_parse.dart';

/// Satu kartu rincian: satu provinsi pada satu tahun, 12 bulan.
/// [bulan] selalu 12 elemen, null = belum ada data bulan itu.
class WisnusBpsRow {
  const WisnusBpsRow({
    required this.provinsi,
    required this.tahun,
    required this.nasional,
    required this.bulan,
    required this.total,
  });

  final String provinsi;
  final int tahun;
  final bool nasional;
  final List<int?> bulan;
  final int total;

  /// Kunci unik baris (dipakai untuk ValueKey dan idOf).
  String get kunci => '$provinsi|$tahun';

  factory WisnusBpsRow.fromJson(Map<String, dynamic> j) => WisnusBpsRow(
    provinsi: '${j['provinsi'] ?? '-'}',
    tahun: asInt(j['tahun']),
    nasional: j['nasional'] == true,
    bulan: duaBelasInt(j['bulan']),
    total: asInt(j['total']),
  );
}

class WisnusBpsResult {
  const WisnusBpsResult({
    required this.tahun,
    required this.provinsi,
    required this.bulanTerakhir,
    required this.series,
    required this.seriesDipotong,
    required this.totalSeries,
    required this.nasionalTidakIkut,
    required this.items,
    required this.pagination,
  });

  /// Tahun yang benar-benar dipakai server (penting saat filter tahun kosong).
  final List<int> tahun;
  final List<String> provinsi;
  final List<WisatawanBulanTerakhir> bulanTerakhir;
  final List<WisatawanSeries> series;
  final bool seriesDipotong;

  /// Jumlah deret selain INDONESIA sebelum dipotong.
  final int totalSeries;

  /// true = angka INDONESIA ada di data tetapi sengaja tidak digambar
  /// (skalanya jauh di atas provinsi); tampilkan catatan di layar.
  final bool nasionalTidakIkut;
  final List<WisnusBpsRow> items;
  final HotelPagination pagination;

  factory WisnusBpsResult.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> meta = asMap(j['meta']);
    final Map<String, dynamic> chart = asMap(j['chart']);

    return WisnusBpsResult(
      tahun: asIntList(meta['tahun']),
      provinsi: asStringList(meta['provinsi']),
      bulanTerakhir: asMapList(
        meta['bulan_terakhir'],
      ).map(WisatawanBulanTerakhir.fromJson).toList(),
      series: asMapList(chart['series']).map(WisatawanSeries.fromJson).toList(),
      seriesDipotong: chart['series_dipotong'] == true,
      totalSeries: asInt(chart['total_series']),
      nasionalTidakIkut: chart['nasional_tidak_ikut'] == true,
      items: asMapList(j['items']).map(WisnusBpsRow.fromJson).toList(),
      pagination: HotelPagination.fromJson(asMap(j['pagination'])),
    );
  }
}