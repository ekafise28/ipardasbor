import '../../data_hotel/models/hotel_page_result.dart' show HotelPagination;

const List<String> kNamaBulanSingkat = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> kNamaBulanPanjang = <String>[
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

List<double?> _duaBelas(dynamic v) {
  final List<dynamic> src = v as List<dynamic>? ?? const <dynamic>[];
  return List<double?>.generate(
    12,
    (int i) => i < src.length && src[i] != null ? (src[i] as num).toDouble() : null,
  );
}

/// Satu deret grafik: satu provinsi (atau INDONESIA) pada satu tahun.
/// [values] selalu 12 elemen, null = belum ada data bulan itu.
class OkupansiSeries {
  const OkupansiSeries({
    required this.label,
    required this.provinsi,
    required this.tahun,
    required this.values,
    required this.rataRata,
    required this.nasional,
  });

  final String label;
  final String provinsi;
  final int tahun;
  final List<double?> values;
  final double rataRata;
  final bool nasional;

  factory OkupansiSeries.fromJson(Map<String, dynamic> j) => OkupansiSeries(
    label: '${j['label'] ?? ''}',
    provinsi: '${j['provinsi'] ?? ''}',
    tahun: (j['tahun'] as num?)?.toInt() ?? 0,
    values: _duaBelas(j['values']),
    rataRata: (j['rata_rata'] as num?)?.toDouble() ?? 0,
    nasional: j['nasional'] == true,
  );
}

/// Satu baris tabel pivot web: hotel + tahun + 12 bulan.
class OkupansiHotelRow {
  const OkupansiHotelRow({
    required this.hotelId,
    required this.namaHotel,
    required this.provinsi,
    required this.kabKota,
    required this.tahun,
    required this.bulan,
    required this.rataRata,
  });

  final int hotelId;
  final String namaHotel;
  final String provinsi;
  final String kabKota;
  final int tahun;
  final List<double?> bulan;
  final double? rataRata;

  factory OkupansiHotelRow.fromJson(Map<String, dynamic> j) => OkupansiHotelRow(
    hotelId: (j['hotel_id'] as num?)?.toInt() ?? 0,
    namaHotel: '${j['nama_hotel'] ?? '-'}',
    provinsi: '${j['provinsi'] ?? '-'}',
    kabKota: '${j['kab_kota'] ?? '-'}',
    tahun: (j['tahun'] as num?)?.toInt() ?? 0,
    bulan: _duaBelas(j['bulan']),
    rataRata: (j['rata_rata'] as num?)?.toDouble(),
  );
}

class OkupansiHotelResult {
  const OkupansiHotelResult({
    required this.tahun,
    required this.provinsi,
    required this.rataRata,
    required this.jumlahHotel,
    required this.series,
    required this.seriesDipotong,
    required this.totalSeries,
    required this.items,
    required this.pagination,
  });

  /// Tahun yang benar-benar dipakai server (penting saat filter tahun kosong).
  final List<int> tahun;
  final List<String> provinsi;
  final double rataRata;
  final int jumlahHotel;
  final List<OkupansiSeries> series;
  final bool seriesDipotong;
  final int totalSeries;
  final List<OkupansiHotelRow> items;
  final HotelPagination pagination;

  factory OkupansiHotelResult.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> daftar(dynamic v) =>
        (v as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    final Map<String, dynamic> meta = (j['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> sum = (j['summary'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> chart = (j['chart'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return OkupansiHotelResult(
      tahun: (meta['tahun'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(),
      provinsi: (meta['provinsi'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(),
      rataRata: (sum['rata_rata'] as num?)?.toDouble() ?? 0,
      jumlahHotel: (sum['jumlah_hotel'] as num?)?.toInt() ?? 0,
      series: daftar(chart['series']).map(OkupansiSeries.fromJson).toList(),
      seriesDipotong: chart['series_dipotong'] == true,
      totalSeries: (chart['total_series'] as num?)?.toInt() ?? 0,
      items: daftar(j['items']).map(OkupansiHotelRow.fromJson).toList(),
      pagination: HotelPagination.fromJson(
        (j['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

/// Pilihan untuk sheet filter.
class OkupansiHotelOptions {
  const OkupansiHotelOptions({required this.tahun, required this.provinsi});

  final List<int> tahun;
  final List<String> provinsi;

  factory OkupansiHotelOptions.fromJson(Map<String, dynamic> j) =>
      OkupansiHotelOptions(
        tahun: (j['tahun'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => (e as num).toInt())
            .toList(),
        provinsi: (j['provinsi'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => '$e')
            .toList(),
      );
}