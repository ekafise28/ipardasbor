import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../storage/secure_storage.dart';

/// Pembuka database SQLite aplikasi (satu file: ipar_offline.db) dan satu-satunya
/// tempat skema dibuat/dimigrasi. Query bisnis TIDAK ada di sini; tiap fitur
/// punya store sendiri yang memakai [database]:
/// - antrean Non-OSS      -> NonOssQueueStore
/// - notifikasi           -> NotificationService
/// - cache respons API    -> ApiCache
///
/// Riwayat versi skema:
/// 1: antrean Non-OSS
/// 2: kolom user_id pada antrean (pemilik data per akun)
/// 3: tabel notifications
/// 4: tabel api_cache
/// 5: (dibatalkan) tabel Data Proyek offline
/// 6: tabel proyek_offline_* dibuang
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// Nama file jangan diubah supaya data pengguna yang sudah ada tidak hilang.
  static const String _fileName = 'ipar_offline.db';
  static const int _schemaVersion = 6;

  static const String nonOssQueueTable = 'non_oss_sync_queue';
  static const String notificationsTable = 'notifications';
  static const String apiCacheTable = 'api_cache';

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  /// ID akun yang sedang login, atau null kalau tidak ada sesi. Dibaca ulang
  /// setiap kali (tidak di-cache) supaya tidak basi saat pindah akun.
  static Future<String?> currentUserId() async {
    final String? id = await SecureStorage.getUserId();
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  Future<Database> _open() async {
    final String root = await getDatabasesPath();
    return openDatabase(
      p.join(root, _fileName),
      version: _schemaVersion,
      onCreate: (Database db, int version) async {
        await _createNonOssQueueTable(db);
        await _createNotificationsTable(db);
        await _createApiCacheTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $nonOssQueueTable ADD COLUMN user_id TEXT NULL',
          );
          await db.execute(
            'CREATE INDEX idx_non_oss_user_id ON $nonOssQueueTable(user_id)',
          );

          // Data lama belum punya pemilik. Serahkan ke akun yang sedang
          // login saat aplikasi diperbarui. Kalau tidak ada yang login,
          // dibiarkan NULL dan diklaim akun pertama yang login
          // (NonOssQueueStore.claimUnownedRows).
          final String? uid = await currentUserId();
          if (uid != null) {
            await db.update(nonOssQueueTable, <String, Object?>{
              'user_id': uid,
            }, where: 'user_id IS NULL');
          }
        }
        if (oldVersion < 3) {
          await _createNotificationsTable(db);
        }
        if (oldVersion < 4) {
          await _createApiCacheTable(db);
        }
        if (oldVersion < 6) {
          // Sisa fitur unduh manual Data Proyek (hanya ada di perangkat
          // yang sempat memakai build v5).
          await db.execute('DROP TABLE IF EXISTS proyek_offline_chunk');
          await db.execute('DROP TABLE IF EXISTS proyek_offline_meta');
        }
      },
    );
  }

  Future<void> _createNonOssQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE $nonOssQueueTable (
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
      'CREATE INDEX idx_non_oss_sync_status ON $nonOssQueueTable(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_non_oss_user_id ON $nonOssQueueTable(user_id)',
    );
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $notificationsTable (
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
      'CREATE UNIQUE INDEX idx_notif_user_dedupe ON $notificationsTable(user_id, dedupe_key)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_user_read ON $notificationsTable(user_id, is_read)',
    );
  }

  Future<void> _createApiCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE $apiCacheTable (
        user_id TEXT NOT NULL,
        cache_key TEXT NOT NULL,
        data BLOB NOT NULL,
        size_bytes INTEGER NOT NULL,
        saved_at TEXT NOT NULL,
        last_access TEXT NOT NULL,
        PRIMARY KEY (user_id, cache_key)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_api_cache_access ON $apiCacheTable(user_id, last_access)',
    );
  }
}
