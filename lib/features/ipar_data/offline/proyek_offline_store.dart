import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/cache/cache_preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../../non_oss/offline/offline_database.dart';
import '../models/proyek_data_item.dart';
import 'proyek_offline_meta.dart';

/// Penyimpanan dataset Data Proyek offline. Isi dikompres lalu dienkripsi
/// AES-GCM dengan kunci per akun (sama seperti ApiCache), dan terikat ke
/// akun serta nomor potongan lewat AAD.
class ProyekOfflineStore {
  ProyekOfflineStore._();
  static final ProyekOfflineStore instance = ProyekOfflineStore._();

  static const String _chunk = 'proyek_offline_chunk';
  static const String _meta = 'proyek_offline_meta';
  static final AesGcm _aes = AesGcm.with256bits();

  List<ProyekDataItem>? _memo;
  String? _memoUid;

  Future<String?> _uid() async {
    final String? id = await SecureStorage.getUserId();
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  /// Keterangan dataset, atau null kalau belum ada / sudah kedaluwarsa
  /// (mengikuti "Simpan data selama" di Pengaturan).
  Future<ProyekOfflineMeta?> meta() async {
    final String? uid = await _uid();
    if (uid == null) return null;

    final Database db = await OfflineDatabase.instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      _meta,
      where: 'user_id = ?',
      whereArgs: <Object?>[uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    try {
      final ProyekOfflineMeta m = ProyekOfflineMeta.fromJson(
        jsonDecode(rows.first['meta_json']! as String) as Map<String, dynamic>,
      );
      final DateTime batas = DateTime.now().subtract(
        Duration(days: CachePreferences.instance.maxDays),
      );
      if (m.savedAt.isBefore(batas)) {
        await hapus();
        return null;
      }
      return m;
    } catch (_) {
      await hapus();
      return null;
    }
  }

  /// Menyimpan satu potongan. Mengembalikan ukuran tersimpan (byte), atau
  /// null kalau potongan ini akan melewati [batasBytes] (tidak disimpan).
  Future<int?> simpanChunk(
    int nomor,
    List<Map<String, dynamic>> rows, {
    required int terpakai,
    required int batasBytes,
  }) async {
    final String? uid = await _uid();
    if (uid == null) {
      throw StateError('Sesi login berakhir. Masuk kembali untuk menyimpan data.');
    }

    final List<int> mampat = gzip.encode(utf8.encode(jsonEncode(rows)));
    final Uint8List blob = await _enkripsi(uid, nomor, mampat);
    if (terpakai + blob.length > batasBytes) return null;

    final Database db = await OfflineDatabase.instance.database;
    await db.insert(_chunk, <String, Object?>{
      'user_id': uid,
      'chunk_no': nomor,
      'data': blob,
      'size_bytes': blob.length,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _memo = null;
    return blob.length;
  }

  Future<void> simpanMeta(ProyekOfflineMeta m) async {
    final String? uid = await _uid();
    if (uid == null) return;

    final Database db = await OfflineDatabase.instance.database;
    await db.insert(_meta, <String, Object?>{
      'user_id': uid,
      'meta_json': jsonEncode(m.toJson()),
      'saved_at': m.savedAt.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> hapus() async {
    _memo = null;
    final String? uid = await _uid();
    if (uid == null) return;

    final Database db = await OfflineDatabase.instance.database;
    await db.delete(_chunk, where: 'user_id = ?', whereArgs: <Object?>[uid]);
    await db.delete(_meta, where: 'user_id = ?', whereArgs: <Object?>[uid]);
  }

  /// Seluruh baris dataset (diurutkan menurut id server). Disimpan di
  /// memori sampai dataset berubah supaya filter/halaman berikutnya cepat.
  Future<List<ProyekDataItem>> muatSemua() async {
    final String? uid = await _uid();
    if (uid == null) return const <ProyekDataItem>[];
    if (_memo != null && _memoUid == uid) return _memo!;

    try {
      final Database db = await OfflineDatabase.instance.database;
      final List<Map<String, Object?>> rows = await db.query(
        _chunk,
        where: 'user_id = ?',
        whereArgs: <Object?>[uid],
        orderBy: 'chunk_no ASC',
      );

      final List<ProyekDataItem> hasil = <ProyekDataItem>[];
      for (final Map<String, Object?> r in rows) {
        final List<int> mampat = await _dekripsi(
          uid,
          r['chunk_no']! as int,
          r['data']! as Uint8List,
        );
        final List<dynamic> daftar =
            jsonDecode(utf8.decode(gzip.decode(mampat))) as List<dynamic>;
        hasil.addAll(
          daftar.whereType<Map<String, dynamic>>().map(ProyekDataItem.fromJson),
        );
      }

      _memo = hasil;
      _memoUid = uid;
      return hasil;
    } catch (_) {
      // Rusak atau tidak bisa didekripsi: buang supaya tidak menggantung.
      await hapus();
      return const <ProyekDataItem>[];
    }
  }

  Future<Uint8List> _enkripsi(String uid, int nomor, List<int> plain) async {
    final SecretKey kunci = SecretKey(
      await SecureStorage.getOrCreateCacheKey(uid),
    );
    final SecretBox box = await _aes.encrypt(
      plain,
      secretKey: kunci,
      aad: utf8.encode('$uid|proyek-offline|$nomor'),
    );
    return Uint8List.fromList(box.concatenation());
  }

  Future<List<int>> _dekripsi(String uid, int nomor, Uint8List blob) async {
    final SecretKey kunci = SecretKey(
      await SecureStorage.getOrCreateCacheKey(uid),
    );
    final SecretBox box = SecretBox.fromConcatenation(
      blob,
      nonceLength: 12,
      macLength: 16,
    );
    return _aes.decrypt(
      box,
      secretKey: kunci,
      aad: utf8.encode('$uid|proyek-offline|$nomor'),
    );
  }
}