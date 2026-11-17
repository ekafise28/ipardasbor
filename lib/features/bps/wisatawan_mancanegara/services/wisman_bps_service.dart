import 'package:ipardasbor/core/api/api_client.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart';
import 'package:ipardasbor/shared/utils/json_parse.dart' show asMap;

import '../models/wisman_bps_data.dart';
import '../models/wisman_bps_filter.dart';

/// Akses API Wisatawan Mancanegara (BPS). Melempar ApiException; tangkap di UI.
class WismanBpsService {
  WismanBpsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<WismanBpsResult> fetch({
    required WismanBpsFilter filter,
    int page = 1,
  }) async {
    final dynamic r = await _api.get(
      ApiEndpoints.wismanBps,
      queryParameters: filter.toQueryParameters(page),
    );
    return WismanBpsResult.fromJson(asMap(asMap(r)['data']));
  }

  Future<WisatawanOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.wismanBpsFilters);
    return WisatawanOptions.fromJson(asMap(asMap(r)['data']));
  }
}