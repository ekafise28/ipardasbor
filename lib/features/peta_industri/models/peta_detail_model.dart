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
                .map(
                  (e) => PetaRekapItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <PetaRekapItem>[],
      page: _asInt(meta['page']),
      perPage: _asInt(meta['per_page']),
      total: _asInt(meta['total']),
      lastPage: _asInt(meta['last_page']),
    );
  }
}

/// Satu perusahaan pada daftar di balik satu baris rekap.
class PetaPerusahaanItem {
  const PetaPerusahaanItem({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.nib,
    required this.investasi,
    required this.tenagaKerja,
    this.telepon,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String nama;
  final String alamat;
  final String nib;
  final int investasi;
  final int tenagaKerja;

  /// null bila kosong atau tidak masuk akal.
  final String? telepon;
  final double? latitude;
  final double? longitude;

  bool get adaNib => nib != '-';
  bool get adaLokasi => latitude != null && longitude != null;

  factory PetaPerusahaanItem.fromJson(Map<String, dynamic> json) {
    final double? lat = _asKoordinat(json['latitude']);
    final double? lng = _asKoordinat(json['longitude']);
    final bool lokasiValid =
        lat != null &&
        lng != null &&
        lat >= -11.5 &&
        lat <= 6.5 &&
        lng >= 94.5 &&
        lng <= 141.5;

    return PetaPerusahaanItem(
      id: _asInt(json['id']),
      nama: _asText(json['nama']),
      alamat: _asText(json['alamat']),
      nib: _asText(json['nib']),
      investasi: _asInt(json['investasi']),
      tenagaKerja: _asInt(json['tenaga_kerja']),
      telepon: _asTelepon(json['telepon']),
      latitude: lokasiValid ? lat : null,
      longitude: lokasiValid ? lng : null,
    );
  }
}

double? _asKoordinat(dynamic value) =>
    double.tryParse((value ?? '').toString().trim().replaceAll(',', '.'));

/// Hanya angka dan "+"; kurang dari 8 digit dianggap bukan nomor telepon.
String? _asTelepon(dynamic value) {
  final String bersih = (value ?? '').toString().replaceAll(
    RegExp(r'[^0-9+]'),
    '',
  );
  return bersih.replaceAll('+', '').length >= 8 ? bersih : null;
}

/// Satu halaman hasil GET /mobile/peta-industri/{provinsi}/perusahaan.
class PetaPerusahaanHalaman {
  const PetaPerusahaanHalaman({
    required this.items,
    required this.page,
    required this.total,
    required this.lastPage,
  });

  final List<PetaPerusahaanItem> items;
  final int page;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory PetaPerusahaanHalaman.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];
    final dynamic rawMeta = json['meta'];
    final Map<String, dynamic> meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : const <String, dynamic>{};

    return PetaPerusahaanHalaman(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) =>
                      PetaPerusahaanItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <PetaPerusahaanItem>[],
      page: _asInt(meta['page']),
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
