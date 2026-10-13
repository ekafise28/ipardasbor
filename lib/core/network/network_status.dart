import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/api_endpoints.dart';
import '../cache/cache_status.dart';

/// true = tidak ada jaringan sama sekali (mode pesawat / data mati).
class NetworkStatus extends ValueNotifier<bool> {
  NetworkStatus._() : super(false);
  static final NetworkStatus instance = NetworkStatus._();

  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOffline => value;

  Future<void> init() async {
    _terapkan(await Connectivity().checkConnectivity());
    _sub ??= Connectivity().onConnectivityChanged.listen(_terapkan);
  }

  /// Membaca status jaringan langsung dari sistem (bukan nilai tersimpan).
  /// true = ada jaringan. Sekaligus menyinkronkan [value].
  Future<bool> cekOnline() async {
    final List<ConnectivityResult> hasil = await Connectivity()
        .checkConnectivity();
    _terapkan(hasil);
    return !value;
  }

  void _terapkan(List<ConnectivityResult> hasil) {
    value = hasil.every((r) => r == ConnectivityResult.none);
  }
}

class NetworkGuard {
  NetworkGuard._();

  static const String pesanVerifikasi =
      'Perlu koneksi internet untuk verifikasi dan pemeriksaan NIB/KBLI/NKU.';

  /// true = boleh lanjut. Kalau false, snackbar sudah ditampilkan.
  static Future<bool> pastikanOnline(
    BuildContext context, {
    String pesan = pesanVerifikasi,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    bool ok = !NetworkStatus.instance.isOffline;
    // Data di layar dari cache = server baru saja tak terjangkau. Pastikan
    // dulu sebelum membiarkan pengguna mengisi form yang akan gagal dikirim.
    if (ok && CacheStatus.instance.isOffline) ok = await _ping();

    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pesan)));
    }
    return ok;
  }

  static Future<bool> _ping() async {
    try {
      final http.Response r = await http
          .get(Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.health}'))
          .timeout(const Duration(seconds: 4));
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
