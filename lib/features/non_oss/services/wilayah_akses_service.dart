import 'dart:convert';

import 'package:flutter/foundation.dart'; // TAMBAHAN DEBUG - untuk debugPrint
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/wilayah_akses.dart';

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

  Future<void> refresh({ApiClient? apiClient}) async {
    final ApiClient api = apiClient ?? ApiClient();

    try {
      final dynamic response = await api.get(ApiEndpoints.wilayahAkses);
      // debugPrint('[WILAYAH_AKSES] raw response: $response'); // TAMBAHAN DEBUG

      final Map<String, dynamic> body = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};
      final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;

      if (data == null) {
        // debugPrint('[WILAYAH_AKSES] data null, refresh dibatalkan'); // TAMBAHAN DEBUG
        return;
      }

      final WilayahAkses akses = WilayahAkses.fromJson(data);
      debugPrint( // TAMBAHAN DEBUG
        '[WILAYAH_AKSES] parsed: fullAccess=${akses.fullAccess}, '
        'provinsi=${akses.provinsiIds}, kabupaten=${akses.kabupatenIds}',
      );

      _cache = akses;
      _loaded = true;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(akses.toJson()));
    } catch (e, st) {
      debugPrint('[WILAYAH_AKSES] refresh GAGAL: $e'); // TAMBAHAN DEBUG
      debugPrint('$st'); // TAMBAHAN DEBUG
    } finally {
      if (apiClient == null) api.close();
    }
  }

  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}