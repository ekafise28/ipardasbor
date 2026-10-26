// Pemanggil API dashboard Okupansi.

import '../../../core/api/api_client.dart';
import '../models/okupansi_dashboard_data.dart';
import '../models/okupansi_filter.dart';
import '../okupansi_endpoints.dart';

class OkupansiService {
  OkupansiService(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// GET /filters -> opsi filter.
  Future<OkupansiFilterOptions> fetchFilters() async {
    final dynamic json = await _api.get(OkupansiEndpoints.filters);
    return OkupansiFilterOptions.fromJson(_map(_map(json)['data']));
  }

  /// GET /data?tahun[0]=...&bulan[0]=... -> seluruh data dashboard.
  Future<OkupansiDashboardData> fetchDashboard(OkupansiFilter filter) async {
    final dynamic json = await _api.get(
      OkupansiEndpoints.data,
      queryParameters: filter.toQueryParams(),
    );
    return OkupansiDashboardData.fromJson(_map(_map(json)['data']));
  }
}
