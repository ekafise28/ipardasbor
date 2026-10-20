// IndustriFilter: menyimpan pilihan filter yang sedang aktif.
// Padanan di web: fungsi getFilters() di JavaScript.
//
// Semua nilai disimpan sebagai String karena itu yang dikirim ke server.
// Objek ini "immutable" (tidak diubah setelah dibuat). Kalau ada perubahan,
// kita membuat objek baru lewat copyWith(). Ini pola standar Flutter.

class IndustriFilter {
  const IndustriFilter({
    this.tahun = const [],
    this.provinsi = const [],
    this.kota = const [],
    this.kbli = const [],
  });

  final List<String> tahun;
  final List<String> provinsi; // berisi ID provinsi
  final List<String> kota; // berisi ID kabupaten/kota
  final List<String> kbli;

  /// True jika tidak ada filter sama sekali ("Semua data").
  bool get isEmpty =>
      tahun.isEmpty && provinsi.isEmpty && kota.isEmpty && kbli.isEmpty;

  /// Membuat salinan dengan sebagian nilai diganti.
  /// Contoh: filter.copyWith(tahun: ['2025']) -> hanya tahun yang berubah.
  IndustriFilter copyWith({
    List<String>? tahun,
    List<String>? provinsi,
    List<String>? kota,
    List<String>? kbli,
  }) {
    return IndustriFilter(
      tahun: tahun ?? this.tahun,
      provinsi: provinsi ?? this.provinsi,
      kota: kota ?? this.kota,
      kbli: kbli ?? this.kbli,
    );
  }

  /// Untuk request POST /filter (dikirim sebagai JSON body).
  Map<String, dynamic> toJson() => {
    'tahun': tahun,
    'provinsi': provinsi,
    'kota': kota,
    'kbli': kbli,
  };

  /// Untuk request GET /summary (query string).
  ///
  /// ApiClient.get hanya menerima SATU nilai per kunci, lalu memakai
  /// toString(). List yang dikirim langsung akan menjadi teks "[2025, 2026]"
  /// yang tidak terbaca Laravel. Jadi list dikirim dengan kunci berindeks:
  ///   tahun[0]=2025&tahun[1]=2026
  /// PHP/Laravel membacanya sebagai array biasa: $request->input('tahun').
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};

    // Fungsi kecil di dalam fungsi: mengubah satu list jadi kunci berindeks.
    void tambah(String nama, List<String> values) {
      for (int i = 0; i < values.length; i++) {
        params['$nama[$i]'] = values[i];
      }
    }

    tambah('tahun', tahun);
    tambah('provinsi', provinsi);
    tambah('kota', kota);
    tambah('kbli', kbli);
    return params;
  }
}
