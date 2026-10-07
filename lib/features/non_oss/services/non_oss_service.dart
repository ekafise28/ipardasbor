import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  static final Map<String, List<MapEntry<String, String>>> _cacheJenisProduk =
      <String, List<MapEntry<String, String>>>{};

  static String _kunciCache(String bidang) => 'jenis_produk_bidang_$bidang';

  Future<List<MapEntry<String, String>>> jenisProduk(String bidang) async {
    // 1) Cache memori (paling cepat).
    final memori = _cacheJenisProduk[bidang];
    if (memori != null) return memori;

    // 2) Server. Kalau berhasil, simpan permanen.
    try {
      final dynamic response = await _api.get(
        ApiEndpoints.jenisProdukBidang(bidang),
      );
      final dynamic data = response is Map ? response['data'] : null;

      if (data is List) {
        final hasil = data
            .whereType<Map>()
            .map(
              (Map e) => MapEntry(e['kode'].toString(), e['label'].toString()),
            )
            .toList(growable: false);

        if (hasil.isNotEmpty) {
          _cacheJenisProduk[bidang] = hasil;
          await _simpanPermanen(bidang, hasil);
          return hasil;
        }
      }
    } catch (_) {
      // Lanjut ke salinan tersimpan di bawah.
    }

    // 3) Gagal/offline: pakai salinan terakhir yang tersimpan di perangkat.
    final tersimpan = await _bacaPermanen(bidang);
    if (tersimpan.isNotEmpty) {
      _cacheJenisProduk[bidang] = tersimpan;
      return tersimpan;
    }

    // Belum pernah berhasil dimuat sama sekali.
    throw Exception('Daftar jenis produk belum pernah dimuat.');
  }

  Future<void> _simpanPermanen(
    String bidang,
    List<MapEntry<String, String>> daftar,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kunciCache(bidang),
        jsonEncode(
          daftar
              .map((e) => <String, String>{'kode': e.key, 'label': e.value})
              .toList(),
        ),
      );
    } catch (_) {
      // Gagal menyimpan cache tidak boleh mengganggu alur utama.
    }
  }

  static Future<List<MapEntry<String, String>>> _bacaPermanen(
    String bidang,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kunciCache(bidang));
      if (raw == null) return const <MapEntry<String, String>>[];

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const <MapEntry<String, String>>[];

      return decoded
          .whereType<Map>()
          .map((Map e) => MapEntry(e['kode'].toString(), e['label'].toString()))
          .toList(growable: false);
    } catch (_) {
      return const <MapEntry<String, String>>[];
    }
  }

  static Future<List<MapEntry<String, String>>> jenisProdukTersimpan(
    String bidang,
  ) async {
    final memori = _cacheJenisProduk[bidang];
    if (memori != null) return memori;
    return _bacaPermanen(bidang);
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
