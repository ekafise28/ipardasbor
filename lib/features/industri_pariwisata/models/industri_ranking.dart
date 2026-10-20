// 4 tabel peringkat Top 20. Masing-masing diambil lewat request sendiri
// (GET /summary?section=...) supaya yang lambat tidak menahan yang lain.

import 'industri_parse.dart';

enum IndustriRankingSection {
  pariwisata('pariwisata'), // Jenis Usaha Pariwisata
  kbli('kbli'), // Kode KBLI
  provinsi('provinsi'), // Provinsi
  kota('kota'); // Kabupaten/Kota

  const IndustriRankingSection(this.key);

  /// Nilai yang dikirim sebagai ?section= dan nama kunci pada respons.
  final String key;
}

class IndustriRankingRow {
  const IndustriRankingRow({
    required this.label,
    required this.total,
    this.code,
  });

  final String label; // nama jenis usaha / judul KBLI / provinsi / kota
  final int total;
  final String? code; // hanya dipakai tabel KBLI (kolom "KBLI")

  /// Nama kolom di JSON berbeda per section (lihat calculateRanking di
  /// controller), jadi dipetakan satu per satu di sini.
  factory IndustriRankingRow.fromJson(
    IndustriRankingSection section,
    Map<String, dynamic> json,
  ) {
    final int total = parseInt(json['total_usaha']);

    switch (section) {
      case IndustriRankingSection.pariwisata:
        return IndustriRankingRow(
          label: parseString(json['judul_kbli']),
          total: total,
        );
      case IndustriRankingSection.kbli:
        return IndustriRankingRow(
          code: parseString(json['kbli']),
          label: parseString(json['judul_kbli']),
          total: total,
        );
      case IndustriRankingSection.provinsi:
        return IndustriRankingRow(
          label: parseString(json['provinsi']),
          total: total,
        );
      case IndustriRankingSection.kota:
        return IndustriRankingRow(
          label: parseString(json['kota']),
          total: total,
        );
    }
  }
}
