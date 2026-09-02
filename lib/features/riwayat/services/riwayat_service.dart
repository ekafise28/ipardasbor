import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/riwayat_filter.dart';
import '../models/riwayat_page_result.dart';

/// Lapisan akses data untuk fitur Riwayat.
///
/// Membungkus ApiClient supaya halaman/widget tidak perlu tahu detail
/// endpoint atau bentuk mentah response JSON.
class RiwayatService {
  RiwayatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Mengambil satu halaman data riwayat sesuai [filter] dan nomor [page].
  ///
  /// Melempar [ApiException] (dari core/api) apabila request gagal —
  /// biarkan exception ini ditangkap di level UI (RiwayatPage) supaya
  /// pesannya bisa ditampilkan langsung ke user.
  Future<RiwayatPageResult> fetch({
    required RiwayatFilter filter,
    int page = 1,
  }) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.riwayatOss,
      queryParameters: filter.toQueryParameters(page),
    );

    final Map<String, dynamic> body =
        response is Map<String, dynamic> ? response : <String, dynamic>{};

    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return RiwayatPageResult.fromJson(data);
  }
}