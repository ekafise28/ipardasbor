import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  DashboardService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DashboardData> getDashboard({
    String province = 'jawa-timur',
    String? startDate,
    String? endDate,
    int? districtId,
    String? dataSource,
    String? verificationStatus,
    bool includeMap = false,
  }) async {
    final String? accessToken = await SecureStorage.getAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw ApiException(
        message: 'Sesi login telah berakhir. Silakan login kembali.',
        statusCode: 401,
      );
    }

    final Map<String, String> queryParameters = {
      'provinsi': province,
      'include_map': includeMap ? '1' : '0',
    };

    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParameters['tanggal_dari'] = startDate.trim();
    }

    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParameters['tanggal_sampai'] = endDate.trim();
    }

    if (districtId != null) {
      queryParameters['kabupaten_id'] = districtId.toString();
    }

    if (dataSource != null && dataSource.trim().isNotEmpty) {
      queryParameters['sumber_data'] = dataSource.trim();
    }

    if (verificationStatus != null && verificationStatus.trim().isNotEmpty) {
      queryParameters['status_verifikasi'] = verificationStatus.trim();
    }

    final Uri uri = ApiEndpoints.uri(
      ApiEndpoints.dashboard,
      queryParameters: queryParameters,
    );

    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${accessToken.trim()}',
            },
          )
          .timeout(const Duration(seconds: 35));

      final Map<String, dynamic> responseBody = _decodeResponse(response.body);

      if (response.statusCode == 401) {
        throw ApiException(
          message: 'Sesi login telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 403) {
        throw ApiException(
          message: 'Anda tidak memiliki izin mengakses dashboard.',
          statusCode: 403,
        );
      }

      if (response.statusCode == 422) {
        throw ApiException(
          message: _readErrorMessage(
            responseBody,
            fallback: 'Filter dashboard tidak valid.',
          ),
          statusCode: 422,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _readErrorMessage(
            responseBody,
            fallback: 'Data dashboard gagal diambil dari server.',
          ),
          statusCode: response.statusCode,
        );
      }

      if (responseBody['success'] != true) {
        throw ApiException(
          message: _readErrorMessage(
            responseBody,
            fallback: 'Data dashboard gagal diproses.',
          ),
          statusCode: response.statusCode,
        );
      }

      final dynamic rawData = responseBody['data'];

      if (rawData is! Map) {
        throw ApiException(
          message: 'Format data dashboard dari server tidak valid.',
          statusCode: response.statusCode,
        );
      }

      return DashboardData.fromJson(Map<String, dynamic>.from(rawData));
    } on TimeoutException {
      throw ApiException(
        message: 'Server terlalu lama merespons. Silakan coba kembali.',
        statusCode: 408,
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException(
        message: 'Respons dashboard dari server tidak valid.',
        statusCode: 500,
      );
    } on http.ClientException {
      throw ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        statusCode: 503,
      );
    } catch (_) {
      throw ApiException(
        message: 'Terjadi kesalahan ketika mengambil data dashboard.',
        statusCode: 500,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const FormatException('Respons server bukan object JSON.');
  }

  String _readErrorMessage(
    Map<String, dynamic> responseBody, {
    required String fallback,
  }) {
    final dynamic message = responseBody['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final dynamic errors = responseBody['errors'];

    if (errors is Map) {
      for (final dynamic value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return fallback;
  }

  void dispose() {
    _client.close();
  }
}
