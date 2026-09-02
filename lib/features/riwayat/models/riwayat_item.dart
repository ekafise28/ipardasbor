/// Rincian status legalitas & OTA satu item riwayat.
class RiwayatIdentitas {
  const RiwayatIdentitas({
    required this.memilikiNib,
    required this.labelNib,
    required this.nib,
    required this.terdaftarOta,
  });

  final String? memilikiNib;
  final String labelNib;
  final String? nib;
  final String? terdaftarOta;

  factory RiwayatIdentitas.fromJson(Map<String, dynamic> json) {
    return RiwayatIdentitas(
      memilikiNib: json['memiliki_nib'] as String?,
      labelNib: (json['label_nib'] as String?) ?? '-',
      nib: json['nib'] as String?,
      terdaftarOta: json['terdaftar_ota'] as String?,
    );
  }

  /// Contoh: "Tanpa NIB" atau "Tanpa NIB · Terdaftar OTA".
  String get ringkasan {
    final bool terdaftar = (terdaftarOta ?? '').toUpperCase() == 'YA';

    if (!terdaftar) {
      return labelNib;
    }

    return '$labelNib · Terdaftar OTA';
  }
}

/// Lokasi kabupaten & provinsi satu item riwayat.
class RiwayatLokasi {
  const RiwayatLokasi({required this.kabupaten, required this.provinsi});

  final String kabupaten;
  final String provinsi;

  factory RiwayatLokasi.fromJson(Map<String, dynamic> json) {
    return RiwayatLokasi(
      kabupaten: (json['kabupaten'] as String?) ?? '-',
      provinsi: (json['provinsi'] as String?) ?? '-',
    );
  }

  /// Contoh: "Kabupaten Sampang, Jawa Timur".
  String get gabungan {
    final List<String> bagian = <String>[
      kabupaten,
      provinsi,
    ].where((String value) => value.isNotEmpty && value != '-').toList();

    return bagian.isEmpty ? '-' : bagian.join(', ');
  }
}

/// Satu baris data pada daftar riwayat pengawasan.
class RiwayatItem {
  const RiwayatItem({
    required this.id,
    required this.jenis,
    required this.identitas,
    required this.namaUsaha,
    required this.lokasi,
    required this.petugas,
    required this.tanggal,
    required this.status,
  });

  final int id;
  final String jenis;
  final RiwayatIdentitas identitas;
  final String namaUsaha;
  final RiwayatLokasi lokasi;
  final String petugas;
  final DateTime? tanggal;
  final String status;

  bool get selesai => status.toUpperCase() == 'SELESAI';

  factory RiwayatItem.fromJson(Map<String, dynamic> json) {
    return RiwayatItem(
      id: (json['id'] as num).toInt(),
      jenis: (json['jenis'] as String?) ?? '-',
      identitas: RiwayatIdentitas.fromJson(
        (json['identitas'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      namaUsaha: (json['nama_usaha'] as String?) ?? '-',
      lokasi: RiwayatLokasi.fromJson(
        (json['lokasi'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      petugas: (json['petugas'] as String?) ?? '-',
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'] as String)
          : null,
      status: (json['status'] as String?) ?? '-',
    );
  }
}