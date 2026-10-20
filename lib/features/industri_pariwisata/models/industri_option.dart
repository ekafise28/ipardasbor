// Satu pilihan di dropdown filter: [value] dikirim ke server,
// [label] ditampilkan ke pengguna.

import 'industri_parse.dart';

class IndustriOption {
  const IndustriOption({required this.value, required this.label});

  final String value;
  final String label;

  /// Kota: web menerima dua kemungkinan nama kunci, jadi kita ikuti:
  /// id/kabupaten_id dan name/nama_kabupaten.
  static IndustriOption? kotaFromJson(Map<String, dynamic> json) {
    final dynamic id = json['id'] ?? json['kabupaten_id'];
    final String name = parseString(json['name'] ?? json['nama_kabupaten'], '');
    if (id == null || name.isEmpty) return null; // data rusak dilewati
    return IndustriOption(value: id.toString(), label: name);
  }
}

/// Seluruh opsi filter dari GET /summary?section=filters
class IndustriFilterOptions {
  const IndustriFilterOptions({
    this.years = const [],
    this.provinsi = const [],
    this.kbli = const [],
  });

  final List<IndustriOption> years;
  final List<IndustriOption> provinsi;
  final List<IndustriOption> kbli;

  /// Cadangan jika server gagal. Sama seperti di web: tahun tetap muncul.
  static const IndustriFilterOptions fallback = IndustriFilterOptions(
    years: [
      IndustriOption(value: '2026', label: '2026'),
      IndustriOption(value: '2025', label: '2025'),
      IndustriOption(value: '2024', label: '2024'),
      IndustriOption(value: '2023', label: '2023'),
      IndustriOption(value: '2022', label: '2022'),
      IndustriOption(value: '2021', label: '2021'),
      IndustriOption(value: '2020', label: '2020'),
      IndustriOption(value: '2019', label: '2019'),
    ],
  );

  /// [json] = isi kunci "filters" dari respons server.
  factory IndustriFilterOptions.fromJson(Map<String, dynamic> json) {
    return IndustriFilterOptions(
      years: parseList(
        json['years'],
      ).map((y) => IndustriOption(value: '$y', label: '$y')).toList(),
      provinsi: parseList(json['provinsi'])
          .whereType<Map>()
          .map(
            (p) => IndustriOption(
              value: '${p['id']}',
              label: parseString(p['name']),
            ),
          )
          .toList(),
      kbli: parseList(json['kbli']).whereType<Map>().map((k) {
        // Format sama dengan web: "kode — judul"
        final String judul = parseString(k['judul_kbli'], 'Tanpa judul');
        return IndustriOption(
          value: '${k['kbli']}',
          label: '${k['kbli']} — $judul',
        );
      }).toList(),
    );
  }
}
