import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/oss_proyek_filter.dart';
import '../models/oss_proyek_page_result.dart';

/// Akses data daftar proyek OSS akomodasi (tabel verifikasi di web).
///
/// Melempar [ApiException] kalau request gagal; tangkap di level UI supaya
/// pesannya tampil ke petugas (pola sama dengan [RiwayatService]).
class OssProyekService {
  OssProyekService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OssProyekPageResult> fetch({
    required OssProyekFilter filter,
    int page = 1,
  }) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.proyekOss,
      queryParameters: filter.toQueryParameters(page),
    );

    final Map<String, dynamic> body = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};

    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return OssProyekPageResult.fromJson(data);
  }
}