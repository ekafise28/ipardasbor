// Pemanggil API dashboard Profil Pasar Wisman.

import '../../../core/api/api_client.dart';
import '../models/rekap_dashboard_data.dart';
import '../models/rekap_filter.dart';
import '../rekap_endpoints.dart';

class RekapService {
  RekapService(this._api);

  final ApiClient _api;

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// GET /filters -> opsi filter.
  Future<RekapFilterOptions> fetchFilters() async {
    final dynamic json = await _api.get(RekapEndpoints.filters);
    return RekapFilterOptions.fromJson(_map(_map(json)['data']));
  }

  /// GET /data?tahun[0]=...&bulan[0]=... -> seluruh data dashboard.
  Future<RekapDashboardData> fetchDashboard(RekapFilter filter) async {
    final dynamic json = await _api.get(
      RekapEndpoints.data,
      queryParameters: filter.toQueryParams(),
    );
    return RekapDashboardData.fromJson(_map(_map(json)['data']));
  }
}
