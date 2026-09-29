import 'package:ipardasbor/features/non_oss/offline/offline_database.dart';
import 'package:ipardasbor/notifications/services/notification_local_service.dart';
import 'package:ipardasbor/notifications/services/notification_statusbar_controller.dart';

import '../models/notification_item.dart';
import 'notification_service.dart';

/// Pengecekan agregat, dijalankan sekali tiap aplikasi dibuka (lihat
/// app.dart) - beda dari notifikasi gagal-sync yang dipicu langsung dari
/// NonOssSyncService saat kejadian itu sendiri terjadi.
class NotificationTriggers {
  NotificationTriggers._();

  static const Duration _waitingThreshold = Duration(hours: 24);
  static const Duration _draftThreshold = Duration(days: 3);

  static Future<void> run() async {
    await _checkWaitingTooLong();
    await _checkDraftLingering();
  }

  /// Kunci per hari - dipanggil berkali-kali sehari (tiap app dibuka) tapi
  /// cukup menghasilkan SATU notifikasi per hari (upsert menimpa yang lama),
  /// dan otomatis hilang dari inbox kalau sudah tidak ada lagi yang lama
  /// (lihat pemanggilan resolve() di bawah).
  static String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _checkWaitingTooLong() async {
    final List waiting = await OfflineDatabase.instance.getWaiting(limit: 500);
    final int lama = waiting
        .where((d) => DateTime.now().difference(d.createdAt) > _waitingThreshold)
        .length;

    final String key = 'waiting_too_long:${_todayKey()}';

    if (lama == 0) {
      await NotificationService.instance.resolve(key);
      await NotificationLocalService.instance.cancelWaitingTooLongReminder();
      return;
    }

    await NotificationService.instance.upsert(
      type: NotificationType.waitingTooLong,
      title: 'Data menunggu terkirim',
      body: '$lama data tersimpan di perangkat lebih dari 24 jam dan belum '
          'terkirim ke server. Buka halaman Sinkronisasi untuk memeriksa.',
      dedupeKey: key,
      targetType: 'sync_page',
    );

    if (NotificationStatusBarController.instance.value) {
      await NotificationLocalService.instance
          .scheduleWaitingTooLongReminder(count: lama, hour: 9);
    }
  }

  static Future<void> _checkDraftLingering() async {
    final List drafts = await OfflineDatabase.instance.getDrafts(limit: 200);
    final int lama = drafts
        .where((d) => DateTime.now().difference(d.updatedAt) > _draftThreshold)
        .length;

    final String key = 'draft_lingering:${_todayKey()}';

    if (lama == 0) {
      await NotificationService.instance.resolve(key);
      await NotificationLocalService.instance.cancelDraftLingeringReminder();
      return;
    }

    await NotificationService.instance.upsert(
      type: NotificationType.draftLingering,
      title: 'Draft belum diselesaikan',
      body: '$lama draft pengawasan sudah lebih dari 3 hari belum '
          'dilanjutkan. Buka halaman Sinkronisasi untuk melanjutkan.',
      dedupeKey: key,
      targetType: 'sync_page',
    );

    if (NotificationStatusBarController.instance.value) {
      await NotificationLocalService.instance
          .scheduleDraftLingeringReminder(count: lama, hour: 9);
    }
  }
}