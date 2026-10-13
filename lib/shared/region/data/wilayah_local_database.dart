import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/region_option.dart';

/// Sumber data wilayah offline yang dibundel bersama aplikasi.
///
/// ID pada database ini sama dengan ID wilayah di Laravel. Database asset
/// disalin ke direktori database aplikasi saat pertama kali digunakan.
class WilayahLocalDatabase {
  WilayahLocalDatabase._();

  static final WilayahLocalDatabase instance = WilayahLocalDatabase._();

  static const String _assetPath = 'assets/database/wilayah_indonesia.db';
  static const String _localFileName = 'wilayah_indonesia.db';

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database {
    final Database? opened = _database;
    if (opened != null && opened.isOpen) {
      return Future<Database>.value(opened);
    }

    return _openingDatabase ??= _open().whenComplete(() {
      _openingDatabase = null;
    });
  }

  Future<Database> _open() async {
    final String databasesDirectory = await getDatabasesPath();
    final String databasePath = p.join(databasesDirectory, _localFileName);

    if (!await databaseExists(databasePath)) {
      await Directory(p.dirname(databasePath)).create(recursive: true);

      final ByteData asset = await rootBundle.load(_assetPath);
      final Uint8List bytes = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );

      // Tulis ke file sementara agar database tidak pernah terbaca setengah jadi.
      final File temporaryFile = File('$databasePath.tmp');
      await temporaryFile.writeAsBytes(bytes, flush: true);
      await temporaryFile.rename(databasePath);
    }

    final Database opened = await openDatabase(
      databasePath,
      readOnly: true,
      singleInstance: true,
    );
    _database = opened;
    return opened;
  }

  Future<List<RegionOption>> provinces() {
    return _queryRegions(table: 'tbl_provinsi', nameColumn: 'nama_provinsi');
  }

  Future<List<RegionOption>> regencies(int provinceId) {
    return _queryRegions(
      table: 'tbl_kabupaten',
      nameColumn: 'nama_kabupaten',
      where: 'propinsi_id = ?',
      whereArgs: <Object>[provinceId],
    );
  }

  Future<List<RegionOption>> districts(int regencyId) {
    return _queryRegions(
      table: 'tbl_kecamatan',
      nameColumn: 'nama_kecamatan',
      where: 'kabupaten_id = ?',
      whereArgs: <Object>[regencyId],
    );
  }

  Future<List<RegionOption>> villages(int districtId) {
    return _queryRegions(
      table: 'tbl_kelurahan',
      nameColumn: 'nama_kelurahan',
      where: 'kecamatan_id = ?',
      whereArgs: <Object>[districtId],
    );
  }

  Future<List<RegionOption>> _queryRegions({
    required String table,
    required String nameColumn,
    String? where,
    List<Object>? whereArgs,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      columns: <String>['id', nameColumn],
      where: where,
      whereArgs: whereArgs,
      orderBy: '$nameColumn COLLATE NOCASE ASC',
    );

    return rows
        .map(
          (Map<String, Object?> row) => RegionOption(
            id: row['id'] as int,
            name: row[nameColumn]?.toString() ?? '-',
          ),
        )
        .toList(growable: false);
  }

  Future<String?> provinceName(int id) =>
      _regionName(table: 'tbl_provinsi', nameColumn: 'nama_provinsi', id: id);

  Future<String?> regencyName(int id) =>
      _regionName(table: 'tbl_kabupaten', nameColumn: 'nama_kabupaten', id: id);

  Future<String?> districtName(int id) =>
      _regionName(table: 'tbl_kecamatan', nameColumn: 'nama_kecamatan', id: id);

  Future<String?> villageName(int id) =>
      _regionName(table: 'tbl_kelurahan', nameColumn: 'nama_kelurahan', id: id);

  Future<String?> _regionName({
    required String table,
    required String nameColumn,
    required int id,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      table,
      columns: <String>[nameColumn],
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first[nameColumn]?.toString();
  }
}
