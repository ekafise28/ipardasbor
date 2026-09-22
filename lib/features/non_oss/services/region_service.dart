import '../models/region_option.dart';
import '../offline/wilayah_local_database.dart';
import 'wilayah_akses_service.dart';

class RegionService {
  RegionService({
    WilayahLocalDatabase? database,
    WilayahAksesService? akses,
  }) : _database = database ?? WilayahLocalDatabase.instance,
       _akses = akses ?? WilayahAksesService.instance;

  final WilayahLocalDatabase _database;
  final WilayahAksesService _akses;

  Future<List<RegionOption>> provinces() async {
    final List<RegionOption> semua = await _database.provinces();
    final akses = await _akses.current();
    return akses == null ? semua : akses.filterProvinsi(semua);
  }

  Future<List<RegionOption>> regencies(int provinceId) async {
    final List<RegionOption> semua = await _database.regencies(provinceId);
    final akses = await _akses.current();
    return akses == null ? semua : akses.filterKabupaten(provinceId, semua);
  }

  Future<List<RegionOption>> districts(int regencyId) =>
      _database.districts(regencyId);

  Future<List<RegionOption>> villages(int districtId) =>
      _database.villages(districtId);
}