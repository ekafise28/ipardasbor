// lib/features/peta_industri/models/peta_detail_model.dart

/// Satu baris rekap (jenis usaha + KBLI + risiko + jumlah proyek).
class PetaRekapItem {
  const PetaRekapItem({
    required this.id,
    required this.jenisUsaha,
    required this.namaKbli,
    required this.kbli,
    required this.risiko,
    required this.jumlah,
  });

  final int id;
  final String jenisUsaha;
  final String namaKbli;
  final String kbli;
  final String risiko;
  final int jumlah;

  factory PetaRekapItem.fromJson(Map<String, dynamic> json) {
    return PetaRekapItem(
      id: _asInt(json['id']),
      jenisUsaha: _asText(json['jenis_usaha']),
      namaKbli: _asText(json['nama_kbli']),
      kbli: _asText(json['kbli']),
      risiko: _asText(json['risiko']),
      jumlah: _asInt(json['jumlah']),
    );
  }
}

/// Satu halaman hasil GET /mobile/peta-industri/{provinsi}/detail.
class PetaRekapHalaman {
  const PetaRekapHalaman({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final List<PetaRekapItem> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory PetaRekapHalaman.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];
    final dynamic rawMeta = json['meta'];
    final Map<String, dynamic> meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : const <String, dynamic>{};

    return PetaRekapHalaman(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((e) => PetaRekapItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const <PetaRekapItem>[],
      page: _asInt(meta['page']),
      perPage: _asInt(meta['per_page']),
      total: _asInt(meta['total']),
      lastPage: _asInt(meta['last_page']),
    );
  }
}

String _asText(dynamic value) {
  final String text = (value ?? '').toString().trim();
  return text.isEmpty ? '-' : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}