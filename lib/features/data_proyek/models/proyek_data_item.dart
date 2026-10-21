import 'proyek_data_parse.dart';

/// Satu baris tbl_proyek (11 kolom tabel web + kab/kota dan versi KBLI).
class ProyekDataItem {
  const ProyekDataItem({
    required this.id,
    required this.namaPerusahaan,
    required this.nib,
    required this.kbli,
    this.skalaUsaha,
    this.risiko,
    this.statusModal,
    this.versiKbli,
    this.judulKbli,
    this.jumlahInvestasi,
    this.jumlahTenagaKerja,
    this.alamat,
    this.provinsi,
    this.kabKota,
  });

  final int id;
  final String namaPerusahaan;
  final String nib;
  final String kbli;
  final String? skalaUsaha;
  final String? risiko;
  final String? statusModal;
  final int? versiKbli;
  final String? judulKbli;
  final int? jumlahInvestasi;
  final int? jumlahTenagaKerja;
  final String? alamat;
  final String? provinsi;
  final String? kabKota;

  /// "Kab. X, Provinsi Y" untuk baris lokasi di kartu.
  String get lokasi {
    final List<String> bagian = <String>[
      ?kabKota,
      ?provinsi,
    ];
    return bagian.isEmpty ? '-' : bagian.join(', ');
  }

  factory ProyekDataItem.fromJson(Map<String, dynamic> json) {
    return ProyekDataItem(
      id: angkaAtauNull(json['id']) ?? 0,
      namaPerusahaan: teksAtauNull(json['nama_perusahaan']) ?? '-',
      nib: teksAtauNull(json['nib']) ?? '-',
      kbli: teksAtauNull(json['kbli']) ?? '-',
      skalaUsaha: teksAtauNull(json['uraian_skala_usaha']),
      risiko: teksAtauNull(json['uraian_risiko_proyek']),
      statusModal: teksAtauNull(json['status_penanaman_modal']),
      versiKbli: angkaAtauNull(json['versikbli']),
      judulKbli: teksAtauNull(json['judul_kbli']),
      jumlahInvestasi: angkaAtauNull(json['jumlah_investasi']),
      jumlahTenagaKerja: angkaAtauNull(json['jumlah_tenaga_kerja']),
      alamat: teksAtauNull(json['alamat_usaha']),
      provinsi: teksAtauNull(json['provinsi_usaha']),
      kabKota: teksAtauNull(json['kab_kota_usaha']),
    );
  }
}