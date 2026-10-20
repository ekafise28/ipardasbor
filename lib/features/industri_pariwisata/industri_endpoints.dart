// Alamat API khusus fitur Industri Pariwisata.
// Dipisah dari ApiEndpoints supaya file lama tidak perlu diubah.

import '../../core/api/api_endpoints.dart';

class IndustriEndpoints {
  IndustriEndpoints._();

  // Harus sama dengan prefix route di routes/api.php.
  // baseUrl (sudah berisi /api) ditambahkan otomatis oleh ApiClient.
  static const String _base = '/mobile/dashboard-pariwisata';

  static const String filter = '$_base/filter'; // POST: KPI + 4 grafik
  static const String summary =
      '$_base/summary'; // GET: opsi filter & peringkat
  static const String rawData = '$_base/raw-data'; // GET: data mentah

  /// Kab/Kota milik satu provinsi. Memakai ApiEndpoints.kabupaten yang
  /// sudah ada ('/mobile/wilayah/kabupaten'), tanpa mengubah file itu.
  static String kota(String provinsiId) =>
      '${ApiEndpoints.kabupaten}/${Uri.encodeComponent(provinsiId)}';
}
