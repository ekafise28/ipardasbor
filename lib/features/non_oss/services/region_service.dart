import '../models/region_option.dart';
import '../offline/wilayah_local_database.dart';

class RegionService {
  RegionService({WilayahLocalDatabase? database})
    : _database = database ?? WilayahLocalDatabase.instance;

  final WilayahLocalDatabase _database;

  Future<List<RegionOption>> provinces() => _database.provinces();

  Future<List<RegionOption>> regencies(int provinceId) =>
      _database.regencies(provinceId);

  Future<List<RegionOption>> districts(int regencyId) =>
      _database.districts(regencyId);

  Future<List<RegionOption>> villages(int districtId) =>
      _database.villages(districtId);
}
