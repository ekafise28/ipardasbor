import 'package:uuid/uuid.dart';

import '../models/non_oss_form_data.dart';
import '../models/non_oss_form_data.dart';

import 'non_oss_local_data.dart';
import 'offline_database.dart';
import 'permanent_photo_storage.dart';
import 'sync_status.dart';

class OfflineQueueService {
  OfflineQueueService({
    OfflineDatabase? database,
    PermanentPhotoStorage? photoStorage,
    Uuid? uuid,
  }) : _database = database ?? OfflineDatabase.instance,
       _photoStorage = photoStorage ?? PermanentPhotoStorage(),
       _uuid = uuid ?? const Uuid();

  final OfflineDatabase _database;
  final PermanentPhotoStorage _photoStorage;
  final Uuid _uuid;

  Future<void> delete(NonOssLocalData data) async {
    await _database.deleteByClientUuid(data.clientUuid);
    await _photoStorage.removeFor(data.clientUuid);
  }

  /// Draft tidak wajib lolos validasi field, tapi tetap tidak boleh
  /// benar-benar kosong (minimal satu isian atau satu foto).
  bool hasAnyContent(NonOssFormData form) {
    final bool adaFieldTerisi = form.toFields().values.any(
      (String v) => v.trim().isNotEmpty,
    );
    return adaFieldTerisi || form.photos.isNotEmpty;
  }

  Future<NonOssLocalData> saveDraft(NonOssFormData form) async {
    if (!hasAnyContent(form)) {
      throw Exception('Isi minimal satu data sebelum menyimpan sebagai draft.');
    }

    final String clientUuid = _uuid.v4();
    final List<String> photoPaths = await _photoStorage.persistAll(
      clientUuid,
      form.photos,
    );
    final DateTime now = DateTime.now();

    final NonOssLocalData localData = NonOssLocalData(
      clientUuid: clientUuid,
      payload: <String, String>{...form.toFields(), 'client_uuid': clientUuid},
      photoPaths: photoPaths,
      status: SyncStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final int id = await _database.insert(localData);
      return NonOssLocalData(
        id: id,
        clientUuid: localData.clientUuid,
        payload: localData.payload,
        photoPaths: localData.photoPaths,
        status: localData.status,
        createdAt: localData.createdAt,
        updatedAt: localData.updatedAt,
      );
    } catch (_) {
      await _photoStorage.removeFor(clientUuid);
      rethrow;
    }
  }

  /// Meng-update entri yang sudah ada (baik draft lama, atau ajuan
  /// PENDING/FAILED yang sedang diedit) menjadi draft.
  Future<NonOssLocalData> updateDraft(
    NonOssLocalData original,
    NonOssFormData form,
  ) async {
    if (!hasAnyContent(form)) {
      throw Exception('Isi minimal satu data sebelum menyimpan sebagai draft.');
    }

    final List<String> photoPaths = await _photoStorage.replaceAll(
      original.clientUuid,
      form.photos,
    );
    final DateTime now = DateTime.now();

    final NonOssLocalData updated = NonOssLocalData(
      id: original.id,
      clientUuid: original.clientUuid,
      payload: <String, String>{
        ...form.toFields(),
        'client_uuid': original.clientUuid,
      },
      photoPaths: photoPaths,
      status: SyncStatus.draft,
      createdAt: original.createdAt,
      updatedAt: now,
      serverId: original.serverId,
      lastError: null,
      lastAttemptAt: original.lastAttemptAt,
      syncedAt: original.syncedAt,
      retryCount: original.retryCount,
    );

    await _database.updateSubmission(updated);
    return updated;
  }

  Future<NonOssLocalData> save(NonOssFormData form) async {
    final String clientUuid = _uuid.v4();
    final List<String> photoPaths = await _photoStorage.persistAll(
      clientUuid,
      form.photos,
    );
    final DateTime now = DateTime.now();

    final NonOssLocalData localData = NonOssLocalData(
      clientUuid: clientUuid,
      payload: <String, String>{...form.toFields(), 'client_uuid': clientUuid},
      photoPaths: photoPaths,
      status: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final int id = await _database.insert(localData);
      return NonOssLocalData(
        id: id,
        clientUuid: localData.clientUuid,
        payload: localData.payload,
        photoPaths: localData.photoPaths,
        status: localData.status,
        createdAt: localData.createdAt,
        updatedAt: localData.updatedAt,
      );
    } catch (_) {
      await _photoStorage.removeFor(clientUuid);
      rethrow;
    }
  }

  /// Memperbarui ajuan yang sudah ada di antrean lokal (mode edit).
  ///
  /// Status SENGAJA di-reset ke [SyncStatus.pending] supaya ajuan yang
  /// tadinya gagal (FAILED) bisa dicoba sync lagi setelah dikoreksi.
  /// id, clientUuid, createdAt, dan retryCount tetap dipertahankan dari
  /// data [original] — ini bukan ajuan baru, cuma versi terbaru dari
  /// ajuan yang sama.
  Future<NonOssLocalData> update(
    NonOssLocalData original,
    NonOssFormData form,
  ) async {
    final List<String> photoPaths = await _photoStorage.replaceAll(
      original.clientUuid,
      form.photos,
    );
    final DateTime now = DateTime.now();

    final NonOssLocalData updated = NonOssLocalData(
      id: original.id,
      clientUuid: original.clientUuid,
      payload: <String, String>{
        ...form.toFields(),
        'client_uuid': original.clientUuid,
      },
      photoPaths: photoPaths,
      status: SyncStatus.pending,
      createdAt: original.createdAt,
      updatedAt: now,
      serverId: original.serverId,
      lastError: null,
      lastAttemptAt: original.lastAttemptAt,
      syncedAt: original.syncedAt,
      retryCount: original.retryCount,
    );

    await _database.updateSubmission(updated);
    return updated;
  }
}
