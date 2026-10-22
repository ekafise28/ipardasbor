import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/proyek_data_filter.dart';
import '../models/proyek_data_option.dart';
import '../models/proyek_data_page_result.dart';

/// Akses data Data Proyek BKPM. Melempar ApiException kalau gagal;
/// tangkap di level UI (pola sama dengan [OssProyekService]).
class ProyekDataService {
  ProyekDataService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Pilihan batas baris unduhan di aplikasi. Unduhan lengkap lewat web.
  static const List<int> batasUnduh = <int>[500, 1000, 2500, 5000, 10000];

  /// Mengunduh CSV sesuai filter ke folder sementara. [onProgress] menerima
  /// jumlah baris data (tanpa header) yang sudah diterima. Mengembalikan
  /// null kalau dibatalkan.
  Future<File?> unduhCsv({
    required ProyekDataFilter filter,
    required int batasBaris,
    void Function(int baris)? onProgress,
    bool Function()? dibatalkan,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final String stempel = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final File file = File('${dir.path}/data-proyek-$stempel.csv');

    final Map<String, dynamic> params =
        <String, dynamic>{...filter.toQueryParameters(1), 'limit': batasBaris}
          ..remove('page')
          ..remove('per_page');

    Future<void> buang() async {
      if (await file.exists()) await file.delete();
    }

    try {
      await _apiClient.downloadToFile(
        ApiEndpoints.proyekDataExport,
        queryParameters: params,
        file: file,
        dibatalkan: dibatalkan,
        // Baris pertama adalah header.
        onProgress: (int byte, int baris) =>
            onProgress?.call(baris > 0 ? baris - 1 : 0),
      );
    } catch (_) {
      await buang();
      rethrow;
    }

    if (dibatalkan?.call() == true) {
      await buang();
      return null;
    }
    return file;
  }

  Future<ProyekDataPageResult> fetch({
    required ProyekDataFilter filter,
    int page = 1,
  }) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.proyekData,
      queryParameters: filter.toQueryParameters(page),
    );

    final Map<String, dynamic> body = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};

    return ProyekDataPageResult.fromJson(
      (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Future<ProyekDataOptionResult> fetchOptions({
    required ProyekDataOptionType tipe,
    String q = '',
    String? provinsi,
  }) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.proyekDataFilterOptions,
      queryParameters: <String, dynamic>{
        'type': tipe.param,
        'q': q.trim(),
        'provinsi': provinsi,
      },
    );

    final Map<String, dynamic> body = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};

    final List<dynamic> mentah =
        (body['data'] as List<dynamic>?) ?? const <dynamic>[];

    return ProyekDataOptionResult(
      options: mentah
          .whereType<Map<String, dynamic>>()
          .map(ProyekDataOption.fromJson)
          .toList(),
      message: body['message']?.toString(),
    );
  }
}