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

  static const String changePassword = '/mobile/change-password';

  // Pengawasan Non-OSS
  static const String pengawasanNonOss = '/mobile/non-oss';

  // Wilayah
  static const String kabupaten = '/mobile/wilayah/kabupaten';
  static const String wilayahAkses = '/mobile/wilayah/akses';

  // Pengawasan OSS
  static const String validasiOss = '/mobile/oss/validasi';
  static const String proyekOss = '/mobile/oss/proyek';
  static const String pengawasanOss = '/mobile/oss/pengawasan';
  static const String riwayatOss = '/mobile/oss/riwayat';

  // Jenis Produk
  static const String jenisProdukSemua = '/mobile/referensi/jenis-produk';

  // Manajemen Akomodasi (Tahap 1 + Tahap 2)
  static const String validasiAkomodasi = '/mobile/oss/validasi-akomodasi';
  static const String pengawasanAkomodasi = '/mobile/oss/pengawasan-akomodasi';
  static const String baselineOta = '/mobile/oss/baseline-ota';

  static String riwayatOssDetail(int id) => '$riwayatOss/$id';

  // Dashboard
  static const String dashboard = '/mobile/dashboard';

  // ---- Dashboard Industri Pariwisata ----
  static const String _dashPariwisata = '/mobile/dashboard-pariwisata';
  static const String dashboardPariwisataFilter =
      '$_dashPariwisata/filter'; // POST: KPI + 4 grafik
  static const String dashboardPariwisataSummary =
      '$_dashPariwisata/summary'; // GET: opsi filter & peringkat

  /// Kab/Kota milik satu provinsi.
  static String dashboardPariwisataKota(String provinsiId) =>
      '$kabupaten/${Uri.encodeComponent(provinsiId)}';

  // ---- Dashboard Okupansi Akomodasi ----
  static const String _dashOkupansi = '/mobile/dashboard-okupansi';
  static const String dashboardOkupansiFilters =
      '$_dashOkupansi/filters'; // GET: tahun, provinsi
  static const String dashboardOkupansiData =
      '$_dashOkupansi/data'; // GET: summary, meta, charts

  // ---- Dashboard Profil Pasar Wisman (Rekap) ----
  static const String _dashRekap = '/mobile/dashboard-wisman-rekap';
  static const String dashboardRekapFilters =
      '$_dashRekap/filters'; // GET: tahun, kewarganegaraan, pintu
  static const String dashboardRekapData = '$_dashRekap/data'; // GET

  // ---- Dashboard Wisman (operasional) ----
  static const String _dashWisman = '/mobile/dashboard-operasional/wisman';
  static const String dashboardWismanFilters =
      '$_dashWisman/filters'; // GET: tahun, provinsi, pintu, nama pintu
  static const String dashboardWismanData = '$_dashWisman/data'; // GET

  // Peta Industri
  static const String petaIndustri = '/mobile/peta-industri';
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

  // Data Proyek BKPM (IPAR Data)
  static const String proyekData = '/mobile/proyek-data';
  static const String proyekDataFilterOptions =
      '/mobile/proyek-data/filter-options';
  static const String proyekDataExport = '/mobile/proyek-data/export';

  // Data Hotel
  static const String dataHotel = '/mobile/data-hotel';
  static String dataHotelDetail(int id) => '$dataHotel/$id';

  // Okupansi Hotel (dipakai Batch 2B)
  static const String okupansiHotel = '/mobile/okupansi-hotel';
  static const String okupansiHotelFilters = '/mobile/okupansi-hotel/filters';

  // BPS - Okupansi Akomodasi Bintang
  static const String okupansiBintang = '/mobile/bps/okupansi-bintang';
  static const String okupansiBintangFilters =
      '/mobile/bps/okupansi-bintang/filters';

  // BPS - Okupansi Akomodasi Non-Bintang
  static const String okupansiNonBintang = '/mobile/bps/okupansi-non-bintang';
  static const String okupansiNonBintangFilters =
      '/mobile/bps/okupansi-non-bintang/filters';

  // //Mobile - CRUD Kelola Akun
  static const String users = '/mobile/users';
  static String userDetail(String kodeUser) {
    final encodedKode = Uri.encodeComponent(kodeUser);
    return '/mobile/users/$encodedKode';
  }
}
