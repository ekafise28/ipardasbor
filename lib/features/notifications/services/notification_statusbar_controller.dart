import 'package:ipardasbor/shared/utils/pref_notifier.dart';

/// Preferensi "tampilkan notifikasi di status bar HP". Murni preferensi -
/// belum ada logic pengiriman notifikasi sungguhan (itu bagian J5, saat
/// flutter_local_notifications dipasang dan izin runtime diminta). Nilainya
/// disimpan mulai sekarang supaya J5 nanti tinggal membaca preferensi ini,
/// tidak perlu menyentuh halaman Pengaturan lagi.
class NotificationStatusBarController extends BoolPref {
  NotificationStatusBarController._();
  static final NotificationStatusBarController instance =
      NotificationStatusBarController._();

  @override
  String get prefsKey => 'notification_statusbar_enabled';
}