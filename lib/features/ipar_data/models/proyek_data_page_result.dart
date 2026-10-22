import 'proyek_data_item.dart';
import 'proyek_data_parse.dart';

class ProyekDataPagination {
  const ProyekDataPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasNextPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasNextPage;

  factory ProyekDataPagination.fromJson(Map<String, dynamic> json) {
    return ProyekDataPagination(
      currentPage: angkaAtauNull(json['current_page']) ?? 1,
      perPage: angkaAtauNull(json['per_page']) ?? 10,
      total: angkaAtauNull(json['total']) ?? 0,
      lastPage: angkaAtauNull(json['last_page']) ?? 1,
      hasNextPage: json['has_next_page'] == true,
    );
  }
}

class ProyekDataPageResult {
  const ProyekDataPageResult({
    required this.items,
    required this.pagination,
    this.provinsiUser,
    this.aksesSemuaWilayah = false,
    this.dariOffline = false, // baru
    this.waktuOffline, // baru
  });

  /// true kalau hasil ini berasal dari data yang diunduh manual.
  final bool dariOffline;
  final DateTime? waktuOffline;

  final List<ProyekDataItem> items;
  final ProyekDataPagination pagination;

  /// Nama provinsi kalau akun terkunci ke satu provinsi; null selain itu.
  final String? provinsiUser;
  final bool aksesSemuaWilayah;

  factory ProyekDataPageResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> mentah =
        (json['items'] as List<dynamic>?) ?? const <dynamic>[];

    return ProyekDataPageResult(
      items: mentah
          .whereType<Map<String, dynamic>>()
          .map(ProyekDataItem.fromJson)
          .toList(),
      pagination: ProyekDataPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      provinsiUser: teksAtauNull(json['provinsi_user']),
      aksesSemuaWilayah: json['akses_semua_wilayah'] == true,
    );
  }
}
