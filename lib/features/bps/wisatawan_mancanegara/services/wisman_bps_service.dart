import 'package:ipardasbor/core/api/api_client.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/shared/utils/json_parse.dart' show asMap;
import 'package:ipardasbor/shared/widgets/list_filters.dart';

import '../models/wisman_bps_data.dart';
import '../models/wisman_bps_filter.dart';

/// Akses API Wisatawan Mancanegara (BPS). Melempar ApiException; tangkap di UI.
class WismanBpsService {
  WismanBpsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.shared;

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

  Future<FilterOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.wismanBpsFilters);
    return FilterOptions.fromJson(asMap(asMap(r)['data']));
  }
}