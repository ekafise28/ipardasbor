import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/app_navigator.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final Map<String, String> parameters = {};

    queryParameters.forEach((String key, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        parameters[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: parameters);
  }

  Future<Map<String, String>> _headers({bool useToken = true}) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (useToken) {
      final String? token = await SecureStorage.getAccessToken();

      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useToken = true,
  }) async {
    try {
      final http.Response response = await _client
          .get(
            _buildUri(endpoint, queryParameters),
            headers: await _headers(useToken: useToken),
          )
          .timeout(_timeout);

      return await _processResponse(response, handleSessionExpired: useToken);
    } on TimeoutException {
      throw const ApiException(
        message: 'Waktu koneksi habis. Silakan periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useToken = true,
  }) async {
    try {
      final http.Response response = await _client
          .post(
            _buildUri(endpoint),
            headers: await _headers(useToken: useToken),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(_timeout);

      return await _processResponse(response, handleSessionExpired: useToken);
    } on TimeoutException {
      throw const ApiException(
        message: 'Waktu koneksi habis. Silakan periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool useToken = true,
  }) async {
    try {
      final http.Response response = await _client
          .put(
            _buildUri(endpoint),
            headers: await _headers(useToken: useToken),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(_timeout);

      return await _processResponse(response, handleSessionExpired: useToken);
    } on TimeoutException {
      throw const ApiException(
        message: 'Waktu koneksi habis. Silakan periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<dynamic> delete(String endpoint, {bool useToken = true}) async {
    try {
      final http.Response response = await _client
          .delete(
            _buildUri(endpoint),
            headers: await _headers(useToken: useToken),
          )
          .timeout(_timeout);

      return await _processResponse(response, handleSessionExpired: useToken);
    } on TimeoutException {
      throw const ApiException(
        message: 'Waktu koneksi habis. Silakan periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<dynamic> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool useToken = true,
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        _buildUri(endpoint),
      );

      final Map<String, String> headers = await _headers(useToken: useToken);

      // MultipartRequest akan membuat Content-Type beserta boundary sendiri.
      headers.remove('Content-Type');

      request.headers.addAll(headers);
      request.fields.addAll(fields);
      request.files.addAll(files);

      final http.StreamedResponse streamedResponse = await _client
          .send(request)
          .timeout(_timeout);

      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );

      return await _processResponse(response, handleSessionExpired: useToken);
    } on TimeoutException {
      throw const ApiException(
        message: 'Waktu unggah habis. Silakan periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  Future<dynamic> _processResponse(
    http.Response response, {
    required bool handleSessionExpired,
  }) async {
    dynamic responseData;

    if (response.body.trim().isNotEmpty) {
      try {
        responseData = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Respons dari server tidak valid.',
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    String message = 'Terjadi kesalahan pada server.';
    Map<String, dynamic>? errors;

    if (responseData is Map<String, dynamic>) {
      message = responseData['message']?.toString().trim().isNotEmpty == true
          ? responseData['message'].toString()
          : message;

      if (responseData['errors'] is Map) {
        errors = Map<String, dynamic>.from(responseData['errors'] as Map);
      }
    }

    switch (response.statusCode) {
      case 401:
        if (handleSessionExpired) {
          message = 'Sesi login telah berakhir. Silakan masuk kembali.';
          await AppNavigator.handleSessionExpired();
        } else if (message == 'Terjadi kesalahan pada server.') {
          message = 'Login gagal. Periksa kembali akun dan kata sandi.';
        }
        break;

      case 419:
        if (handleSessionExpired) {
          message = 'Sesi login telah kedaluwarsa. Silakan masuk kembali.';
          await AppNavigator.handleSessionExpired();
        } else {
          message = 'Sesi permintaan telah kedaluwarsa. Silakan coba kembali.';
        }
        break;

      case 403:
        message = 'Anda tidak memiliki akses untuk melakukan proses ini.';
        break;

      case 404:
        message = 'Data atau alamat API tidak ditemukan.';
        break;

      case 422:
        message = responseData is Map<String, dynamic>
            ? responseData['message']?.toString() ??
                  'Data yang dikirim belum valid.'
            : 'Data yang dikirim belum valid.';
        break;

      case 500:
        message = 'Terjadi gangguan pada server. Silakan coba kembali.';
        break;

      case 502:
      case 503:
      case 504:
        message = 'Server sedang tidak tersedia. Silakan coba kembali.';
        break;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }

  void close() {
    _client.close();
  }
}
