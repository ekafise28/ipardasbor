class ApiEndpoints {
  ApiEndpoints._();

  // Base URL utama API Laravel.
  static const String baseUrl = 'https://dasbor.kemenpar.online/api';
  // static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://localhost:8000/api';

  // Health check tanpa prefix mobile.
  // Hasil: https://dasbor.kemenpar.online/api/health
  static const String health = '/health';

  // Authentication
  static const String login = '/mobile/login';
  static const String logout = '/mobile/logout';
  static const String me = '/mobile/me';

  // PLACEHOLDER — ganti path ini setelah cek Network tab di web.
  // Kemungkinan pola umum Laravel: '/mobile/profile/change-password'
  // atau '/mobile/change-password'.
  static const String changePassword = '/mobile/change-password';

  // Pengawasan Non-OSS
  static const String pengawasanNonOss = '/mobile/non-oss';

  // Wilayah
  static const String provinsi = '/mobile/wilayah/provinsi';
  static const String kabupaten = '/mobile/wilayah/kabupaten';
  static const String kecamatan = '/mobile/wilayah/kecamatan';
  static const String kelurahan = '/mobile/wilayah/kelurahan';

  // Pengawasan OSS
  static const String proyekOss = '/mobile/oss/proyek';
  static const String pengawasanOss = '/mobile/oss/pengawasan';
  static const String riwayatOss = '/mobile/oss/riwayat';

  // Dashboard
  static const String dashboard = '/mobile/dashboard';

  static String detailProyekOss(String idProyek) {
    final encodedId = Uri.encodeComponent(idProyek);

    return '/mobile/oss/proyek/$encodedId';
  }

  static String fotoPengawasanOss(dynamic idPengawasan) {
    final encodedId = Uri.encodeComponent(idPengawasan.toString());

    return '/mobile/oss/pengawasan/$encodedId/foto';
  }

  static Uri uri(String endpoint, {Map<String, dynamic>? queryParameters}) {
    final parameters = <String, String>{};

    queryParameters?.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        parameters[key] = value.toString();
      }
    });

    return Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: parameters.isEmpty ? null : parameters);
  }
}
