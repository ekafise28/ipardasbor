import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mengelola preferensi mode sinkronisasi (manual vs otomatis) dan
/// menyimpannya secara lokal agar pilihan pengguna tetap tersimpan
/// setelah aplikasi ditutup.
///
/// Default-nya MANUAL (false) — sinkronisasi hanya terjadi saat user
/// menekan tombol "Sync Semua" / "Sync" di halaman Sinkronisasi.
/// Kalau diaktifkan, aplikasi akan mencoba sync otomatis saat dibuka
/// dan saat koneksi internet kembali tersedia (lihat AplikasiApp).
class AutoSyncController extends ValueNotifier<bool> {
  AutoSyncController._() : super(false);

  static final AutoSyncController instance = AutoSyncController._();

  static const String _prefsKey = 'auto_sync_enabled';

  bool get isEnabled => value;

  /// Dipanggil sekali saat aplikasi pertama kali dijalankan untuk memuat
  /// preferensi yang tersimpan.
  Future<void> loadSavedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    value = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}