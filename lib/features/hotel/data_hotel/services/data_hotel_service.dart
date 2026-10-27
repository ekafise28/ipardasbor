import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/hotel_filter.dart';
import '../models/hotel_item.dart';
import '../models/hotel_page_result.dart';

/// Akses API Data Hotel. Melempar ApiException; tangkap di level UI.
class DataHotelService {
  DataHotelService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _data(dynamic r) {
    final Map<String, dynamic> body = r is Map<String, dynamic> ? r : <String, dynamic>{};
    return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<HotelPageResult> fetch({required HotelFilter filter, int page = 1}) async {
    final dynamic r = await _api.get(
      ApiEndpoints.dataHotel,
      queryParameters: filter.toQueryParameters(page),
    );
    return HotelPageResult.fromJson(_data(r));
  }

  Future<HotelItem> detail(int id) async {
    final dynamic r = await _api.get(ApiEndpoints.dataHotelDetail(id));
    return HotelItem.fromJson(_data(r));
  }

  // ---- CRUD (dipakai Batch 3, hanya tampil untuk Admin) ----

  Future<void> create(Map<String, dynamic> payload) =>
      _api.post(ApiEndpoints.dataHotel, body: payload);

  Future<void> update(int id, Map<String, dynamic> payload) =>
      _api.put(ApiEndpoints.dataHotelDetail(id), body: payload);

  Future<void> remove(int id) => _api.delete(ApiEndpoints.dataHotelDetail(id));
}