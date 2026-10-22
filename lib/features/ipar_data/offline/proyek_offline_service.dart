import 'dart:math' as math;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/cache/cache_preferences.dart';
import '../models/proyek_data_filter.dart';
import '../models/proyek_data_parse.dart';
import 'proyek_offline_meta.dart';
import 'proyek_offline_store.dart';

class ProyekOfflineHasil {
  const ProyekOfflineHasil({
    required this.baris,
    required this.ukuranBytes,
    required this.terpotongBatas,
  });

  final int baris;
  final int ukuranBytes;
  final bool terpotongBatas;
}

/// Unduhan manual dataset Data Proyek untuk dipakai offline.
class ProyekOfflineService {
  ProyekOfflineService({ApiClient? apiClient, ProyekOfflineStore? store})
    : _api = apiClient ?? ApiClient(),
      _store = store ?? ProyekOfflineStore.instance;

  static const List<int> pilihanBaris = <int>[500, 1000, 2500, 5000, 10000];
  static const int _barisPerPermintaan = 500;

  final ApiClient _api;
  final ProyekOfflineStore _store;

  /// Mengunduh sampai [targetBaris] baris sesuai [filter], menggantikan
  /// dataset sebelumnya. Mengembalikan null kalau dibatalkan (tidak ada
  /// data yang tersisa). Kalau batas ukuran tercapai, baris yang sudah
  /// masuk tetap disimpan dan [ProyekOfflineHasil.terpotongBatas] true.
  Future<ProyekOfflineHasil?> unduh({
    required ProyekDataFilter filter,
    required int targetBaris,
    void Function(int baris, int ukuranBytes)? onProgress,
    bool Function()? dibatalkan,
  }) async {
    final int batas = CachePreferences.instance.proyekOfflineMaxBytes;

    await _store.hapus(); // dataset baru menggantikan yang lama

    int baris = 0;
    int ukuran = 0;
    int nomor = 0;
    int kursor = 0;
    bool terpotong = false;
    String? provinsiUser;
    bool aksesSemua = false;

    try {
      while (baris < targetBaris) {
        if (dibatalkan?.call() == true) {
          await _store.hapus();
          return null;
        }

        final dynamic res = await _api.get(
          ApiEndpoints.proyekDataOffline,
          queryParameters: <String, dynamic>{
            ...filter.toQueryParameters(1),
            'after_id': kursor,
            'limit': math.min(_barisPerPermintaan, targetBaris - baris),
          }..remove('page')..remove('per_page'),
        );

        final Map<String, dynamic> data =
            (res is Map<String, dynamic>
                ? res['data'] as Map<String, dynamic>?
                : null) ??
            <String, dynamic>{};

        final List<Map<String, dynamic>> items =
            ((data['items'] as List<dynamic>?) ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList();

        if (nomor == 0) {
          provinsiUser = teksAtauNull(data['provinsi_user']);
          aksesSemua = data['akses_semua_wilayah'] == true;
        }
        if (items.isEmpty) break;

        final int? bytes = await _store.simpanChunk(
          nomor,
          items,
          terpakai: ukuran,
          batasBytes: batas,
        );
        if (bytes == null) {
          terpotong = true; // batas ukuran tercapai
          break;
        }

        nomor++;
        baris += items.length;
        ukuran += bytes;
        onProgress?.call(baris, ukuran);

        final int? berikut = angkaAtauNull(data['next_cursor']);
        if (data['has_more'] != true || berikut == null) break;
        kursor = berikut;
      }
    } catch (_) {
      await _store.hapus();
      rethrow;
    }

    if (dibatalkan?.call() == true) {
      await _store.hapus();
      return null;
    }

    if (baris == 0) {
      await _store.hapus();
      return ProyekOfflineHasil(
        baris: 0,
        ukuranBytes: 0,
        terpotongBatas: terpotong,
      );
    }

    await _store.simpanMeta(
      ProyekOfflineMeta(
        baris: baris,
        ukuranBytes: ukuran,
        savedAt: DateTime.now(),
        target: targetBaris,
        ringkasanFilter: filter.ringkasan,
        provinsiUser: provinsiUser,
        aksesSemuaWilayah: aksesSemua,
        terpotongBatas: terpotong,
      ),
    );

    return ProyekOfflineHasil(
      baris: baris,
      ukuranBytes: ukuran,
      terpotongBatas: terpotong,
    );
  }
}