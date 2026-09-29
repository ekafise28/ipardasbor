import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifikasi status bar sungguhan (bukan cuma inbox di dalam aplikasi).
/// Dua jenis pemakaian:
/// - [showNow]: notifikasi langsung, dipanggil dari NotificationService
///   saat sebuah kejadian terjadi (gagal sync, dsb) DAN aplikasi sedang
///   berjalan. Tidak berfungsi kalau aplikasi benar-benar tertutup.
/// - [scheduleDailyReminder]/[cancelReminder]: alarm sistem, tetap jalan
///   walau aplikasi tertutup, tapi isinya statis saat dijadwalkan - wajib
///   dijadwalkan ULANG setiap kali datanya berubah (lihat pemanggilnya di
///   NotificationTriggers).
class NotificationLocalService {
  NotificationLocalService._();
  static final NotificationLocalService instance = NotificationLocalService._();

  static const String _channelId = 'ipar_notifications';
  static const String _channelName = 'Notifikasi IPAR';

  // ID tetap untuk 2 jenis pengingat terjadwal - dipakai ulang saat
  // reschedule (bukan ID acak), supaya jadwal lama otomatis tertimpa.
  static const int _idWaitingTooLong = 9001;
  static const int _idDraftLingering = 9002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(settings: settings);

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Pemberitahuan sinkronisasi dan draft pengawasan',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  /// Minta izin runtime (Android 13+). Return true kalau diizinkan.
  /// Di bawah Android 13, selalu true (tidak perlu izin).
  Future<bool> requestPermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (e) {
      // Notifikasi status bar bersifat pelengkap - kegagalan di sini
      // tidak boleh mengganggu alur utama aplikasi.
      debugPrint('Gagal menampilkan notifikasi status bar: $e');
    }
  }

  Future<void> scheduleWaitingTooLongReminder({
    required int count,
    required int hour,
  }) => _scheduleDaily(
    id: _idWaitingTooLong,
    title: 'Data menunggu terkirim',
    body:
        '$count data belum terkirim lebih dari 24 jam. Buka Sinkronisasi untuk memeriksa.',
    hour: hour,
  );

  Future<void> scheduleDraftLingeringReminder({
    required int count,
    required int hour,
  }) => _scheduleDaily(
    id: _idDraftLingering,
    title: 'Draft belum diselesaikan',
    body: '$count draft belum dilanjutkan lebih dari 3 hari.',
    hour: hour,
  );

  Future<void> cancelWaitingTooLongReminder() =>
      _plugin.cancel(id: _idWaitingTooLong);
  Future<void> cancelDraftLingeringReminder() =>
      _plugin.cancel(id: _idDraftLingering);

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
  }) async {
    if (!_initialized) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan pengingat: $e');
    }
  }
}
