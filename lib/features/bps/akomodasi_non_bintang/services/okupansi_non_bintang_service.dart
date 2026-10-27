import 'package:ipardasbor/core/api/api_client.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/models/okupansi_hotel_data.dart'
    show OkupansiHotelOptions;

import '../models/okupansi_non_bintang_data.dart';
import '../models/okupansi_non_bintang_filter.dart';

/// Akses API Okupansi Non-Bintang. Melempar ApiException; tangkap di UI.
class OkupansiNonBintangService {
  OkupansiNonBintangService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _data(dynamic r) {
    final Map<String, dynamic> body =
        r is Map<String, dynamic> ? r : <String, dynamic>{};
    return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<OkupansiNonBintangResult> fetch({
    required OkupansiNonBintangFilter filter,
    int page = 1,
  }) async {
    final dynamic r = await _api.get(
      ApiEndpoints.okupansiNonBintang,
      queryParameters: filter.toQueryParameters(page),
    );
    return OkupansiNonBintangResult.fromJson(_data(r));
  }

  /// Bentuk JSON-nya sama dengan opsi filter Okupansi Hotel, jadi
  /// kelasnya dipakai ulang (sama seperti service Bintang).
  Future<OkupansiHotelOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.okupansiNonBintangFilters);
    return OkupansiHotelOptions.fromJson(_data(r));
  }
}