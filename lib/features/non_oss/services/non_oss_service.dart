import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/non_oss_form_data.dart';
import '../offline/non_oss_local_data.dart';

class NonOssService {
  NonOssService(this._api);

  final ApiClient _api;

  Future<bool> isServerAvailable() async {
    try {
      final dynamic response = await _api
          .get(ApiEndpoints.health)
          .timeout(const Duration(seconds: 3));

      return response is Map &&
          (response['status'] == 'ok' || response['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> submit(NonOssFormData data) {
    return _multipart(
      data.toFields(),
      data.photos.map((photo) => photo.path).toList(growable: false),
    );
  }

  Future<dynamic> submitLocal(NonOssLocalData data) {
    return _multipart(data.payload, data.photoPaths);
  }

  bool isConnectionFailure(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return true;
    }

    final String message = error.toString().toLowerCase();
    const List<String> networkMessages = <String>[
      'socketexception',
      'clientexception',
      'connection refused',
      'connection reset',
      'connection closed',
      'failed host lookup',
      'network is unreachable',
      'no route to host',
      'timed out',
      'timeout',
      'waktu unggah habis',
      'waktu koneksi habis',
    ];

    return networkMessages.any(message.contains);
  }

  Future<dynamic> _multipart(
    Map<String, String> fields,
    List<String> photoPaths,
  ) async {
    final List<http.MultipartFile> files = <http.MultipartFile>[];

    for (final String path in photoPaths) {
      final File file = File(path);
      if (!await file.exists()) {
        throw Exception('Foto lokal tidak ditemukan: $path');
      }

      files.add(
        await http.MultipartFile.fromPath(
          'foto_dokumentasi[]',
          path,
          filename: file.uri.pathSegments.last,
        ),
      );
    }

    return _api.multipartPost(
      ApiEndpoints.pengawasanNonOss,
      fields: Map<String, String>.from(fields),
      files: files,
    );
  }

  int? serverIdFrom(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final dynamic body = response['data'];
    final dynamic value = body is Map ? body['id'] : response['id'];

    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }
}
