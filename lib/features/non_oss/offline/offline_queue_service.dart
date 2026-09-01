import 'package:uuid/uuid.dart';

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
}
