import 'package:ipardasbor/core/api/api_client.dart';
import 'package:ipardasbor/core/api/api_endpoints.dart';
import 'package:ipardasbor/shared/utils/json_parse.dart' show asMap;
import 'package:ipardasbor/shared/widgets/list_filters.dart';

import '../models/wisnus_bps_data.dart';
import '../models/wisnus_bps_filter.dart';

/// Akses API Wisatawan Nusantara (BPS). Melempar ApiException; tangkap di UI.
class WisnusBpsService {
  WisnusBpsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.shared;

  final ApiClient _api;

  Future<WisnusBpsResult> fetch({
    required WisnusBpsFilter filter,
    int page = 1,
  }) async {
    final dynamic r = await _api.get(
      ApiEndpoints.wisnusBps,
      queryParameters: filter.toQueryParameters(page),
    );
    return WisnusBpsResult.fromJson(asMap(asMap(r)['data']));
  }

  Future<FilterOptions> fetchOptions() async {
    final dynamic r = await _api.get(ApiEndpoints.wisnusBpsFilters);
    return FilterOptions.fromJson(asMap(asMap(r)['data']));
  }
}