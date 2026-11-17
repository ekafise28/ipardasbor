import 'package:ipardasbor/shared/utils/pref_notifier.dart';

/// Mengelola preferensi mode sinkronisasi (manual vs otomatis) dan
/// menyimpannya secara lokal agar pilihan pengguna tetap tersimpan
/// setelah aplikasi ditutup.
///
/// Default-nya MANUAL (false) - sinkronisasi hanya terjadi saat user
/// menekan tombol "Sync Semua" / "Sync" di halaman Sinkronisasi.
/// Kalau diaktifkan, aplikasi akan mencoba sync otomatis saat dibuka
/// dan saat koneksi internet kembali tersedia (lihat AplikasiApp).
class AutoSyncController extends BoolPref {
  AutoSyncController._();
  static final AutoSyncController instance = AutoSyncController._();

  @override
  String get prefsKey => 'auto_sync_enabled';
}