import 'region_option.dart';

/// Wilayah kewenangan akun, sama dengan hasil WilayahAccessService::scope().
class WilayahAkses {
  const WilayahAkses({
    required this.fullAccess,
    required this.provinsiIds,
    required this.kabupatenIds,
  });

  final bool fullAccess;
  final Set<int> provinsiIds;
  final Set<int> kabupatenIds;

  factory WilayahAkses.fromJson(Map<String, dynamic> json) {
    Set<int> ids(dynamic raw) => ((raw as List<dynamic>?) ?? const <dynamic>[])
        .map((dynamic e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toSet();

    return WilayahAkses(
      fullAccess: json['full_access'] == true,
      provinsiIds: ids(json['provinsi_ids']),
      kabupatenIds: ids(json['kabupaten_ids']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'full_access': fullAccess,
    'provinsi_ids': provinsiIds.toList(),
    'kabupaten_ids': kabupatenIds.toList(),
  };

  List<RegionOption> filterProvinsi(List<RegionOption> semua) {
    if (fullAccess) return semua;
    return semua.where((RegionOption o) => provinsiIds.contains(o.id)).toList();
  }

  /// Aturan sama dengan backend: kalau akun dibatasi sampai kabupaten,
  /// hanya kabupaten itu; kalau hanya provinsi, semua kabupaten di provinsi itu.
  List<RegionOption> filterKabupaten(int provinsiId, List<RegionOption> semua) {
    if (fullAccess) return semua;
    if (!provinsiIds.contains(provinsiId)) return const <RegionOption>[];
    if (kabupatenIds.isEmpty) return semua;
    return semua.where((RegionOption o) => kabupatenIds.contains(o.id)).toList();
  }
}