/// Hitungan listing baseline OTA per status verifikasi. Dihitung backend
/// untuk filter yang sedang aktif, TANPA memperhitungkan filter status itu
/// sendiri, sehingga angka pada chip tetap utuh saat salah satu chip dipilih.
class BaselineOtaRingkasan {
  const BaselineOtaRingkasan({
    required this.total,
    required this.belum,
    required this.sudah,
  });

  final int total;
  final int belum;
  final int sudah;

  static BaselineOtaRingkasan? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);

    int angka(String key) => (json[key] as num?)?.toInt() ?? 0;

    return BaselineOtaRingkasan(
      total: angka('total'),
      belum: angka('belum'),
      sudah: angka('sudah'),
    );
  }
}