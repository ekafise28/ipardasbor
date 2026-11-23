import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/riwayat_filter.dart';
import '../models/riwayat_page_result.dart';
import '../models/riwayat_detail.dart';

/// Lapisan akses data untuk fitur Riwayat.
///
/// Membungkus ApiClient supaya halaman/widget tidak perlu tahu detail
/// endpoint atau bentuk mentah response JSON.
class RiwayatService {
  RiwayatService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.shared;

  final ApiClient _apiClient;

  /// Mengambil satu halaman data riwayat sesuai [filter] dan nomor [page].
  ///
  /// Melempar [ApiException] (dari core/api) apabila request gagal -
  /// biarkan exception ini ditangkap di level UI (RiwayatPage) supaya
  /// pesannya bisa ditampilkan langsung ke user.
  Future<RiwayatPageResult> fetch({
    required RiwayatFilter filter,
    int page = 1,
  }) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.riwayatOss,
      queryParameters: filter.toQueryParameters(page),
    );

    // debugPrint('DEBUG riwayat response: $response'); // tambahkan ini sementara

    final Map<String, dynamic> body = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};

    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return RiwayatPageResult.fromJson(data);
  }

  /// Mengambil detail lengkap satu item riwayat berdasarkan [id].
  ///
  /// Melempar [ApiException] jika request gagal (termasuk 404 saat data
  /// tidak ditemukan atau di luar akses wilayah user).
  Future<RiwayatDetail> fetchDetail(int id) async {
    final dynamic response = await _apiClient.get(
      ApiEndpoints.riwayatOssDetail(id),
    );

    final Map<String, dynamic> body = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};

    final Map<String, dynamic> data =
        (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return RiwayatDetail.fromJson(data);
  }

  /// Simpan hasil edit (POST multipart ke endpoint detail).
  /// [fields] dari NonOssFormData.toUpdateFields(); [fotoBaruPaths] hanya
  /// foto baru. Melempar ApiException (409 = data sudah diubah orang lain).
  Future<void> update(
    int id, {
    required Map<String, String> fields,
    required List<String> fotoBaruPaths,
  }) async {
    final List<http.MultipartFile> files = <http.MultipartFile>[];

    for (final String path in fotoBaruPaths) {
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

    await _apiClient.multipartPost(
      ApiEndpoints.riwayatOssDetail(id),
      fields: fields,
      files: files,
    );
  }
}
