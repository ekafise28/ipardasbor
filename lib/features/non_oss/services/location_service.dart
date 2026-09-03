import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_fetch_status.dart';

/// Hasil pengambilan lokasi, membawa posisi SEKALIGUS sumbernya, supaya
/// UI bisa tetap menampilkan keterangan sumber setelah proses selesai.
class LocationResult {
  const LocationResult({required this.position, required this.source});

  final Position position;
  final LocationSource source;
}

class LocationService {
  Future<LocationResult> current({
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

    final bool layananAktif = await Geolocator.isLocationServiceEnabled();

    if (!layananAktif) {
      return _pakaiCadanganAtauGagal(onStatus);
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

      onStatus?.call(LocationFetchStatus.berhasil);
      return LocationResult(
        position: posisi,
        source: LocationSource.gpsLangsung,
      );
    } catch (_) {
      return _pakaiCadanganAtauGagal(onStatus);
    } finally {
      countdownTimer.cancel();
    }
  }

  Future<LocationResult> _pakaiCadanganAtauGagal(
    void Function(LocationFetchStatus status)? onStatus,
  ) async {
    final bool adaInternet = await _cekInternet();

    final LocationFetchStatus statusFallback = adaInternet
        ? LocationFetchStatus.memakaiLokasiTersimpanSinyalLemah
        : LocationFetchStatus.memakaiLokasiTersimpanTanpaInternet;

    onStatus?.call(statusFallback);

    final Position? posisiTerakhir = await Geolocator.getLastKnownPosition();

    if (posisiTerakhir != null) {
      onStatus?.call(LocationFetchStatus.berhasil);
      return LocationResult(
        position: posisiTerakhir,
        source: adaInternet
            ? LocationSource.tersimpanSinyalLemah
            : LocationSource.tersimpanTanpaInternet,
      );
    }

    onStatus?.call(LocationFetchStatus.gagalTanpaCadangan);
    throw Exception(
      'GPS tidak tersedia dan belum ada koordinat tersimpan sebelumnya.',
    );
  }

  Future<bool> _cekInternet() async {
    final List<ConnectivityResult> hasil = await Connectivity()
        .checkConnectivity();

    return hasil.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}