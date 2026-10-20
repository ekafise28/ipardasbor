import '../../../core/api/api_client.dart';
import '../industri_endpoints.dart';
import '../models/industri_dashboard_data.dart';
import '../models/industri_filter.dart';
import '../models/industri_option.dart';
import '../models/industri_parse.dart';
import '../models/industri_ranking.dart';

class IndustriPariwisataService {
  IndustriPariwisataService(this._api);

  final ApiClient _api;

  /// Pilihan filter (tahun, provinsi, KBLI).
  /// GET /summary?section=filters
  Future<IndustriFilterOptions> fetchFilterOptions() async {
    final dynamic json = await _api.get(
      IndustriEndpoints.summary,
      queryParameters: {'section': 'filters'},
    );
    return IndustriFilterOptions.fromJson(parseMap(parseMap(json)['filters']));
  }

  /// 3 kartu KPI + 4 grafik, sesuai filter.
  /// POST /filter (filter dikirim sebagai JSON body).
  Future<IndustriDashboardData> fetchDashboard(IndustriFilter filter) async {
    final dynamic json = await _api.post(
      IndustriEndpoints.filter,
      body: filter.toJson(),
    );
    return IndustriDashboardData.fromJson(parseMap(json));
  }

  /// Satu tabel peringkat Top 20 (dipakai di tahap berikutnya).
  /// GET /summary?section=<pariwisata|kbli|provinsi|kota>&tahun[0]=...
  Future<List<IndustriRankingRow>> fetchRanking(
    IndustriRankingSection section,
    IndustriFilter filter,
  ) async {
    final dynamic json = await _api.get(
      IndustriEndpoints.summary,
      queryParameters: {...filter.toQueryParams(), 'section': section.key},
    );

    return parseList(parseMap(json)[section.key])
        .whereType<Map>()
        .map(
          (row) => IndustriRankingRow.fromJson(
            section,
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  /// Daftar kabupaten/kota milik satu provinsi.
  Future<List<IndustriOption>> fetchKota(String provinsiId) async {
    final dynamic json = await _api.get(IndustriEndpoints.kota(provinsiId));

    // Server bisa membalas langsung berupa list, atau dibungkus {"data": [...]}.
    final List<dynamic> rows = json is List
        ? json
        : parseList(parseMap(json)['data']);

    final List<IndustriOption> result = [];
    for (final dynamic row in rows) {
      if (row is! Map) continue;
      final IndustriOption? option = IndustriOption.kotaFromJson(
        Map<String, dynamic>.from(row),
      );
      if (option != null) result.add(option);
    }
    return result;
  }
}
