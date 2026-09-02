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
    required this.statusPengawasan,
    required this.statusKetidaksesuaian,
    required this.keterangan,
    required this.catatanPetugas,
    required this.tanggalPengawasan,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int? idProyek;
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

  final String? statusPengawasan;
  final String? statusKetidaksesuaian;
  final String? keterangan;
  final String? catatanPetugas;

  final DateTime? tanggalPengawasan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nama usaha yang enak ditampilkan sebagai judul halaman.
  /// (Tidak menarik dari tabel proyek karena scope endpoint ini sengaja
  /// dibatasi hanya kolom tbl_oss_pengawasan.)
  String get namaUsaha => namaBrand ?? namaPemilik ?? '-';

  factory RiwayatDetail.fromJson(Map<String, dynamic> json) {
    return RiwayatDetail(
      id: (json['id'] as num).toInt(),
      idProyek: _toInt(json['id_proyek']),
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
      statusPengawasan: _toStringSafe(json['status_pengawasan']),
      statusKetidaksesuaian: _toStringSafe(json['status_ketidaksesuaian']),
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
    );
  }
}

int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
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
  // bukan string — convert aja daripada crash.
  return value.toString();
}