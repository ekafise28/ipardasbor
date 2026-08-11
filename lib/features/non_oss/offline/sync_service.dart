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
    try {
      final bool serverAvailable = await remote.isServerAvailable();

      if (!serverAvailable) {
        return false;
      }

      await database.markSyncing(data.clientUuid);

      final dynamic response = await remote.submitLocal(data);

      await database.markSynced(
        data.clientUuid,
        serverId: remote.serverIdFrom(response),
      );

      return true;
    } catch (error) {
      try {
        await database.markFailed(data.clientUuid, _clean(error));
      } catch (_) {
        // Data utama sudah tersimpan di SQLite.
        // Kegagalan memperbarui status sinkronisasi
        // tidak boleh diteruskan ke halaman form.
      }

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

      for (final NonOssLocalData data in waiting) {
        await syncOne(data);
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
