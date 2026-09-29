import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi "tampilkan notifikasi di status bar HP". Murni preferensi -
/// belum ada logic pengiriman notifikasi sungguhan (itu bagian J5, saat
/// flutter_local_notifications dipasang dan izin runtime diminta). Nilainya
/// disimpan mulai sekarang supaya J5 nanti tinggal membaca preferensi ini,
/// tidak perlu menyentuh halaman Pengaturan lagi.
class NotificationStatusBarController extends ValueNotifier<bool> {
  NotificationStatusBarController._() : super(false);

  static final NotificationStatusBarController instance =
      NotificationStatusBarController._();

  static const String _prefsKey = 'notification_statusbar_enabled';

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