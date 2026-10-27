import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/okupansi_hotel_data.dart';
import '../models/okupansi_hotel_filter.dart';

/// Akses API Okupansi Hotel. Melempar ApiException; tangkap di level UI.
class OkupansiHotelService {
  OkupansiHotelService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _data(dynamic r) {
    final Map<String, dynamic> body = r is Map<String, dynamic> ? r : <String, dynamic>{};
    return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<OkupansiHotelResult> fetch({
    required OkupansiHotelFilter filter,
    int page = 1,
  }) async {
    final dynamic r = await _api.get(
      ApiEndpoints.okupansiHotel,
      queryParameters: filter.toQueryParameters(page),
    );
    return OkupansiHotelResult.fromJson(_data(r));
  }

  Future<OkupansiHotelOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.okupansiHotelFilters);
    return OkupansiHotelOptions.fromJson(_data(r));
  }
}