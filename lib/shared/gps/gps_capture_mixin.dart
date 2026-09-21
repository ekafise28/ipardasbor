import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/non_oss/models/location_fetch_status.dart';
import 'package:ipardasbor/features/non_oss/services/location_service.dart';

/// Mixin berbagi untuk alur pengambilan lokasi GPS di form lapangan
/// (dipakai oleh Non-OSS dan OSS).
///
/// Menyediakan:
/// - state GPS (`gpsLoading`, `gpsStatus`, `gpsCountdown`, `gpsSource`,
///   `gpsSavedAt`) yang langsung cocok dipakai oleh widget `LocationPicker`.
/// - alur lengkap: cek layanan lokasi aktif -> tawarkan aktifkan lewat
///   Settings -> tunggu app resume -> coba GPS -> fallback ke koordinat
///   cadangan dengan konfirmasi.
///
/// Pemakaian di halaman form:
/// ```dart
/// class _MyFormPageState extends State<MyFormPage>
///     with WidgetsBindingObserver, GpsCaptureMixin<MyFormPage> {
///   @override
///   void initState() {
///     super.initState();
///     initGpsCapture();
///   }
///
///   @override
///   void dispose() {
///     disposeGpsCapture();
///     super.dispose();
///   }
///
///   Future<void> _gps() => ambilLokasiGps(
///     onBerhasil: (hasil) => setState(() {
///       _data.latitude = hasil.position.latitude.toStringAsFixed(8);
///       _data.longitude = hasil.position.longitude.toStringAsFixed(8);
///     }),
///   );
/// }
/// ```
mixin GpsCaptureMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  static const _primary = AppTheme.primaryColor;

  final LocationService _gpsLocation = LocationService();

  bool gpsLoading = false;
  LocationFetchStatus? gpsStatus;
  int? gpsCountdown;
  LocationSource? gpsSource;
  DateTime? gpsSavedAt;

  /*
  Dipakai untuk menunggu app benar-benar kembali ke foreground (resumed)
  setelah user pergi ke halaman Settings lokasi. `openLocationSettings()`
  hanya melempar Intent dan langsung return, TIDAK menunggu user kembali,
  jadi tanpa ini pengecekan `isLocationServiceEnabled()` akan dijalankan
  terlalu dini (masih membaca status lama).
  */
  Completer<void>? _resumeCompleter;

  /// Panggil di `initState()` halaman pemakai.
  void initGpsCapture() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Panggil di `dispose()` halaman pemakai (sebelum `super.dispose()`).
  void disposeGpsCapture() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeCompleter?.complete();
      _resumeCompleter = null;
    }
  }

  Future<void> _tungguAppResume({
    Duration timeout = const Duration(seconds: 30),
  }) {
    final Completer<void> completer = Completer<void>();
    _resumeCompleter = completer;

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        if (_resumeCompleter == completer) {
          _resumeCompleter = null;
        }
      },
    );
  }

  /// Alur utama pengambilan lokasi.
  ///
  /// Memanggil [onBerhasil] dengan koordinat hasil (baik dari GPS langsung
  /// maupun cadangan) kalau berhasil. Kalau gagal total, memanggil
  /// [onError]; kalau tidak diberikan, dipakai penanganan default berupa
  /// SnackBar merah.
  Future<void> ambilLokasiGps({
    required void Function(LocationResult hasil) onBerhasil,
    void Function(Object error)? onError,
  }) async {
    if (!mounted) return;

    bool layananAktif = await _gpsLocation.isLocationServiceEnabled();
    if (!mounted) return;

    if (!layananAktif) {
      final bool? aktifkan = await _tanyaAktifkanLokasi();
      if (!mounted) return;

      if (aktifkan == true) {
        await _gpsLocation.openLocationSettings();
        if (!mounted) return;

        // Menunggu user BENAR-BENAR kembali ke app dari halaman Settings,
        // bukan langsung cek status setelah openLocationSettings() return
        // (Future itu selesai duluan sebelum user sempat apa-apa).
        await _tungguAppResume();
        if (!mounted) return;

        layananAktif = await _gpsLocation.isLocationServiceEnabled();
        if (!mounted) return;
      }

      if (!layananAktif) {
        await _pakaiCadanganDenganKonfirmasi(
          onBerhasil: onBerhasil,
          onError: onError,
        );
        return;
      }

      // Kalau layananAktif berubah jadi true, lanjut ke proses normal
      // di bawah seperti biasa.
    }

    setState(() {
      gpsLoading = true;
      gpsStatus = null;
      gpsCountdown = null;
    });

    try {
      final LocationResult? hasil = await _gpsLocation.current(
        onStatus: (LocationFetchStatus status) {
          if (!mounted) return;
          setState(() => gpsStatus = status);
        },
        onCountdown: (int sisaDetik) {
          if (!mounted) return;
          setState(() => gpsCountdown = sisaDetik);
        },
      );

      if (!mounted) return;

      if (hasil == null) {
        (onError ?? _defaultError)(
          Exception(
            'GPS tidak tersedia dan belum ada koordinat tersimpan sebelumnya.',
          ),
        );
        return;
      }

      setState(() {
        gpsSource = hasil.source;
        gpsSavedAt = hasil.savedAt;
      });
      onBerhasil(hasil);
    } catch (e) {
      if (mounted) (onError ?? _defaultError)(e);
    } finally {
      if (mounted) setState(() => gpsLoading = false);
    }
  }

  /// Dipanggil hanya ketika layanan lokasi diketahui nonaktif (baik user
  /// pilih "Batal" di dialog aktivasi, maupun sudah ke Settings tapi masih
  /// nonaktif). Mengecek dulu apakah ada cadangan SEBELUM menampilkan
  /// konfirmasi pemakaiannya - supaya tidak menanyakan sesuatu yang
  /// cadangannya sendiri kosong.
  Future<void> _pakaiCadanganDenganKonfirmasi({
    required void Function(LocationResult hasil) onBerhasil,
    void Function(Object error)? onError,
  }) async {
    final LocationResult? cadangan = await _gpsLocation.peekCadangan();
    if (!mounted) return;

    if (cadangan == null) {
      (onError ?? _defaultError)(
        Exception(
          'GPS tidak tersedia dan belum ada koordinat tersimpan sebelumnya.',
        ),
      );
      return;
    }

    final bool? gunakan = await _tanyaGunakanCadangan(cadangan.savedAt);
    if (!mounted) return;

    if (gunakan != true) {
      // Batal: sesuai kesepakatan, tidak ada pesan apa pun.
      return;
    }

    setState(() {
      gpsSource = cadangan.source;
      gpsSavedAt = cadangan.savedAt;
    });
    onBerhasil(cadangan);
  }

  void _defaultError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool?> _tanyaAktifkanLokasi() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.location_off_rounded,
          color: Color(0xFFD97706),
          size: 48,
        ),
        title: const Text(
          'Aktifkan Lokasi?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Layanan lokasi (GPS) di perangkat ini sedang nonaktif. '
          'Aktifkan untuk mendapatkan koordinat yang akurat.',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Aktifkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _tanyaGunakanCadangan(DateTime? savedAt) {
    final String waktu = savedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(savedAt)
        : 'waktu tidak diketahui';

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.history_rounded,
          color: Color(0xFFD97706),
          size: 48,
        ),
        title: const Text(
          'Gunakan Koordinat Cadangan?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Lokasi GPS tidak aktif. Gunakan koordinat tersimpan terakhir '
          'pada $waktu? Koordinat ini bukan posisi Anda saat ini.',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Gunakan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}