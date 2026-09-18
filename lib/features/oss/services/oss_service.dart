import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/oss_form_data.dart';
import '../models/oss_validasi_result.dart';

class OssService {
  OssService(this._api);

  final ApiClient _api;

  /// Cek kombinasi NIB + KBLI + NKU ke backend (yang meneruskan ke API OSS
  /// pemerintah).
  Future<OssValidasiResult> validasi({
    required String nib,
    required String kbli,
    required String nku,
  }) async {
    final dynamic response = await _api.post(
      ApiEndpoints.validasiOss,
      body: {'nib': nib, 'kbli': kbli, 'nku': nku},
    );

    if (response is! Map) {
      throw const ApiException(message: 'Respons validasi OSS tidak valid.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(response);

    return OssValidasiResult(
      nib: nib,
      kbli: kbli,
      nku: nku,
      kbliDesc: '',
      isValid: data['valid'] == true,
    );
  }

  /// Kirim data pengawasan OSS + foto dokumentasi (multipart), sama seperti
  /// alur Non-OSS. `data.toFields()` HARUS mengirim juga 'nib', 'kbli', 'nku'
  /// (lihat catatan di INTEGRASI_BATCH_2.md kalau field itu belum ada).
  Future<dynamic> submit(OssFormData data) {
    return _multipart(
      data.toFields(),
      data.photos.map((photo) => photo.path).toList(growable: false),
    );
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
      ApiEndpoints.pengawasanOss,
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