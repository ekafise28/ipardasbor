// Pemanggil API dashboard Wisman.

import '../../../core/api/api_client.dart';
import '../models/wisman_dashboard_data.dart';
import '../models/wisman_filter.dart';
import '../wisman_endpoints.dart';

class WismanService {
  WismanService(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// GET /filters -> opsi filter.
  Future<WismanFilterOptions> fetchFilters() async {
    final dynamic json = await _api.get(WismanEndpoints.filters);
    return WismanFilterOptions.fromJson(_map(_map(json)['data']));
  }

  /// GET /data?tahun[0]=...&bulan[0]=... -> seluruh data dashboard.
  Future<WismanDashboardData> fetchDashboard(WismanFilter filter) async {
    final dynamic json = await _api.get(
      WismanEndpoints.data,
      queryParameters: filter.toQueryParams(),
    );
    return WismanDashboardData.fromJson(_map(_map(json)['data']));
  }
}
