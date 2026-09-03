import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'non_oss_local_data.dart';
import 'sync_status.dart';

class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();
  static const String table = 'non_oss_sync_queue';
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final String root = await getDatabasesPath();
    return openDatabase(
      p.join(root, 'ipar_offline.db'),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_uuid TEXT NOT NULL UNIQUE,
            payload_json TEXT NOT NULL,
            photo_paths_json TEXT NOT NULL DEFAULT '[]',
            sync_status TEXT NOT NULL DEFAULT 'PENDING',
            server_id INTEGER NULL,
            last_error TEXT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_attempt_at TEXT NULL,
            synced_at TEXT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_non_oss_sync_status ON $table(sync_status)',
        );
      },
    );
  }

  Future<int> insert(NonOssLocalData data) async {
    final Database db = await database;
    return db.insert(
      table,
      data.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<NonOssLocalData>> getAll() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      orderBy: 'created_at DESC',
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  Future<NonOssLocalData?> getByClientUuid(String clientUuid) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: 'client_uuid = ?',
      whereArgs: <Object?>[clientUuid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return NonOssLocalData.fromDatabase(rows.first);
  }

  Future<List<NonOssLocalData>> getWaiting({int limit = 20}) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: 'sync_status IN (?, ?)',
      whereArgs: <Object?>[SyncStatus.pending.value, SyncStatus.failed.value],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  Future<void> markSyncing(String clientUuid) async {
    await _updateStatus(clientUuid, SyncStatus.syncing, <String, Object?>{
      'last_attempt_at': DateTime.now().toIso8601String(),
      'last_error': null,
    });
  }

  Future<void> markSynced(String clientUuid, {int? serverId}) async {
    final String now = DateTime.now().toIso8601String();
    await _updateStatus(clientUuid, SyncStatus.synced, <String, Object?>{
      'server_id': serverId,
      'synced_at': now,
      'last_error': null,
    });
  }

  Future<void> markFailed(String clientUuid, String error) async {
    final Database db = await database;
    await db.rawUpdate(
      '''UPDATE $table
         SET sync_status = ?, last_error = ?, retry_count = retry_count + 1,
             updated_at = ?
         WHERE client_uuid = ?''',
      <Object?>[
        SyncStatus.failed.value,
        error,
        DateTime.now().toIso8601String(),
        clientUuid,
      ],
    );
  }

  Future<void> restoreInterruptedSyncs() async {
    final Database db = await database;
    await db.update(
      table,
      <String, Object?>{
        'sync_status': SyncStatus.pending.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'sync_status = ?',
      whereArgs: <Object?>[SyncStatus.syncing.value],
    );
  }

  Future<int> deleteByClientUuid(String clientUuid) async {
    final Database db = await database;
    return db.delete(
      table,
      where: 'client_uuid = ?',
      whereArgs: <Object?>[clientUuid],
    );
  }

  Future<void> _updateStatus(
    String clientUuid,
    SyncStatus status,
    Map<String, Object?> additions,
  ) async {
    final Database db = await database;
    await db.update(
      table,
      <String, Object?>{
        'sync_status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
        ...additions,
      },
      where: 'client_uuid = ?',
      whereArgs: <Object?>[clientUuid],
    );
  }

  Future<void> updateSubmission(NonOssLocalData data) async {
    final Database db = await database;
    await db.update(
      table,
      data.toDatabase(),
      where: 'client_uuid = ?',
      whereArgs: <Object?>[data.clientUuid],
    );
  }
}
