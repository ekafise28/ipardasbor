import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/non_oss/offline/offline_database.dart';
import '../storage/secure_storage.dart';
import 'cache_preferences.dart';

class CachedEntry {
  const CachedEntry(this.data, this.savedAt);
  final dynamic data;
  final DateTime savedAt;
}

class ApiCache {
  ApiCache._();
  static final ApiCache instance = ApiCache._();

  static const String table = 'api_cache';

  /// Hanya GET dashboard, riwayat, profil, daftar OTA, dan daftar OSS proyek.
  static const Set<String> _exact = <String>{
    '/mobile/me',
    '/mobile/dashboard',
    '/mobile/peta-industri',
    '/mobile/oss/riwayat',
    '/mobile/oss/proyek',
    '/mobile/oss/baseline-ota',
  };
  static const List<String> _prefix = <String>[
    '/mobile/oss/riwayat/',
    '/mobile/oss/proyek/',
    '/mobile/peta-industri/',
  ];

  static final AesGcm _aes = AesGcm.with256bits();

  /// null = request ini tidak boleh di-cache.
  String? keyFor(String endpoint, Uri uri) {
    if (!CachePreferences.instance.enabled) return null;

    final bool boleh =
        _exact.contains(endpoint) || _prefix.any(endpoint.startsWith);
    if (!boleh) return null;

    // Potongan data ekspor tidak di-cache: besar dan hanya dipakai sekali.
    if (endpoint.endsWith('/perusahaan/ekspor')) return null;

    // Mode "Dekat saya": koordinat berubah tiap saat, cache-nya tidak berguna.
    if (uri.queryParameters.containsKey('lat')) return null;

    final List<MapEntry<String, String>> params =
        uri.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return '$endpoint?${params.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  Future<String?> _uid() async {
    final String? id = await SecureStorage.getUserId();
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String _batasKedaluwarsa() => DateTime.now()
      .toUtc()
      .subtract(Duration(days: CachePreferences.instance.maxDays))
      .toIso8601String();

  Future<bool> has(String key) async {
    try {
      final String? uid = await _uid();
      if (uid == null) return false;
      final Database db = await OfflineDatabase.instance.database;
      final List<Map<String, Object?>> rows = await db.query(
        table,
        columns: <String>['cache_key'],
        where: 'user_id = ? AND cache_key = ? AND saved_at >= ?',
        whereArgs: <Object?>[uid, key, _batasKedaluwarsa()],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<CachedEntry?> read(String key) async {
    final String? uid = await _uid();
    if (uid == null) return null;

    try {
      final Database db = await OfflineDatabase.instance.database;
      final List<Map<String, Object?>> rows = await db.query(
        table,
        where: 'user_id = ? AND cache_key = ? AND saved_at >= ?',
        whereArgs: <Object?>[uid, key, _batasKedaluwarsa()],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final Map<String, Object?> row = rows.first;
      final List<int> plain = await _decrypt(
        uid,
        key,
        row['data'] as Uint8List,
      );
      final dynamic data = jsonDecode(utf8.decode(gzip.decode(plain)));

      unawaited(
        db.update(
          table,
          <String, Object?>{
            'last_access': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'user_id = ? AND cache_key = ?',
          whereArgs: <Object?>[uid, key],
        ),
      );

      return CachedEntry(
        data,
        DateTime.parse(row['saved_at'] as String).toLocal(),
      );
    } catch (_) {
      // Rusak atau tidak bisa didekripsi: buang barisnya.
      try {
        final Database db = await OfflineDatabase.instance.database;
        await db.delete(
          table,
          where: 'user_id = ? AND cache_key = ?',
          whereArgs: <Object?>[uid, key],
        );
      } catch (_) {}
      return null;
    }
  }

  Future<void> put(String key, dynamic data) async {
    if (data == null) return;
    try {
      final String? uid = await _uid();
      if (uid == null) return;

      final List<int> compressed = gzip.encode(utf8.encode(jsonEncode(data)));
      final Uint8List blob = await _encrypt(uid, key, compressed);
      final String now = DateTime.now().toUtc().toIso8601String();

      final Database db = await OfflineDatabase.instance.database;
      await db.insert(table, <String, Object?>{
        'user_id': uid,
        'cache_key': key,
        'data': blob,
        'size_bytes': blob.length,
        'saved_at': now,
        'last_access': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await _pangkasKeBatas(db, uid);
    } catch (_) {
      // Cache bersifat bonus: gagal menyimpan tidak boleh mengganggu aplikasi.
    }
  }

  Future<void> _pangkasKeBatas(Database db, String uid) async {
    final int batas = CachePreferences.instance.maxBytes;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      columns: <String>['cache_key', 'size_bytes'],
      where: 'user_id = ?',
      whereArgs: <Object?>[uid],
      orderBy: 'last_access ASC',
    );

    int total = rows.fold<int>(0, (int s, r) => s + (r['size_bytes'] as int));
    for (final Map<String, Object?> r in rows) {
      if (total <= batas) break;
      await db.delete(
        table,
        where: 'user_id = ? AND cache_key = ?',
        whereArgs: <Object?>[uid, r['cache_key']],
      );
      total -= r['size_bytes'] as int;
    }
  }

  /// Semua akun di perangkat. Dipanggil saat aplikasi dibuka.
  Future<void> pruneExpired() async {
    try {
      final Database db = await OfflineDatabase.instance.database;
      await db.delete(
        table,
        where: 'saved_at < ?',
        whereArgs: <Object?>[_batasKedaluwarsa()],
      );
    } catch (_) {}
  }

  Future<int> usageBytes() async {
    final String? uid = await _uid();
    if (uid == null) return 0;
    final Database db = await OfflineDatabase.instance.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COALESCE(SUM(size_bytes), 0) AS total FROM $table WHERE user_id = ?',
      <Object?>[uid],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Hapus cache akun yang sedang login.
  Future<void> clearForCurrentUser() async {
    final String? uid = await _uid();
    if (uid == null) return;
    final Database db = await OfflineDatabase.instance.database;
    await db.delete(table, where: 'user_id = ?', whereArgs: <Object?>[uid]);
  }

  // AAD mengikat isi ke akun dan kunci request, jadi baris yang ditukar atau
  // disalin ke akun lain gagal didekripsi.
  Future<Uint8List> _encrypt(String uid, String key, List<int> plain) async {
    final SecretKey secret = SecretKey(
      await SecureStorage.getOrCreateCacheKey(uid),
    );
    final SecretBox box = await _aes.encrypt(
      plain,
      secretKey: secret,
      aad: utf8.encode('$uid|$key'),
    );
    return Uint8List.fromList(box.concatenation());
  }

  Future<List<int>> _decrypt(String uid, String key, Uint8List blob) async {
    final SecretKey secret = SecretKey(
      await SecureStorage.getOrCreateCacheKey(uid),
    );
    final SecretBox box = SecretBox.fromConcatenation(
      blob,
      nonceLength: 12,
      macLength: 16,
    );
    return _aes.decrypt(box, secretKey: secret, aad: utf8.encode('$uid|$key'));
  }
}
