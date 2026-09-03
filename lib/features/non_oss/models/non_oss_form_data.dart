import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import '../offline/non_oss_local_data.dart';

class NonOssFormData {
  NonOssFormData();
  
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

  /// Membangun ulang [NonOssFormData] dari data yang tersimpan di antrean
  /// lokal, untuk keperluan mode edit. Kebalikan dari [toFields].
  factory NonOssFormData.fromLocalData(NonOssLocalData data) {
    final NonOssFormData form = NonOssFormData();
    final Map<String, String> payload = data.payload;

    form.memilikiNib = payload['memiliki_nib'] ?? 'TIDAK';
    form.namaPemilik = payload['nama_pemilik'] ?? '';
    form.namaBrand = payload['nama_brand'] ?? '';
    form.jenisProduk = payload['jenis_produk'] ?? '';

    form.provinsiId = int.tryParse(payload['provinsi_id'] ?? '');
    form.kabupatenId = int.tryParse(payload['kabupaten_id'] ?? '');
    form.kecamatanId = int.tryParse(payload['kecamatan_id'] ?? '');
    form.kelurahanId = int.tryParse(payload['kelurahan_id'] ?? '');

    form.alamat = payload['alamat'] ?? '';
    form.latitude = payload['latitude'] ?? '';
    form.longitude = payload['longitude'] ?? '';

    form.npwpd = payload['npwpd'] ?? '';
    form.website = payload['website'] ?? '';
    form.noHp = payload['no_hp'] ?? '';
    form.email = payload['email'] ?? '';

    form.terdaftarOta = payload['terdaftar_ota'] ?? 'TIDAK';
    form.otaLainnyaNama = payload['ota_lainnya_nama'] ?? '';

    form.statusPengawasan =
        int.tryParse(payload['status_pengawasan'] ?? '') ?? 1;

    form.keterangan = payload['keterangan'] ?? '';
    form.catatanPetugas = payload['catatan_petugas'] ?? '';

    final String? tanggalMentah = payload['tanggal_pengawasan'];
    if (tanggalMentah != null && tanggalMentah.isNotEmpty) {
      form.tanggalPengawasan =
          DateTime.tryParse(tanggalMentah) ?? DateTime.now();
    }

    // Susun ulang platform_ota[i] & ota_urls[platform][j] menjadi
    // Map<String, List<String>> seperti bentuk asalnya di form.
    final RegExp platformPattern = RegExp(r'^platform_ota\[(\d+)\]$');
    final RegExp urlPattern = RegExp(r'^ota_urls\[([^\]]+)\]\[(\d+)\]$');

    final Map<int, String> platformByIndex = <int, String>{};
    for (final MapEntry<String, String> entry in payload.entries) {
      final Match? match = platformPattern.firstMatch(entry.key);
      if (match != null) {
        platformByIndex[int.parse(match.group(1)!)] = entry.value;
      }
    }

    final Map<String, Map<int, String>> urlByPlatform =
        <String, Map<int, String>>{};
    for (final MapEntry<String, String> entry in payload.entries) {
      final Match? match = urlPattern.firstMatch(entry.key);
      if (match != null) {
        final String platform = match.group(1)!;
        final int urlIndex = int.parse(match.group(2)!);
        urlByPlatform.putIfAbsent(platform, () => <int, String>{})[urlIndex] =
            entry.value;
      }
    }

    for (final String platform in platformByIndex.values) {
      final Map<int, String> urlMap =
          urlByPlatform[platform] ?? <int, String>{};
      final List<int> sortedKeys = urlMap.keys.toList()..sort();
      form.otaUrls[platform] = sortedKeys
          .map((int key) => urlMap[key]!)
          .toList();
    }

    // Bungkus path foto permanen sebagai XFile supaya PhotoPicker bisa
    // menampilkan foto lama seolah baru saja dipilih.
    form.photos.addAll(data.photoPaths.map((String path) => XFile(path)));

    return form;
  }

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
