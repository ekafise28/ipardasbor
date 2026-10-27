/// Info wilayah lengkap (nama, bukan cuma ID) untuk satu item riwayat.
class RiwayatDetailWilayah {
  const RiwayatDetailWilayah({
    required this.provinsiId,
    required this.provinsi,
    required this.kabupatenId,
    required this.kabupaten,
    required this.kecamatanId,
    required this.kecamatan,
    required this.kelurahanId,
    required this.kelurahan,
  });

  final int? provinsiId;
  final String? provinsi;
  final int? kabupatenId;
  final String? kabupaten;
  final int? kecamatanId;
  final String? kecamatan;
  final int? kelurahanId;
  final String? kelurahan;

  factory RiwayatDetailWilayah.fromJson(Map<String, dynamic> json) {
    return RiwayatDetailWilayah(
      provinsiId: (json['provinsi_id'] as num?)?.toInt(),
      provinsi: json['provinsi'] as String?,
      kabupatenId: (json['kabupaten_id'] as num?)?.toInt(),
      kabupaten: json['kabupaten'] as String?,
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      kelurahanId: (json['kelurahan_id'] as num?)?.toInt(),
      kelurahan: json['kelurahan'] as String?,
    );
  }

  /// Contoh: "Kelurahan X, Kecamatan Y, Kabupaten Z, Provinsi W".
  String get gabungan {
    final List<String> bagian =
        <String?>[kelurahan, kecamatan, kabupaten, provinsi]
            .whereType<String>()
            .where((String value) => value.trim().isNotEmpty)
            .toList();

    return bagian.isEmpty ? '-' : bagian.join(', ');
  }
}

/// Detail lengkap satu baris data pada tabel tbl_oss_pengawasan.
///
/// Berbeda dengan [RiwayatItem] (dipakai di list), model ini memuat SEMUA
/// kolom yang tersedia, diambil dari endpoint detail
/// (GET /api/mobile/oss/riwayat/{id}).
class RiwayatDetail {
  const RiwayatDetail({
    required this.id,
    required this.idProyek,
    required this.sumberData,
    required this.statusVerifikasi,
    required this.petugas,
    required this.namaPemilik,
    required this.namaBrand,
    required this.jenisProduk,
    required this.kbli,
    required this.kbliDesc,
    required this.website,
    required this.noHp,
    required this.email,
    required this.memilikiNib,
    required this.nib,
    required this.npwpd,
    required this.terdaftarOta,
    required this.wilayah,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.hasilValidasi,
    required this.pesanValidasi,
    required this.statusPengawasan,
    required this.statusKetidaksesuaian,
    required this.keteranganKetidaksesuaian,
    required this.keterangan,
    required this.catatanPetugas,
    required this.tanggalPengawasan,
    required this.createdAt,
    required this.updatedAt,
    required this.foto,
    required this.ota,
  });

  final int id;

  /// NKU (bentuk "R-xxxxxxxxx"), disimpan di kolom id_proyek. BUKAN angka
  /// - jangan di-parse pakai int.tryParse, cuma string identifier.
  final String? idProyek;

  final String sumberData;
  final String statusVerifikasi;

  final String? petugas;

  final String? namaPemilik;
  final String? namaBrand;
  final String? jenisProduk;
  final String? kbli;
  final String? kbliDesc;
  final String? website;
  final String? noHp;
  final String? email;

  final String? memilikiNib;
  final String? nib;
  final String? npwpd;
  final String? terdaftarOta;

  final RiwayatDetailWilayah wilayah;
  final String? alamat;
  final double? latitude;
  final double? longitude;

  /// 'VALID' / 'TIDAK_VALID' - hasil validasi otomatis NIB/KBLI/NKU ke API
  /// OSS saat data ini disimpan. Null untuk data Non-OSS/OTA.
  final String? hasilValidasi;

  /// Penjelasan dari sistem kenapa hasilnya begitu (mis. "KBLI tidak sesuai
  /// dengan proyek OSS.").
  final String? pesanValidasi;

  final String? statusPengawasan;

  /// Kategori ketidaksesuaian yang dipilih petugas (hanya diisi kalau
  /// [hasilValidasi] == 'TIDAK_VALID'). Kolomnya di backend di-cast array,
  /// jadi ini beneran List, bukan String tunggal.
  final List<String> statusKetidaksesuaian;

  /// Penjelasan bebas dari petugas untuk ketidaksesuaian di atas.
  final String? keteranganKetidaksesuaian;

  final String? keterangan;
  final String? catatanPetugas;

  final DateTime? tanggalPengawasan;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RiwayatDetailFoto> foto;
  final List<RiwayatDetailOta> ota;

  /// Nama usaha yang enak ditampilkan sebagai judul halaman.
  /// (Tidak menarik dari tabel proyek karena scope endpoint ini sengaja
  /// dibatasi hanya kolom tbl_oss_pengawasan.)
  String get namaUsaha => namaBrand ?? namaPemilik ?? '-';

  /// True kalau data OSS ini hasil validasinya TIDAK_VALID - dipakai untuk
  /// menampilkan badge peringatan di halaman detail.
  bool get ossTidakValid =>
      sumberData.toUpperCase() == 'OSS' && hasilValidasi == 'TIDAK_VALID';

  factory RiwayatDetail.fromJson(Map<String, dynamic> json) {
    return RiwayatDetail(
      id: (json['id'] as num).toInt(),
      idProyek: json['id_proyek'] as String?,
      sumberData: (json['sumber_data'] as String?) ?? '-',
      statusVerifikasi: (json['status_verifikasi'] as String?) ?? '-',
      petugas: json['petugas'] as String?,
      namaPemilik: json['nama_pemilik'] as String?,
      namaBrand: json['nama_brand'] as String?,
      jenisProduk: json['jenis_produk'] as String?,
      kbli: json['kbli'] as String?,
      kbliDesc: json['kbli_desc'] as String?,
      website: json['website'] as String?,
      noHp: json['no_hp'] as String?,
      email: json['email'] as String?,
      memilikiNib: _toStringSafe(json['memiliki_nib']),
      nib: json['nib'] as String?,
      npwpd: json['npwpd'] as String?,
      terdaftarOta: _toStringSafe(json['terdaftar_ota']),
      wilayah: RiwayatDetailWilayah.fromJson(
        (json['wilayah'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      alamat: json['alamat'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      hasilValidasi: json['hasil_validasi'] as String?,
      pesanValidasi: json['pesan_validasi'] as String?,
      statusPengawasan: _toStringSafe(json['status_pengawasan']),
      statusKetidaksesuaian: _toStringList(json['status_ketidaksesuaian']),
      keteranganKetidaksesuaian: json['keterangan_ketidaksesuaian'] as String?,
      keterangan: json['keterangan'] as String?,
      catatanPetugas: json['catatan_petugas'] as String?,
      tanggalPengawasan: json['tanggal_pengawasan'] != null
          ? DateTime.tryParse(json['tanggal_pengawasan'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      foto: ((json['foto'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                RiwayatDetailFoto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      ota: ((json['ota'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                RiwayatDetailOta.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

String? _toStringSafe(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  // Backend kadang ngirim status/kode sebagai number atau bool,
  // bukan string - convert aja daripada crash.
  return value.toString();
}

/// Backend meng-cast status_ketidaksesuaian sebagai array (JSON), jadi di
/// sini kita terima List asli - bukan di-stringify seperti _toStringSafe.
List<String> _toStringList(dynamic value) {
  if (value == null) {
    return const <String>[];
  }

  if (value is List) {
    return value
        .map((dynamic e) => e.toString().trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  // Jaga-jaga kalau suatu saat backend malah kirim string tunggal.
  final String s = value.toString().trim();
  return s.isEmpty ? const <String>[] : <String>[s];
}

/// Satu foto dokumentasi hasil pengawasan.
class RiwayatDetailFoto {
  const RiwayatDetailFoto({
    required this.id,
    required this.namaFile,
    required this.url,
    required this.mimeType,
    required this.keterangan,
  });

  final int id;
  final String namaFile;
  final String url;
  final String? mimeType;
  final String? keterangan;

  factory RiwayatDetailFoto.fromJson(Map<String, dynamic> json) {
    return RiwayatDetailFoto(
      id: (json['id'] as num).toInt(),
      namaFile: (json['nama_file'] as String?) ?? '-',
      url: (json['url'] as String?) ?? '',
      mimeType: json['mime_type'] as String?,
      keterangan: json['keterangan'] as String?,
    );
  }
}

/// Satu listing OTA (Online Travel Agent) terkait hasil pengawasan.
class RiwayatDetailOta {
  const RiwayatDetailOta({
    required this.id,
    required this.namaPlatform,
    required this.namaListing,
    required this.urlListing,
    required this.statusListing,
    required this.tanggalDitemukan,
    required this.tanggalDiperiksa,
    required this.hargaTerendah,
    required this.rating,
    required this.jumlahUlasan,
    required this.latitude,
    required this.longitude,
    required this.catatan,
    required this.mapsUrl,
  });

  final int id;
  final String? namaPlatform;
  final String? namaListing;
  final String? urlListing;
  final String? statusListing;
  final DateTime? tanggalDitemukan;
  final DateTime? tanggalDiperiksa;
  final double? hargaTerendah;
  final double? rating;
  final int? jumlahUlasan;
  final double? latitude;
  final double? longitude;
  final String? catatan;
  final String? mapsUrl;

  factory RiwayatDetailOta.fromJson(Map<String, dynamic> json) {
    return RiwayatDetailOta(
      id: (json['id'] as num).toInt(),
      namaPlatform: json['nama_platform'] as String?,
      namaListing: json['nama_listing'] as String?,
      urlListing: json['url_listing'] as String?,
      statusListing: json['status_listing'] as String?,
      tanggalDitemukan: json['tanggal_ditemukan'] != null
          ? DateTime.tryParse(json['tanggal_ditemukan'] as String)
          : null,
      tanggalDiperiksa: json['tanggal_diperiksa'] != null
          ? DateTime.tryParse(json['tanggal_diperiksa'] as String)
          : null,
      hargaTerendah: _toDouble(json['harga_terendah']),
      rating: _toDouble(json['rating']),
      jumlahUlasan: _toIntOta(json['jumlah_ulasan']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      catatan: json['catatan'] as String?,
      mapsUrl: json['maps_url'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toIntOta(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}