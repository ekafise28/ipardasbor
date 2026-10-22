class ApiEndpoints {
  ApiEndpoints._();

  // Base URL utama API Laravel.
  // static const String baseUrl = 'https://dasbor.kemenpar.online/api';
  static const String baseUrl = 'https://dasbor.kemenpar.tech/api';
  // static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://localhost:8000/api';

  // Health check tanpa prefix mobile.
  // Hasil: https://dasbor.kemenpar.online/api/health
  static const String health = '/health';

  // Authentication
  static const String login = '/mobile/login';
  static const String logout = '/mobile/logout';
  static const String me = '/mobile/me';

  // PLACEHOLDER - ganti path ini setelah cek Network tab di web.
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
  static const String wilayahAkses = '/mobile/wilayah/akses';

  // Pengawasan OSS
  static const String validasiOss = '/mobile/oss/validasi';
  static const String proyekOss = '/mobile/oss/proyek';
  static const String pengawasanOss = '/mobile/oss/pengawasan';
  static const String riwayatOss = '/mobile/oss/riwayat';

  // Bidang usaha
  static String jenisProdukBidang(String bidang) =>
      '/mobile/bidang-usaha/${Uri.encodeComponent(bidang)}/jenis-produk';

  // Manajemen Akomodasi (Tahap 1 + Tahap 2)
  static const String validasiAkomodasi = '/mobile/oss/validasi-akomodasi';
  static const String pengawasanAkomodasi = '/mobile/oss/pengawasan-akomodasi';
  static const String baselineOta = '/mobile/oss/baseline-ota';

  static String riwayatOssDetail(int id) => '$riwayatOss/$id';

  // Dashboard
  static const String dashboard = '/mobile/dashboard';

  // Peta Industri
  static const String petaIndustri = '/mobile/peta-industri';

  // Data Proyek BKPM (IPAR Data)
  static const String proyekData = '/mobile/proyek-data';
  static const String proyekDataFilterOptions =
      '/mobile/proyek-data/filter-options';

  static const String proyekDataExport = '/mobile/proyek-data/export';

  static String petaIndustriGrafik(String provinsi) =>
      '$petaIndustri/${Uri.encodeComponent(provinsi)}/grafik';

  static String petaIndustriPerusahaan(String provinsi) =>
      '/mobile/peta-industri/${Uri.encodeComponent(provinsi)}/perusahaan';

  static String petaIndustriDetail(String provinsi) =>
      '$petaIndustri/${Uri.encodeComponent(provinsi)}/detail';

  static String petaIndustriPerusahaanEkspor(String provinsi) =>
    '${petaIndustriPerusahaan(provinsi)}/ekspor';

  static String petaIndustriEkspor(String provinsi) =>
      '/mobile/peta-industri/${Uri.encodeComponent(provinsi)}/ekspor';

  // //Mobile - CRUD Kelola Akun
  static const String users = '/mobile/users';
  static String userDetail(String kodeUser) {
    final encodedKode = Uri.encodeComponent(kodeUser);
    return '/mobile/users/$encodedKode';
  }

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
