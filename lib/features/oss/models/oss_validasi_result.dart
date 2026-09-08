/// Hasil tahap validasi NIB/KBLI/NKU, dibawa ke [OssFormPage].
///
/// [isValid] untuk sekarang SELALU diisi manual dari toggle simulasi di
/// [OssValidasiPage] karena backend validasi belum tersedia. Setelah API
/// validasi jadi, nilai ini akan datang dari respons server.
class OssValidasiResult {
  const OssValidasiResult({
    required this.nib,
    required this.kbli,
    required this.nku,
    required this.kbliDesc,
    required this.isValid,
  });

  final String nib;
  final String kbli;
  final String nku;

  /// Hanya relevan kalau [kbli] == '55900'.
  final String kbliDesc;

  final bool isValid;
}