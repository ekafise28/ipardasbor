/// Hasil tahap validasi NIB/KBLI/NKU, dibawa ke [OssFormPage].
///
/// [isValid] dan [proyek] berasal dari respons backend (`OssService.validasi`),
/// yang meneruskan pengecekan ke API OSS pemerintah dan mencocokkan KBLI/NKU.
class OssValidasiResult {
  const OssValidasiResult({
    required this.nib,
    required this.kbli,
    required this.nku,
    required this.kbliDesc,
    required this.isValid,
    this.proyek,
  });

  final String nib;
  final String kbli;
  final String nku;

  /// Hanya relevan kalau [kbli] == '55900'.
  final String kbliDesc;

  final bool isValid;

  /// Data usaha hasil pencocokan ke proyek OSS: nama_perusahaan,
  /// alamat_usaha, nomor_telp_perusahaan, email_perusahaan, provinsi_id,
  /// provinsi_usaha, kabupaten_id, kab_kota_usaha, kecamatan_id, kecamatan,
  /// kelurahan_id, kelurahan. Dipakai [OssFormPage] untuk autofill form.
  /// Null kalau NIB tidak ditemukan API OSS sama sekali.
  final Map<String, dynamic>? proyek;
}