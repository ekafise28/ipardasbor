import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/secure_storage.dart';
import 'non_oss_local_data.dart';
import 'sync_status.dart';

/// Antrean offline Non-OSS.
///
/// Sejak skema versi 2, setiap baris punya pemilik (`user_id`, diambil dari
/// akun yang sedang login di SecureStorage). Semua query baca/ubah/hapus
/// otomatis dibatasi ke akun yang sedang login, jadi petugas B tidak bisa
/// melihat, mengedit, menghapus, atau ikut mengirim data milik petugas A
/// walaupun memakai HP yang sama.
///
/// Kalau tidak ada akun yang login, semua query baca mengembalikan kosong
/// dan insert ditolak.
class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();
  static const String table = 'non_oss_sync_queue';
  static const int _schemaVersion = 3;
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  /// ID akun yang sedang login, atau null kalau tidak ada sesi.
  /// Dibaca ulang setiap kali (tidak di-cache) supaya tidak basi saat
  /// pindah akun.
  Future<String?> _currentUserId() async {
    final String? id = await SecureStorage.getUserId();
    if (id == null || id.trim().isEmpty) {
      return null;
    }
    return id.trim();
  }

  Future<Database> _open() async {
    final String root = await getDatabasesPath();
    return openDatabase(
      p.join(root, 'ipar_offline.db'),
      version: _schemaVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_uuid TEXT NOT NULL UNIQUE,
            user_id TEXT NULL,
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
        await db.execute(
          'CREATE INDEX idx_non_oss_user_id ON $table(user_id)',
        );
        await _createNotificationsTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $table ADD COLUMN user_id TEXT NULL');
          await db.execute(
            'CREATE INDEX idx_non_oss_user_id ON $table(user_id)',
          );

          // Data lama belum punya pemilik. Serahkan ke akun yang sedang
          // login saat aplikasi diperbarui (hampir pasti pemiliknya).
          // Kalau tidak ada yang login, dibiarkan NULL dan akan diklaim
          // akun pertama yang login (lihat claimUnownedRows).
          final String? uid = await _currentUserId();
          if (uid != null) {
            await db.update(
              table,
              <String, Object?>{'user_id': uid},
              where: 'user_id IS NULL',
            );
          }
        }

        if (oldVersion < 3) {
          await _createNotificationsTable(db);
        }
      },
    );
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        dedupe_key TEXT NOT NULL,
        target_type TEXT NULL,
        target_id TEXT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_notif_user_dedupe ON notifications(user_id, dedupe_key)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_user_read ON notifications(user_id, is_read)',
    );
  }

  /// Menyerahkan baris tanpa pemilik (sisa sebelum skema v2) ke akun yang
  /// sedang login. Panggil sekali setelah login berhasil.
  Future<void> claimUnownedRows() async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return;
    }

    final Database db = await database;
    await db.update(
      table,
      <String, Object?>{'user_id': uid},
      where: 'user_id IS NULL',
    );
  }

  Future<int> insert(NonOssLocalData data) async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      throw Exception('Sesi login berakhir. Masuk kembali untuk menyimpan data.');
    }

    final Database db = await database;
    return db.insert(
      table,
      <String, Object?>{...data.toDatabase(), 'user_id': uid},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<NonOssLocalData>> getAll() async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return const <NonOssLocalData>[];
    }

    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: 'user_id = ?',
      whereArgs: <Object?>[uid],
      orderBy: 'created_at DESC',
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  Future<NonOssLocalData?> getByClientUuid(String clientUuid) async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return null;
    }

    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[clientUuid, uid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return NonOssLocalData.fromDatabase(rows.first);
  }

  Future<List<NonOssLocalData>> getWaiting({int limit = 20}) async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return const <NonOssLocalData>[];
    }

    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
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

  /// Draft SENGAJA dipisah dari getWaiting() - draft tidak boleh pernah
  /// ikut ke-fetch untuk proses sync otomatis, karena isinya belum tentu
  /// valid/lengkap.
  Future<List<NonOssLocalData>> getDrafts({int limit = 100}) async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return const <NonOssLocalData>[];
    }

    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: <Object?>[uid, SyncStatus.draft.value],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(NonOssLocalData.fromDatabase).toList(growable: false);
  }

  // markSyncing / markSynced / markFailed SENGAJA hanya memakai client_uuid,
  // tanpa filter pemilik: baris yang dimaksud sudah diambil lewat query di
  // atas (yang terbatas ke akun aktif). Kalau sesi berganti di tengah
  // proses kirim, status tetap harus tercatat supaya data tidak terkirim
  // dua kali.
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

  /// Global untuk semua akun: hanya mengembalikan status SYNCING (proses
  /// yang terputus) ke PENDING, tidak membuka data siapa pun.
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

  /// Mengembalikan jumlah baris yang terhapus. 0 berarti baris tidak ada
  /// atau bukan milik akun yang sedang login.
  Future<int> deleteByClientUuid(String clientUuid) async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return 0;
    }

    final Database db = await database;
    return db.delete(
      table,
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[clientUuid, uid],
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
    final String? uid = await _currentUserId();
    if (uid == null) {
      return;
    }

    final Database db = await database;
    await db.update(
      table,
      data.toDatabase(),
      where: 'client_uuid = ? AND user_id = ?',
      whereArgs: <Object?>[data.clientUuid, uid],
    );
  }

  /// Menghitung seluruh ajuan milik akun yang sedang login yang tersimpan
  /// lokal dan BELUM synced - mencakup draft, pending, failed, dan syncing
  /// (kalau sedang berjalan). Dipakai untuk badge jumlah di ikon status
  /// Home: total data tersimpan offline, bukan cuma yang siap sync (beda
  /// dengan getWaiting()).
  Future<int> countUnsynced() async {
    final String? uid = await _currentUserId();
    if (uid == null) {
      return 0;
    }

    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $table '
      'WHERE user_id = ? AND sync_status != ?',
      <Object?>[uid, SyncStatus.synced.value],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}