import 'dart:convert';
import 'package:ipardasbor/shared/utils/ota_fields.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../offline/non_oss_local_data.dart';

class NonOssFormData {
  NonOssFormData();

  /// Slug bidang usaha (key config bidang_usaha_pariwisata). Draft/antrean
  /// lama tanpa nilai ini dianggap akomodasi.
  String bidang = 'akomodasi';

  /// ID unik data ini, dibuat SEKALI saat form dibuat dan dipakai ulang di
  /// pengiriman langsung maupun antrean offline. Server memakainya untuk
  /// menolak duplikat (kolom kode_validasi). Mode edit memakai UUID milik
  /// data yang diedit (lihat fromLocalData).
  String clientUuid = const Uuid().v4();

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

  /// ID baris tbl_oss_baseline_ota yang sedang diverifikasi, kalau form ini
  /// dibuka dari alur Pengawasan OTA (BaselineOtaPage). null untuk
  /// pengisian Non-OSS biasa.
  int? baselineOtaId;
  String website = '';
  String noHp = '';
  String email = '';

  String terdaftarOta = 'TIDAK';

  /// Key harus mengikuti API, misalnya booking_com, traveloka, dan lainnya.
  final Map<String, List<String>> otaUrls = <String, List<String>>{};

  String otaLainnyaNama = '';

  /// Kode status hasil pengawasan, mengikuti kondisi memilikiNib:
  /// - 'TIDAK'      -> selalu ['NIB_TIDAK_DITEMUKAN'] (diisi otomatis di UI)
  /// - 'TIDAK TAHU' -> checkbox: TIDAK_BERTEMU_PEMILIK,
  ///                   PENGELOLA_TIDAK_BISA_MEMBERIKAN_DATA, LAINNYA
  List<String> statusKetidaksesuaian = <String>[];

  String keterangan = '';
  String catatanPetugas = '';

  DateTime tanggalPengawasan = DateTime.now();

  final List<XFile> photos = <XFile>[];

  static List<String> _parseStatusKetidaksesuaian(Map<String, String> payload) {
    final RegExp pattern = RegExp(r'^status_ketidaksesuaian\[(\d+)\]$');
    final Map<int, String> byIndex = <int, String>{};

    for (final MapEntry<String, String> entry in payload.entries) {
      final Match? match = pattern.firstMatch(entry.key);
      if (match != null) {
        byIndex[int.parse(match.group(1)!)] = entry.value;
      }
    }

    final List<int> sortedKeys = byIndex.keys.toList()..sort();
    return sortedKeys.map((int key) => byIndex[key]!).toList();
  }

  /// Membangun ulang [NonOssFormData] dari data yang tersimpan di antrean
  /// lokal, untuk keperluan mode edit. Kebalikan dari [toFields].
  factory NonOssFormData.fromLocalData(NonOssLocalData data) {
    final NonOssFormData form = NonOssFormData();
    final Map<String, String> payload = data.payload;

    form.clientUuid = data.clientUuid;
    form.memilikiNib = payload['memiliki_nib'] ?? 'TIDAK';
    form.bidang = payload['bidang_usaha'] ?? 'akomodasi';
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

    form.statusKetidaksesuaian = _parseStatusKetidaksesuaian(payload);

    form.keterangan = payload['keterangan'] ?? '';
    form.catatanPetugas = payload['catatan_petugas'] ?? '';
    form.baselineOtaId = int.tryParse(payload['baseline_ota_id'] ?? '');

    final String? tanggalMentah = payload['tanggal_pengawasan'];
    if (tanggalMentah != null && tanggalMentah.isNotEmpty) {
      form.tanggalPengawasan =
          DateTime.tryParse(tanggalMentah) ?? DateTime.now();
    }

    // Susun ulang platform_ota[i] & ota_urls[platform][j] menjadi
    // Map<String, List<String>> seperti bentuk asalnya di form.
    form.otaUrls
      ..clear()
      ..addAll(OtaFields.parse(payload));

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
      'bidang_usaha': bidang,
      'client_uuid': clientUuid,
      'nama_pemilik': namaPemilik.trim(),
      'nama_brand': namaBrand.trim(),
      'jenis_produk': jenisProduk.trim(),
      'alamat': alamat.trim(),
      'latitude': latitude.trim(),
      'longitude': longitude.trim(),
      'no_hp': noHp.trim(),
      'terdaftar_ota': terdaftarOta.trim().toUpperCase(),
      'tanggal_pengawasan': _formatDate(tanggalPengawasan),
    };

    _addStatusKetidaksesuaianFields(fields);

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
    if (baselineOtaId != null) {
      fields['baseline_ota_id'] = baselineOtaId.toString();
    }

    return fields;
  }

  void _addStatusKetidaksesuaianFields(Map<String, String> fields) {
    // Untuk 'TIDAK', status selalu tetap dan otomatis (tidak ada pilihan
    // di UI), jadi diisi langsung di sini - tidak bergantung pada apakah
    // sempat tersimpan di _data.statusKetidaksesuaian atau tidak.
    final List<String> efektif = memilikiNib.trim().toUpperCase() == 'TIDAK'
        ? const <String>['NIB_TIDAK_DITEMUKAN']
        : statusKetidaksesuaian
              .map((String kode) => kode.trim())
              .where((String kode) => kode.isNotEmpty)
              .toList(growable: false);

    for (int i = 0; i < efektif.length; i++) {
      fields['status_ketidaksesuaian[$i]'] = efektif[i];
    }
  }

  void _addOtaFields(Map<String, String> fields) =>
      OtaFields.tulis(fields, otaUrls, lainnyaNama: otaLainnyaNama);

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
