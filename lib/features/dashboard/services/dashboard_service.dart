import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DashboardData> getDashboard({
    String province = 'jawa-timur',
    String? startDate,
    String? endDate,
    int? districtId,
    String? dataSource,
    String? verificationStatus,
    String? bidangUsaha,
    bool includeMap = false,
  }) async {
    // ApiClient membuang nilai null/kosong, jadi tidak perlu if satu-satu.
    final dynamic response = await _api.get(
      ApiEndpoints.dashboard,
      queryParameters: <String, dynamic>{
        'provinsi': province,
        'include_map': includeMap ? '1' : '0',
        'tanggal_dari': startDate?.trim(),
        'tanggal_sampai': endDate?.trim(),
        'kabupaten_id': districtId,
        'sumber_data': dataSource?.trim(),
        'status_verifikasi': verificationStatus?.trim(),
        'bidang_usaha': bidangUsaha?.trim(),
      },
    );

    if (response is! Map || response['success'] != true) {
      final String pesan =
          response is Map &&
              response['message']?.toString().trim().isNotEmpty == true
          ? response['message'].toString()
          : 'Data dashboard gagal diproses.';
      throw ApiException(message: pesan);
    }

    final dynamic rawData = response['data'];
    if (rawData is! Map) {
      throw const ApiException(
        message: 'Format data dashboard dari server tidak valid.',
      );
    }

    return DashboardData.fromJson(Map<String, dynamic>.from(rawData));
  }

  void dispose() => _api.close();
}
