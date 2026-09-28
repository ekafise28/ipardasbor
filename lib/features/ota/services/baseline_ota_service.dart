import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/baseline_ota_filter.dart';
import '../models/baseline_ota_page_result.dart';

class BaselineOtaService {
  BaselineOtaService(this._api);

  final ApiClient _api;

  Future<BaselineOtaPageResult> list(BaselineOtaFilter filter, {int page = 1}) async {
    final dynamic response = await _api.get(
      ApiEndpoints.baselineOta,
      queryParameters: filter.toQueryParams(page),
    );

    if (response is! Map) {
      throw Exception('Respons daftar baseline OTA tidak valid.');
    }

    return BaselineOtaPageResult.fromJson(Map<String, dynamic>.from(response));
  }
}