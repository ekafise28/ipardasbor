// Pemanggil API dashboard Okupansi.

import 'package:ipardasbor/core/api/api_endpoints.dart';

import '../../../core/api/api_client.dart';
import '../models/okupansi_dashboard_data.dart';
import '../models/okupansi_filter.dart';

class OkupansiService {
  OkupansiService(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// GET /filters -> opsi filter.
  Future<OkupansiFilterOptions> fetchFilters() async {
    final dynamic json = await _api.get(ApiEndpoints.dashboardOkupansiFilters);
    return OkupansiFilterOptions.fromJson(_map(_map(json)['data']));
  }

  /// GET /data?tahun[0]=...&bulan[0]=... -> seluruh data dashboard.
  Future<OkupansiDashboardData> fetchDashboard(OkupansiFilter filter) async {
    final dynamic json = await _api.get(
      ApiEndpoints.dashboardOkupansiData,
      queryParameters: filter.toQueryParams(),
    );
    return OkupansiDashboardData.fromJson(_map(_map(json)['data']));
  }
}
