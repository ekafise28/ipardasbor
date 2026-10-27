import 'package:ipardasbor/core/api/api_client.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/models/okupansi_hotel_data.dart'
    show OkupansiHotelOptions;

import '../models/okupansi_bintang_data.dart';
import '../models/okupansi_bintang_filter.dart';

/// Akses API Okupansi Akomodasi Bintang. Melempar ApiException; tangkap di UI.
class OkupansiBintangService {
  OkupansiBintangService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _data(dynamic r) {
    final Map<String, dynamic> body =
        r is Map<String, dynamic> ? r : <String, dynamic>{};
    return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<OkupansiBintangResult> fetch({
    required OkupansiBintangFilter filter,
    int page = 1,
  }) async {
    final dynamic r = await _api.get(
      ApiEndpoints.okupansiBintang,
      queryParameters: filter.toQueryParameters(page),
    );
    return OkupansiBintangResult.fromJson(_data(r));
  }

  /// Bentuk JSON-nya sama dengan opsi filter Okupansi Hotel, jadi
  /// kelasnya dipakai ulang.
  Future<OkupansiHotelOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.okupansiBintangFilters);
    return OkupansiHotelOptions.fromJson(_data(r));
  }
}