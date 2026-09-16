import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_fetch_status.dart';

class LocationResult {
  const LocationResult({
    required this.position,
    required this.source,
    this.savedAt,
  });

  final Position position;
  final LocationSource source;
  final DateTime? savedAt;
}

class LocationService {
  static const _kCacheLatKey = 'last_manual_location_lat';
  static const _kCacheLngKey = 'last_manual_location_lng';
  static const _kCacheTimeKey = 'last_manual_location_time';

  Future<LocationResult?> current({
    void Function(LocationFetchStatus status)? onStatus,
    void Function(int sisaDetik)? onCountdown,
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    onStatus?.call(LocationFetchStatus.memintaIzin);

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Aktifkan izin lokasi melalui pengaturan aplikasi.');
    }

    // Dicek di depan. Kalau tidak ada internet, tidak perlu mencoba GPS
    // langsung sama sekali — langsung ke jalur cadangan.
    final bool adaInternet = await _cekInternet();

    if (!adaInternet) {
      return _pakaiCadanganAtauGagal(onStatus, adaInternet: false);
    }

    final bool layananAktif = await Geolocator.isLocationServiceEnabled();

    if (!layananAktif) {
      return _pakaiCadanganAtauGagal(onStatus, adaInternet: true);
    }

    onStatus?.call(LocationFetchStatus.mencariSinyalGps);

    int sisaDetik = timeLimit.inSeconds;
    onCountdown?.call(sisaDetik);

    final Timer countdownTimer = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) {
      sisaDetik--;
      if (sisaDetik >= 0) {
        onCountdown?.call(sisaDetik);
      }
      if (sisaDetik <= 0) {
        timer.cancel();
      }
    });

    try {
      final Position posisi = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );

      await _simpanCacheManual(posisi);

      onStatus?.call(LocationFetchStatus.berhasil);
      return LocationResult(
        position: posisi,
        source: LocationSource.gpsLangsung,
      );
    } catch (_) {
      return _pakaiCadanganAtauGagal(onStatus, adaInternet: true);
    } finally {
      countdownTimer.cancel();
    }
  }

  Future<LocationResult?> _pakaiCadanganAtauGagal(
    void Function(LocationFetchStatus status)? onStatus, {
    required bool adaInternet,
  }) async {
    final LocationFetchStatus statusFallback = adaInternet
        ? LocationFetchStatus.memakaiLokasiTersimpanSinyalLemah
        : LocationFetchStatus.memakaiLokasiTersimpanTanpaInternet;

    onStatus?.call(statusFallback);

    Position? posisiTerakhir;
    try {
      posisiTerakhir = await Geolocator.getLastKnownPosition();
    } catch (_) {
      posisiTerakhir = null;
    }

    if (posisiTerakhir != null) {
      onStatus?.call(LocationFetchStatus.berhasil);
      return LocationResult(
        position: posisiTerakhir,
        source: adaInternet
            ? LocationSource.tersimpanSinyalLemah
            : LocationSource.tersimpanTanpaInternet,
      );
    }

    final _CachedLocation? cacheManual = await _bacaCacheManual();

    if (cacheManual != null) {
      onStatus?.call(LocationFetchStatus.berhasil);
      return LocationResult(
        position: cacheManual.toPosition(),
        source: LocationSource.cacheManual,
        savedAt: cacheManual.savedAt,
      );
    }

    onStatus?.call(LocationFetchStatus.gagalTanpaCadangan);
    return null;
  }

  Future<void> _simpanCacheManual(Position posisi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kCacheLatKey, posisi.latitude);
    await prefs.setDouble(_kCacheLngKey, posisi.longitude);
    await prefs.setString(_kCacheTimeKey, DateTime.now().toIso8601String());
  }

  Future<_CachedLocation?> _bacaCacheManual() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(_kCacheLatKey);
    final double? lng = prefs.getDouble(_kCacheLngKey);
    final String? waktuStr = prefs.getString(_kCacheTimeKey);

    if (lat == null || lng == null) return null;

    return _CachedLocation(
      latitude: lat,
      longitude: lng,
      savedAt: waktuStr != null ? DateTime.tryParse(waktuStr) : null,
    );
  }

  Future<bool> _cekInternet() async {
    final List<ConnectivityResult> hasil = await Connectivity()
        .checkConnectivity();

    return hasil.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}

class _CachedLocation {
  _CachedLocation({
    required this.latitude,
    required this.longitude,
    this.savedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime? savedAt;

  Position toPosition() => Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: savedAt ?? DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
