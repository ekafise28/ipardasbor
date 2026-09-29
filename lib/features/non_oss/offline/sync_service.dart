import 'package:ipardasbor/features/notifications/models/notification_item.dart';
import 'package:ipardasbor/features/notifications/services/notification_service.dart';

import '../services/non_oss_service.dart';
import 'non_oss_local_data.dart';
import 'offline_database.dart';

class NonOssSyncService {
  NonOssSyncService({required this.remote, OfflineDatabase? database})
    : database = database ?? OfflineDatabase.instance;

  final NonOssService remote;
  final OfflineDatabase database;

  bool _running = false;

  /// Mengirim satu data lokal ke server.
  ///
  /// Method ini tidak melempar error ke UI.
  /// Jika server tidak tersedia atau pengiriman gagal,
  /// data tetap tersimpan di SQLite.
  Future<bool> syncOne(NonOssLocalData data) async {
    // Draft TIDAK BOLEH pernah diproses sync, apa pun jalur pemanggilnya
    // (baik dari SyncPage maupun SubmissionDetailPage). Draft belum tentu
    // lengkap/valid, dan kalau lolos ke sini lalu gagal, statusnya akan
    // berubah jadi FAILED - yang membuatnya salah masuk ke grup "Menunggu
    // Sinkronisasi" (lihat OfflineDatabase.getWaiting()).
    if (data.isDraft) {
      return false;
    }

    final String dedupeKey = 'sync_failed:${data.clientUuid}';

    try {
      final bool serverAvailable = await remote.isServerAvailable();

      // Server tidak tersedia BUKAN kegagalan - ini kondisi normal saat
      // offline, jadi TIDAK dibuatkan notifikasi (lihat diskusi: data
      // yang menumpuk karena offline ditangani oleh pengecekan agregat
      // "menunggu terlalu lama", bukan notifikasi per percobaan).
      if (!serverAvailable) {
        return false;
      }

      await database.markSyncing(data.clientUuid);

      final dynamic response = await remote.submitLocal(data);

      await database.markSynced(
        data.clientUuid,
        serverId: remote.serverIdFrom(response),
      );

      // Kalau sebelumnya sempat gagal dan bikin notifikasi, bersihkan -
      // sekarang sudah berhasil, notifikasi lama jadi tidak relevan.
      await NotificationService.instance.resolve(dedupeKey);

      return true;
    } catch (error) {
      final String pesan = _clean(error);

      try {
        await database.markFailed(data.clientUuid, pesan);
      } catch (_) {
        // Data utama sudah tersimpan di SQLite.
        // Kegagalan memperbarui status sinkronisasi
        // tidak boleh diteruskan ke halaman form.
      }

      // upsert() menimpa notifikasi gagal yang sama (bukan menumpuk) kalau
      // data ini gagal lagi di percobaan otomatis berikutnya.
      await NotificationService.instance.upsert(
        type: NotificationType.syncFailed,
        title: 'Gagal mengirim ${data.displayName}',
        body: pesan,
        dedupeKey: dedupeKey,
        targetType: 'submission_detail',
        targetId: data.clientUuid,
      );

      return false;
    }
  }

  /// Mengirim ulang data berstatus PENDING atau FAILED
  /// ketika server kembali tersedia.
  Future<void> syncWaiting({int limit = 20}) async {
    if (_running) {
      return;
    }

    _running = true;

    try {
      await database.restoreInterruptedSyncs();

      final bool serverAvailable = await remote.isServerAvailable();

      if (!serverAvailable) {
        return;
      }

      final List<NonOssLocalData> waiting = await database.getWaiting(
        limit: limit,
      );

      int berhasil = 0;
      for (final NonOssLocalData data in waiting) {
        if (await syncOne(data)) berhasil++;
      }

      // Notifikasi berhasil TIDAK memakai dedupeKey tetap - setiap putaran
      // sinkron yang membuahkan hasil layak diberi tahu sendiri-sendiri,
      // beda dengan notifikasi gagal yang memang harus saling menimpa.
      if (berhasil > 0) {
        await NotificationService.instance.upsert(
          type: NotificationType.syncSuccess,
          title: 'Sinkronisasi selesai',
          body: '$berhasil data berhasil dikirim ke server.',
          dedupeKey: 'sync_success:${DateTime.now().toIso8601String()}',
          targetType: 'sync_page',
        );
      }
    } finally {
      _running = false;
    }
  }

  String _clean(Object error) {
    final String value = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    if (value.length <= 1000) {
      return value;
    }

    return value.substring(0, 1000);
  }
}
