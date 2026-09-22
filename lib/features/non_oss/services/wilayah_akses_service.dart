import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/wilayah_akses.dart';

/// Menyimpan wilayah kewenangan akun di perangkat supaya dropdown tetap
/// terbatas walau offline. Belum ada cache -> tidak menyaring (server tetap
/// menolak data di luar wilayah).
class WilayahAksesService {
  WilayahAksesService._();

  static final WilayahAksesService instance = WilayahAksesService._();

  static const String _prefsKey = 'wilayah_akses_v1';

  WilayahAkses? _cache;
  bool _loaded = false;

  Future<WilayahAkses?> current() async {
    if (_loaded) return _cache;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw != null) {
        _cache = WilayahAkses.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      _cache = null;
    }

    _loaded = true;
    return _cache;
  }

  /// Ambil dari server dan simpan. Gagal/offline: cache lama tetap dipakai.
  Future<void> refresh({ApiClient? apiClient}) async {
    final ApiClient api = apiClient ?? ApiClient();

    try {
      final dynamic response = await api.get(ApiEndpoints.wilayahAkses);
      final Map<String, dynamic> body = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};
      final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final WilayahAkses akses = WilayahAkses.fromJson(data);
      _cache = akses;
      _loaded = true;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(akses.toJson()));
    } catch (_) {
      // Sengaja diabaikan: offline atau server bermasalah.
    } finally {
      if (apiClient == null) api.close();
    }
  }

  /// Panggil saat logout supaya akun berikutnya tidak memakai wilayah lama.
  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}