import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Data form lanjutan validasi OSS.
///
/// Struktur field mengikuti kolom `tbl_oss_pengawasan` (lihat model
/// Laravel OssPengawasan) ditambah field khusus tahap ketidaksesuaian yang
/// masih dari alur `OssValidasiLanjutan` - backend belum final, jadi
/// [toFields] ini sifatnya sementara untuk keperluan visual/debug saja.
class OssFormData {
  OssFormData({
    required this.nib,
    required this.kbli,
    required this.nku,
    required this.isValid,
    String kbliDesc = '',
  }) : kbliDesc = kbliDesc;

  // --- Dari tahap validasi (readonly di form lanjutan) ---
  final String nib;
  final String kbli;
  final String nku;
  final bool isValid;
  final String kbliDesc;

  String namaPemilik = '';
  String namaBrand = '';

  /// Kalau [isValid], nilai ini otomatis sama dengan [kbli].
  /// Kalau tidak, user memilih dari dropdown kode KBLI akomodasi.
  String jenisProduk = '';

  int? provinsiId;
  int? kabupatenId;
  int? kecamatanId;
  int? kelurahanId;

  String alamat = '';
  String latitude = '';
  String longitude = '';

  String npwpd = '';
  String website = '';
  String noHp = '';
  String email = '';

  String terdaftarOta = 'TIDAK';

  /// Key = nama platform (mis. booking_com), value = daftar URL.
  final Map<String, List<String>> otaUrls = <String, List<String>>{};
  String otaLainnyaNama = '';

  /// Hanya relevan kalau ![isValid].
  final List<String> statusKetidaksesuaian = <String>[];
  String keteranganKetidaksesuaian = '';

  int statusPengawasan = 1;
  String keterangan = '';
  String catatanPetugas = '';
  DateTime tanggalPengawasan = DateTime.now();

  final List<XFile> photos = <XFile>[];

  Map<String, String> toFields() {
    final Map<String, String> fields = <String, String>{
      // --- WAJIB ditambahkan (belum ada di form Non-OSS) ---
      'nib': nib.trim(),
      'kbli': kbli.trim(),
      'nku': nku.trim(),
      if (kbliDesc.trim().isNotEmpty) 'kbli_desc': kbliDesc.trim(),

      // --- Sama seperti Non-OSS ---
      'nama_pemilik': namaPemilik.trim(),
      'nama_brand': namaBrand.trim(),
      'jenis_produk': jenisProduk.trim(),
      'alamat': alamat.trim(),
      'latitude': latitude.trim(),
      'longitude': longitude.trim(),
      'no_hp': noHp.trim(),
      'terdaftar_ota': terdaftarOta.trim().toUpperCase(),
      'status_pengawasan': statusPengawasan.toString(),
      'tanggal_pengawasan': _formatDate(tanggalPengawasan),
    };

    _addOptionalInt(fields, 'provinsi_id', provinsiId);
    _addOptionalInt(fields, 'kabupaten_id', kabupatenId);
    _addOptionalInt(fields, 'kecamatan_id', kecamatanId);
    _addOptionalInt(fields, 'kelurahan_id', kelurahanId);

    _addOptional(fields, 'npwpd', npwpd);
    _addOptional(fields, 'website', website);
    _addOptional(fields, 'email', email);
    _addOptional(fields, 'keterangan', keterangan);
    _addOptional(fields, 'catatan_petugas', catatanPetugas);

    // --- Hanya kalau data hasil validasi TIDAK VALID ---
    if (!isValid) {
      for (int i = 0; i < statusKetidaksesuaian.length; i++) {
        fields['status_ketidaksesuaian[$i]'] = statusKetidaksesuaian[i];
      }
      _addOptional(
        fields,
        'keterangan_ketidaksesuaian',
        keteranganKetidaksesuaian,
      );
    }

    if (terdaftarOta.trim().toUpperCase() == 'YA') {
      _addOtaFields(fields); // logic sama persis seperti NonOssFormData
    }

    return fields;
  }

  void _addOtaFields(Map<String, String> fields) {
    final List<MapEntry<String, List<String>>> selected = otaUrls.entries
        .where(
          (e) =>
              e.key.trim().isNotEmpty &&
              e.value.any((url) => url.trim().isNotEmpty),
        )
        .toList(growable: false);

    for (int i = 0; i < selected.length; i++) {
      final MapEntry<String, List<String>> entry = selected[i];
      final List<String> urls = entry.value
          .map((u) => u.trim())
          .where((u) => u.isNotEmpty)
          .toList(growable: false);

      fields['platform_ota[$i]'] = entry.key.trim();
      for (int j = 0; j < urls.length; j++) {
        fields['ota_urls[${entry.key.trim()}][$j]'] = urls[j];
      }
    }

    if (selected.any((e) => e.key.trim() == 'lainnya')) {
      _addOptional(fields, 'ota_lainnya_nama', otaLainnyaNama);
    }
  }

  void _addOptional(Map<String, String> fields, String key, String value) {
    final String clean = value.trim();
    if (clean.isNotEmpty) fields[key] = clean;
  }

  void _addOptionalInt(Map<String, String> fields, String key, int? value) {
    if (value != null) fields[key] = value.toString();
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String debugJson() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toFields());
  }
}
