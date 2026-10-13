class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() {
    return message;
  }
}

/// Pesan untuk pengguna dari sebuah error. Kegagalan jaringan dan error
/// server sudah dibungkus [ApiException] oleh ApiClient, jadi pesannya
/// dipakai apa adanya; error teknis lain (mis. gagal membaca respons)
/// diganti kalimat umum.
String pesanErrorRamah(
  Object e, {
  String fallback = 'Terjadi kesalahan saat memuat data. Silakan coba lagi.',
}) {
  return e is ApiException ? e.message : fallback;
}