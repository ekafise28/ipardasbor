import 'package:ipardasbor/shared/utils/formatters.dart' show bulanSingkat, duaBelasInt;
import 'package:ipardasbor/shared/utils/json_parse.dart';

/// Satu deret grafik: jumlah wisatawan per bulan untuk satu provinsi pada
/// satu tahun. [values] selalu 12 elemen, null = belum ada data bulan itu.
class WisatawanSeries {
  const WisatawanSeries({
    required this.label,
    required this.provinsi,
    required this.tahun,
    required this.values,
    required this.total,
    required this.nasional,
  });

  final String label;
  final String provinsi;
  final int tahun;
  final List<int?> values;
  final int total;
  final bool nasional;

  /// Kunci unik deret (dipakai untuk menyembunyikan garis lewat legenda).
  String get kunci => '$provinsi|$tahun';

  factory WisatawanSeries.fromJson(Map<String, dynamic> j) => WisatawanSeries(
    label: '${j['label'] ?? ''}',
    provinsi: '${j['provinsi'] ?? ''}',
    tahun: asInt(j['tahun']),
    values: duaBelasInt(j['values']),
    total: asInt(j['total']),
    nasional: j['nasional'] == true,
  );
}

/// Bulan terakhir yang punya data pada satu tahun (2026 -> 6 = baru Juni).
class WisatawanBulanTerakhir {
  const WisatawanBulanTerakhir({required this.tahun, required this.bulan});

  final int tahun;
  final int bulan;

  factory WisatawanBulanTerakhir.fromJson(Map<String, dynamic> j) =>
      WisatawanBulanTerakhir(
        tahun: asInt(j['tahun']),
        bulan: asInt(j['bulan']),
      );
}

/// "2026: Jan–Jun" untuk tahun yang datanya belum sampai Desember.
/// Null kalau semua tahun lengkap.
String? catatanBulanTerakhir(List<WisatawanBulanTerakhir> daftar) {
  final List<String> bagian = <String>[
    for (final WisatawanBulanTerakhir b in daftar)
      if (b.bulan >= 1 && b.bulan < 12)
        '${b.tahun}: Jan–${bulanSingkat[b.bulan - 1]}',
  ];
  return bagian.isEmpty ? null : bagian.join(' · ');
}

/// Pilihan untuk sheet filter. [pintuMasuk] hanya terisi untuk Wisman.
class WisatawanOptions {
  const WisatawanOptions({
    required this.tahun,
    required this.provinsi,
    this.pintuMasuk = const <String>[],
  });

  final List<int> tahun;
  final List<String> provinsi;
  final List<String> pintuMasuk;

  factory WisatawanOptions.fromJson(Map<String, dynamic> j) =>
      WisatawanOptions(
        tahun: asIntList(j['tahun']),
        provinsi: asStringList(j['provinsi']),
        pintuMasuk: asStringList(j['pintu_masuk']),
      );
}