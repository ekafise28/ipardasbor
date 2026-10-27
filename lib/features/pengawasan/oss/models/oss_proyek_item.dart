/// Satu baris proyek OSS akomodasi pada daftar verifikasi.
///
/// Padanan satu baris tabel "Daftar Pengawasan OSS Akomodasi" di web.
class OssProyekItem {
  const OssProyekItem({
    required this.id,
    required this.idProyek,
    required this.nku,
    required this.nib,
    required this.kbli,
    required this.namaPerusahaan,
    required this.kabupaten,
    required this.kecamatan,
    required this.kelurahan,
    required this.alamat,
    required this.sudahDiverifikasi,
    this.statusPenanamanModal,
    this.uraianRisiko,
    this.pengawasanId,
    this.hasilValidasi,
  });

  final int id;

  /// Format asli database, contoh: "R-202210051139546023359".
  final String idProyek;

  /// NKU tanpa awalan "R-" (format yang diketik petugas di form validasi).
  final String nku;
  final String nib;
  final String kbli;
  final String namaPerusahaan;
  final String? statusPenanamanModal;
  final String? uraianRisiko;
  final String kabupaten;
  final String kecamatan;
  final String kelurahan;
  final String alamat;

  /// True kalau usaha ini sudah punya hasil pengawasan.
  final bool sudahDiverifikasi;

  /// ID baris di tbl_oss_pengawasan; dipakai tombol Detail. Null kalau belum.
  final int? pengawasanId;

  /// 'VALID' / 'TIDAK_VALID' / null (belum diverifikasi).
  final String? hasilValidasi;

  bool get tidakValid => hasilValidasi == 'TIDAK_VALID';

  /// Contoh: "Pare, Kab. Kediri". Bagian kosong dilewati.
  String get lokasiRingkas {
    final List<String> bagian = <String>[kelurahan, kecamatan, kabupaten]
        .where((String v) => v.isNotEmpty && v != '-')
        .toList();

    return bagian.isEmpty ? '-' : bagian.join(', ');
  }

  factory OssProyekItem.fromJson(Map<String, dynamic> json) {
    String teks(String key) => json[key]?.toString().trim() ?? '';

    String? teksOpsional(String key) {
      final String v = teks(key);
      return v.isEmpty ? null : v;
    }

    return OssProyekItem(
      id: (json['id'] as num).toInt(),
      idProyek: teks('id_proyek'),
      nku: teks('nku'),
      nib: teks('nib'),
      kbli: teks('kbli'),
      namaPerusahaan: teks('nama_perusahaan').isEmpty
          ? '-'
          : teks('nama_perusahaan'),
      statusPenanamanModal: teksOpsional('status_penanaman_modal'),
      uraianRisiko: teksOpsional('uraian_risiko'),
      kabupaten: teks('kabupaten'),
      kecamatan: teks('kecamatan'),
      kelurahan: teks('kelurahan'),
      alamat: teks('alamat'),
      sudahDiverifikasi: json['sudah_diverifikasi'] == true,
      pengawasanId: (json['pengawasan_id'] as num?)?.toInt(),
      hasilValidasi: teksOpsional('hasil_validasi'),
    );
  }
}