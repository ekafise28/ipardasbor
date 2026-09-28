import '../../non_oss/models/region_option.dart';
import 'baseline_ota_item.dart';

/// Opsi filter yang dikembalikan backend, dibatasi sesuai akses wilayah
/// user (lihat data.filter_opsi di mobileIndex()).
class BaselineOtaFilterOptions {
  const BaselineOtaFilterOptions({
    required this.provinsi,
    required this.kabupaten,
    required this.platformOta,
  });

  final List<RegionOption> provinsi;
  final List<RegionOption> kabupaten;
  final List<String> platformOta;

  factory BaselineOtaFilterOptions.fromJson(Map<String, dynamic> json) {
    List<RegionOption> parseRegion(dynamic list) => (list as List? ?? [])
        .map((e) => RegionOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return BaselineOtaFilterOptions(
      provinsi: parseRegion(json['provinsi']),
      kabupaten: parseRegion(json['kabupaten']),
      platformOta: (json['platform_ota'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Satu halaman hasil listing baseline OTA + info paginasi + opsi filter,
/// sesuai bentuk `data` pada respons mobileIndex().
class BaselineOtaPageResult {
  const BaselineOtaPageResult({
    required this.provinsiId,
    required this.provinsiNama,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.filterOptions,
  });

  final int? provinsiId;
  final String provinsiNama;
  final List<BaselineOtaItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final BaselineOtaFilterOptions filterOptions;

  bool get hasMore => currentPage < lastPage;

  factory BaselineOtaPageResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      json['data'] as Map,
    );
    final Map<String, dynamic> pagination = Map<String, dynamic>.from(
      data['pagination'] as Map,
    );

    final Map<String, dynamic> provinsi = data['provinsi'] is Map
        ? Map<String, dynamic>.from(data['provinsi'] as Map)
        : <String, dynamic>{};

    return BaselineOtaPageResult(
      provinsiId: int.tryParse(provinsi['id']?.toString() ?? ''),
      provinsiNama: provinsi['nama']?.toString() ?? '-',
      items: (data['items'] as List? ?? [])
          .map(
            (e) =>
                BaselineOtaItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      currentPage: int.parse(pagination['current_page'].toString()),
      lastPage: int.parse(pagination['last_page'].toString()),
      total: int.parse(pagination['total'].toString()),
      filterOptions: BaselineOtaFilterOptions.fromJson(
        Map<String, dynamic>.from(data['filter_opsi'] as Map),
      ),
    );
  }
}
