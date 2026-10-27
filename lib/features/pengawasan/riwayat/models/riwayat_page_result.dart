import 'riwayat_item.dart';

/// Satu opsi kabupaten/kota pada dropdown filter.
class RiwayatKabupatenOption {
  const RiwayatKabupatenOption({required this.id, required this.nama});

  final int id;
  final String nama;

  factory RiwayatKabupatenOption.fromJson(Map<String, dynamic> json) {
    return RiwayatKabupatenOption(
      id: (json['id'] as num).toInt(),
      nama: (json['nama'] as String?) ?? '-',
    );
  }
}

/// Seluruh opsi filter yang dikirim backend (kabupaten sudah dibatasi
/// sesuai akses wilayah user yang sedang login).
class RiwayatFilterOptions {
  const RiwayatFilterOptions({
    required this.kabupaten,
    required this.sumberData,
    required this.statusVerifikasi,
  });

  final List<RiwayatKabupatenOption> kabupaten;
  final List<String> sumberData;
  final List<String> statusVerifikasi;

  factory RiwayatFilterOptions.fromJson(Map<String, dynamic> json) {
    return RiwayatFilterOptions(
      kabupaten: ((json['kabupaten'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                RiwayatKabupatenOption.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      sumberData: ((json['sumber_data'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      statusVerifikasi:
          ((json['status_verifikasi'] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
    );
  }

  static const RiwayatFilterOptions kosong = RiwayatFilterOptions(
    kabupaten: <RiwayatKabupatenOption>[],
    sumberData: <String>[],
    statusVerifikasi: <String>[],
  );
}

/// Info pagination dari Laravel LengthAwarePaginator.
class RiwayatPagination {
  const RiwayatPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasNextPage => currentPage < lastPage;

  factory RiwayatPagination.fromJson(Map<String, dynamic> json) {
    return RiwayatPagination(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  static const RiwayatPagination kosong = RiwayatPagination(
    currentPage: 1,
    perPage: 25,
    total: 0,
    lastPage: 1,
  );
}

/// Hasil satu kali panggilan API riwayat: daftar item + info pagination +
/// opsi filter yang tersedia untuk user ini.
class RiwayatPageResult {
  const RiwayatPageResult({
    required this.items,
    required this.pagination,
    required this.filterOptions,
    this.ringkasan,
  });

  final List<RiwayatItem> items;
  final RiwayatPagination pagination;
  final RiwayatFilterOptions filterOptions;
  final RiwayatRingkasan? ringkasan;

  factory RiwayatPageResult.fromJson(Map<String, dynamic> json) {
    return RiwayatPageResult(
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                RiwayatItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pagination: RiwayatPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      filterOptions: RiwayatFilterOptions.fromJson(
        (json['filter_opsi'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      ringkasan: json['ringkasan'] is Map<String, dynamic>
          ? RiwayatRingkasan.fromJson(json['ringkasan'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Hitungan riwayat per status, untuk chip filter cepat.
class RiwayatRingkasan {
  const RiwayatRingkasan({
    required this.total,
    required this.draft,
    required this.selesai,
  });

  final int total;
  final int draft;
  final int selesai;

  factory RiwayatRingkasan.fromJson(Map<String, dynamic> json) {
    return RiwayatRingkasan(
      total: (json['total'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      selesai: (json['selesai'] as num?)?.toInt() ?? 0,
    );
  }
}
