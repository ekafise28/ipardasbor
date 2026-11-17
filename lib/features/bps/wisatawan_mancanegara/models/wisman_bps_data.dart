import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart';
import 'package:ipardasbor/features/hotel/data_hotel/models/hotel_page_result.dart'
    show HotelPagination;
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/json_parse.dart';

/// Satu kartu rincian: satu nama pintu pada satu tahun, 12 bulan.
/// [bulan] selalu 12 elemen, null = belum ada data bulan itu.
class WismanBpsRow {
  const WismanBpsRow({
    required this.pintuMasuk,
    required this.provinsi,
    required this.namaPintu,
    required this.tahun,
    required this.bulan,
    required this.total,
  });

  final String pintuMasuk;
  final String provinsi;
  final String namaPintu;
  final int tahun;
  final List<int?> bulan;
  final int total;

  /// Kunci unik baris (dipakai untuk ValueKey dan idOf).
  String get kunci => '$pintuMasuk|$provinsi|$namaPintu|$tahun';

  factory WismanBpsRow.fromJson(Map<String, dynamic> j) => WismanBpsRow(
    pintuMasuk: '${j['pintu_masuk'] ?? '-'}',
    provinsi: '${j['provinsi'] ?? '-'}',
    namaPintu: '${j['nama_pintu'] ?? '-'}',
    tahun: asInt(j['tahun']),
    bulan: duaBelasInt(j['bulan']),
    total: asInt(j['total']),
  );
}

/// Satu grafik: semua deret (provinsi + tahun) pada satu jenis pintu.
class WismanBpsGrup {
  const WismanBpsGrup({
    required this.pintuMasuk,
    required this.series,
    required this.totalSeries,
    required this.seriesDipotong,
  });

  final String pintuMasuk;
  final List<WisatawanSeries> series;

  /// Jumlah deret sebelum dipotong server.
  final int totalSeries;
  final bool seriesDipotong;

  factory WismanBpsGrup.fromJson(Map<String, dynamic> j) => WismanBpsGrup(
    pintuMasuk: '${j['pintu_masuk'] ?? '-'}',
    series: asMapList(j['series']).map(WisatawanSeries.fromJson).toList(),
    totalSeries: asInt(j['total_series']),
    seriesDipotong: j['series_dipotong'] == true,
  );
}

class WismanBpsPintuTotal {
  const WismanBpsPintuTotal({required this.pintuMasuk, required this.total});

  final String pintuMasuk;
  final int total;

  factory WismanBpsPintuTotal.fromJson(Map<String, dynamic> j) =>
      WismanBpsPintuTotal(
        pintuMasuk: '${j['pintu_masuk'] ?? '-'}',
        total: asInt(j['total']),
      );
}

class WismanBpsResult {
  const WismanBpsResult({
    required this.tahun,
    required this.pintuMasuk,
    required this.provinsi,
    required this.bulanTerakhir,
    required this.total,
    required this.perPintu,
    required this.grup,
    required this.items,
    required this.pagination,
  });

  /// Tahun yang benar-benar dipakai server (penting saat filter tahun kosong).
  final List<int> tahun;
  final List<String> pintuMasuk;
  final List<String> provinsi;
  final List<WisatawanBulanTerakhir> bulanTerakhir;

  /// Total seluruh data yang cocok dengan filter, bukan hanya halaman ini.
  final int total;
  final List<WismanBpsPintuTotal> perPintu;
  final List<WismanBpsGrup> grup;
  final List<WismanBpsRow> items;
  final HotelPagination pagination;

  factory WismanBpsResult.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> meta = asMap(j['meta']);
    final Map<String, dynamic> sum = asMap(j['summary']);
    final Map<String, dynamic> chart = asMap(j['chart']);

    return WismanBpsResult(
      tahun: asIntList(meta['tahun']),
      pintuMasuk: asStringList(meta['pintu_masuk']),
      provinsi: asStringList(meta['provinsi']),
      bulanTerakhir: asMapList(
        meta['bulan_terakhir'],
      ).map(WisatawanBulanTerakhir.fromJson).toList(),
      total: asInt(sum['total']),
      perPintu: asMapList(
        sum['per_pintu'],
      ).map(WismanBpsPintuTotal.fromJson).toList(),
      grup: asMapList(chart['groups']).map(WismanBpsGrup.fromJson).toList(),
      items: asMapList(j['items']).map(WismanBpsRow.fromJson).toList(),
      pagination: HotelPagination.fromJson(asMap(j['pagination'])),
    );
  }
}