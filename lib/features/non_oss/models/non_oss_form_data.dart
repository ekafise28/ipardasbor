import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class NonOssFormData {
  String memilikiNib = 'TIDAK';

  String namaPemilik = '';
  String namaBrand = '';
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

  /// Key harus mengikuti API, misalnya booking_com, traveloka, dan lainnya.
  final Map<String, List<String>> otaUrls = <String, List<String>>{};

  String otaLainnyaNama = '';

  int statusPengawasan = 1;

  String keterangan = '';
  String catatanPetugas = '';

  DateTime tanggalPengawasan = DateTime.now();

  final List<XFile> photos = <XFile>[];

  /// Menghasilkan field multipart yang dapat langsung dikirim ke Laravel
  /// atau disimpan sebagai payload JSON di antrean SQLite.
  Map<String, String> toFields() {
    final Map<String, String> fields = <String, String>{
      'memiliki_nib': memilikiNib.trim().toUpperCase(),
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

    // Jangan mengirim teks "null". ID wilayah baru dimasukkan jika tersedia.
    _addOptionalInt(fields, 'provinsi_id', provinsiId);
    _addOptionalInt(fields, 'kabupaten_id', kabupatenId);
    _addOptionalInt(fields, 'kecamatan_id', kecamatanId);
    _addOptionalInt(fields, 'kelurahan_id', kelurahanId);

    _addOptional(fields, 'npwpd', npwpd);
    _addOptional(fields, 'website', website);
    _addOptional(fields, 'email', email);
    _addOptional(fields, 'keterangan', keterangan);
    _addOptional(fields, 'catatan_petugas', catatanPetugas);

    if (terdaftarOta.trim().toUpperCase() == 'YA') {
      _addOtaFields(fields);
    }

    return fields;
  }

  void _addOtaFields(Map<String, String> fields) {
    final List<MapEntry<String, List<String>>> selectedOta = otaUrls.entries
        .where((MapEntry<String, List<String>> entry) {
          final String platform = entry.key.trim();

          return platform.isNotEmpty &&
              entry.value.any((String url) => url.trim().isNotEmpty);
        })
        .toList(growable: false);

    for (int i = 0; i < selectedOta.length; i++) {
      final MapEntry<String, List<String>> entry = selectedOta[i];
      final String platform = entry.key.trim();
      final List<String> validUrls = entry.value
          .map((String url) => url.trim())
          .where((String url) => url.isNotEmpty)
          .toList(growable: false);

      fields['platform_ota[$i]'] = platform;

      for (int j = 0; j < validUrls.length; j++) {
        fields['ota_urls[$platform][$j]'] = validUrls[j];
      }
    }

    // API mewajibkan nama ini jika platform "lainnya" dipilih.
    if (selectedOta.any(
      (MapEntry<String, List<String>> entry) => entry.key.trim() == 'lainnya',
    )) {
      _addOptional(fields, 'ota_lainnya_nama', otaLainnyaNama);
    }
  }

  void _addOptional(Map<String, String> fields, String key, String value) {
    final String cleanValue = value.trim();

    if (cleanValue.isNotEmpty) {
      fields[key] = cleanValue;
    }
  }

  void _addOptionalInt(Map<String, String> fields, String key, int? value) {
    if (value != null) {
      fields[key] = value.toString();
    }
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String debugJson() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toFields());
  }
}
