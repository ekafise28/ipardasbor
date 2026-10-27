import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'non_oss_local_data.dart';
import 'sync_status.dart';

/// Antrean offline Non-OSS (tabel non_oss_sync_queue).
///
/// Setiap baris punya pemilik (`user_id`, dari akun yang sedang login).
/// Query baca/ubah/hapus dibatasi ke akun yang sedang login, jadi petugas B
/// tidak bisa melihat, mengedit, menghapus, atau ikut mengirim data petugas A
/// walaupun memakai HP yang sama. Tanpa akun login, query baca mengembalikan
/// kosong dan insert ditolak.
class NonOssQueueStore {
  NonOssQueueStore._();

  static final NonOssQueueStore instance = NonOssQueueStore._();

  static const String _table = AppDatabase.nonOssQueueTable;

  Future<Database> get _db => AppDatabase.instance.database;

  /// Menyerahkan baris tanpa pemilik (sisa sebelum skema v2) ke akun yang
  /// sedang login. Panggil sekali setelah login berhasil.
  Future<void> claimUnownedRows() async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return;

    final Database db = await _db;
    await db.update(_table, <String, Object?>{
      'user_id': uid,
    }, where: 'user_id IS NULL');
  }

  Future<int> insert(NonOssLocalData data) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) {
      throw Exception(
        'Sesi login berakhir. Masuk kembali untuk menyimpan data.',
      );
    }

    final Database db = await _db;
    return db.insert(_table, <String, Object?>{
      ...data.toDatabase(),
      'user_id': uid,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<NonOssLocalData>> getAll() async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return const <NonOssLocalData>[];

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: <Object?>[uid],
      orderBy: 'created_at DESC',
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  Future<NonOssLocalData?> getByClientUuid(String clientUuid) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return null;

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[clientUuid, uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NonOssLocalData.fromDatabase(rows.first);
  }

  Future<List<NonOssLocalData>> getWaiting({int limit = 20}) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return const <NonOssLocalData>[];

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'user_id = ? AND sync_status IN (?, ?)',
      whereArgs: <Object?>[
        uid,
        SyncStatus.pending.value,
        SyncStatus.failed.value,
      ],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  /// Draft SENGAJA dipisah dari getWaiting() - draft tidak boleh pernah ikut
  /// ke-fetch untuk proses sync otomatis, karena isinya belum tentu
  /// valid/lengkap.
  Future<List<NonOssLocalData>> getDrafts({int limit = 100}) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return const <NonOssLocalData>[];

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      _table,
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: <Object?>[uid, SyncStatus.draft.value],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  /// Klaim atomik: hanya berhasil kalau baris masih PENDING/FAILED.
  /// Return false kalau sudah diklaim proses lain (SYNCING), sudah SYNCED,
  /// atau berstatus DRAFT. Pemanggil harus berhenti kalau false.
  Future<bool> markSyncing(String clientUuid) async {
    final Database db = await _db;
    final String now = DateTime.now().toIso8601String();

    final int diubah = await db.update(
      _table,
      <String, Object?>{
        'sync_status': SyncStatus.syncing.value,
        'updated_at': now,
        'last_attempt_at': now,
        'last_error': null,
      },
      where: 'client_uuid = ? AND sync_status IN (?, ?)',
      whereArgs: <Object?>[
        clientUuid,
        SyncStatus.pending.value,
        SyncStatus.failed.value,
      ],
    );

    return diubah == 1;
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
    final Database db = await _db;
    await db.rawUpdate(
      '''UPDATE $_table
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

  /// Mengembalikan status SYNCING yang macet ke PENDING. Hanya baris yang
  /// percobaannya sudah lebih tua dari [staleAfter], supaya proses kirim yang
  /// masih berjalan tidak ikut di-reset. Saat aplikasi baru dibuka, pakai
  /// Duration.zero karena belum ada proses kirim yang berjalan.
  Future<void> restoreInterruptedSyncs({
    Duration staleAfter = const Duration(minutes: 5),
  }) async {
    final Database db = await _db;
    final String batas = DateTime.now().subtract(staleAfter).toIso8601String();

    await db.update(
      _table,
      <String, Object?>{
        'sync_status': SyncStatus.pending.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where:
          'sync_status = ? AND (last_attempt_at IS NULL OR last_attempt_at <= ?)',
      whereArgs: <Object?>[SyncStatus.syncing.value, batas],
    );
  }

  /// Mengembalikan jumlah baris yang terhapus. 0 berarti baris tidak ada atau
  /// bukan milik akun yang sedang login.
  Future<int> deleteByClientUuid(String clientUuid) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return 0;

    final Database db = await _db;
    return db.delete(
      _table,
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[clientUuid, uid],
    );
  }

  Future<void> updateSubmission(NonOssLocalData data) async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return;

    final Database db = await _db;
    await db.update(
      _table,
      data.toDatabase(),
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[data.clientUuid, uid],
    );
  }

  /// Waktu sinkronisasi terakhir yang berhasil untuk akun yang sedang login
  /// (kolom synced_at). Null kalau belum pernah ada.
  Future<DateTime?> lastSyncedAt() async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return null;

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT MAX(synced_at) AS terakhir FROM $_table '
      'WHERE user_id = ? AND sync_status = ?',
      <Object?>[uid, SyncStatus.synced.value],
    );

    if (rows.isEmpty) return null;
    final Object? raw = rows.first['terakhir'];
    return raw == null ? null : DateTime.tryParse(raw.toString());
  }

  /// Seluruh ajuan akun ini yang tersimpan lokal dan BELUM synced: draft,
  /// pending, failed, dan syncing. Dipakai untuk badge di Home (beda dengan
  /// [getWaiting] yang hanya yang siap sync).
  Future<int> countUnsynced() async {
    final String? uid = await AppDatabase.currentUserId();
    if (uid == null) return 0;

    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table '
      'WHERE user_id = ? AND sync_status != ?',
      <Object?>[uid, SyncStatus.synced.value],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> _updateStatus(
    String clientUuid,
    SyncStatus status,
    Map<String, Object?> additions,
  ) async {
    final Database db = await _db;
    await db.update(
      _table,
      <String, Object?>{
        'sync_status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
        ...additions,
      },
      where: 'client_uuid = ?',
      whereArgs: <Object?>[clientUuid],
    );
  }
}