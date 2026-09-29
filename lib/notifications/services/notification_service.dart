import 'package:ipardasbor/features/non_oss/offline/offline_database.dart';
import 'package:ipardasbor/notifications/services/notification_category_preferences.dart';
import 'package:ipardasbor/notifications/services/notification_local_service.dart';
import 'package:ipardasbor/notifications/services/notification_statusbar_controller.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/secure_storage.dart';
import '../models/notification_item.dart';

/// Semua akses baca/tulis notifikasi dibatasi ke akun yang sedang login,
/// pola sama persis dengan OfflineDatabase (lihat K1) - tanpa sesi login,
/// baca mengembalikan kosong dan tulis diabaikan diam-diam.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String table = 'notifications';

  Future<String?> _currentUserId() async {
    final String? id = await SecureStorage.getUserId();
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  /// Membuat notifikasi baru, atau MENIMPA yang lama kalau [dedupeKey]
  /// sudah pernah dipakai (lewat UNIQUE INDEX di tabel) - waktu dan status
  /// baca ikut ter-reset ke belum dibaca. Ini yang mencegah retry sinkron
  /// berulang membuat notifikasi gagal-sync menumpuk jadi puluhan.
  Future<void> upsert({
    required NotificationType type,
    required String title,
    required String body,
    required String dedupeKey,
    String? targetType,
    String? targetId,
  }) async {
    if (!NotificationCategoryPreferences.instance.isEnabled(type)) {
      return;
    }

    final String? uid = await _currentUserId();
    if (uid == null) return;

    final Database db = await OfflineDatabase.instance.database;
    final NotificationItem item = NotificationItem(
      type: type,
      title: title,
      body: body,
      dedupeKey: dedupeKey,
      targetType: targetType,
      targetId: targetId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await db.insert(
      table,
      item.toDatabase(uid),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final bool statusBarAktif = NotificationStatusBarController.instance.value;
    final bool kejadianSeketika =
        type == NotificationType.syncFailed || type == NotificationType.syncSuccess;

    if (statusBarAktif && kejadianSeketika) {
      await NotificationLocalService.instance.showNow(
        id: dedupeKey.hashCode & 0x7fffffff,
        title: title,
        body: body,
      );
    }
  }

  /// Dipanggil saat kejadian yang memicu notifikasi sudah tidak relevan
  /// lagi (mis. data yang tadinya gagal akhirnya berhasil terkirim) -
  /// membuang notifikasi terkait supaya tidak nyangkut di inbox.
  Future<void> resolve(String dedupeKey) async {
    final String? uid = await _currentUserId();
    if (uid == null) return;
    final Database db = await OfflineDatabase.instance.database;
    await db.delete(
      table,
      where: 'user_id = ? AND dedupe_key = ?',
      whereArgs: <Object?>[uid, dedupeKey],
    );
  }

  Future<List<NotificationItem>> list({
    NotificationType? type,
    int limit = 100,
  }) async {
    final String? uid = await _currentUserId();
    if (uid == null) return const <NotificationItem>[];

    final Database db = await OfflineDatabase.instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      where: type != null ? 'user_id = ? AND type = ?' : 'user_id = ?',
      whereArgs: type != null ? <Object?>[uid, type.value] : <Object?>[uid],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(NotificationItem.fromDatabase).toList(growable: false);
  }

  Future<int> countUnread() async {
    final String? uid = await _currentUserId();
    if (uid == null) return 0;

    final Database db = await OfflineDatabase.instance.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $table WHERE user_id = ? AND is_read = 0',
      <Object?>[uid],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> markRead(int id) async {
    final String? uid = await _currentUserId();
    if (uid == null) return;
    final Database db = await OfflineDatabase.instance.database;
    await db.update(
      table,
      <String, Object?>{'is_read': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: <Object?>[id, uid],
    );
  }

  Future<void> markAllRead() async {
    final String? uid = await _currentUserId();
    if (uid == null) return;
    final Database db = await OfflineDatabase.instance.database;
    await db.update(
      table,
      <String, Object?>{'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: <Object?>[uid],
    );
  }

  Future<void> deleteAll() async {
    final String? uid = await _currentUserId();
    if (uid == null) return;
    final Database db = await OfflineDatabase.instance.database;
    await db.delete(table, where: 'user_id = ?', whereArgs: <Object?>[uid]);
  }

  /// Buang notifikasi lebih tua dari [days] hari, plus batas keras
  /// [hardCap] item terbaru per akun - pengaman kalau ada bug yang bikin
  /// notifikasi berulang tak terkendali walau anti-duplikat sudah ada.
  Future<void> prune({required int days, int hardCap = 200}) async {
    final String? uid = await _currentUserId();
    if (uid == null) return;

    final Database db = await OfflineDatabase.instance.database;
    final String cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();

    await db.delete(
      table,
      where: 'user_id = ? AND created_at < ?',
      whereArgs: <Object?>[uid, cutoff],
    );

    final List<Map<String, Object?>> sisa = await db.query(
      table,
      columns: <String>['id'],
      where: 'user_id = ?',
      whereArgs: <Object?>[uid],
      orderBy: 'created_at DESC',
    );

    if (sisa.length > hardCap) {
      final List<int> idDibuang = sisa
          .skip(hardCap)
          .map((Map<String, Object?> r) => r['id'] as int)
          .toList();

      final String placeholders = List.filled(idDibuang.length, '?').join(',');
      await db.delete(
        table,
        where: 'id IN ($placeholders)',
        whereArgs: idDibuang,
      );
    }
  }
}