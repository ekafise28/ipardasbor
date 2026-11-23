import 'dart:convert';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/features/pengawasan/riwayat/models/riwayat_detail.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/ota_utils.dart';
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

  /// Mode edit data server (Riwayat). null = bukan mode ini.
  int? riwayatId;

  /// updated_at yang dibaca saat detail dibuka; dikirim balik untuk
  /// deteksi konflik (server membalas 409 kalau sudah berbeda).
  String? versiServer;

  /// Foto yang sudah ada di server. Yang dihapus petugas dikeluarkan dari
  /// daftar ini dan id-nya dicatat di [fotoHapusIds].
  final List<({int id, String url})> fotoLama = <({int id, String url})>[];
  final List<int> fotoHapusIds = <int>[];

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

  /// Mengisi form dari detail Riwayat (mode edit data server).
  factory NonOssFormData.fromRiwayat(RiwayatDetail d) {
    final NonOssFormData form = NonOssFormData();

    form.riwayatId = d.id;
    form.versiServer = d.updatedAt?.toUtc().toIso8601String();
    form.bidang = d.bidangUsaha ?? 'akomodasi';
    form.memilikiNib = (d.memilikiNib ?? 'TIDAK').toUpperCase();

    form.namaPemilik = d.namaPemilik ?? '';
    form.namaBrand = d.namaBrand ?? '';
    form.jenisProduk = d.jenisProduk ?? '';

    form.provinsiId = d.wilayah.provinsiId;
    form.kabupatenId = d.wilayah.kabupatenId;
    form.kecamatanId = d.wilayah.kecamatanId;
    form.kelurahanId = d.wilayah.kelurahanId;

    form.alamat = d.alamat ?? '';
    form.latitude = d.latitude?.toStringAsFixed(8) ?? '';
    form.longitude = d.longitude?.toStringAsFixed(8) ?? '';

    form.npwpd = d.npwpd ?? '';
    form.website = d.website ?? '';
    form.noHp = d.noHp ?? '';
    form.email = d.email ?? '';

    form.terdaftarOta = (d.terdaftarOta ?? 'TIDAK').toUpperCase();
    for (final RiwayatDetailOta o in d.ota) {
      final String url = (o.urlListing ?? '').trim();
      if (url.isEmpty) continue;

      final String key = o.platformKey ?? OtaPlatform.lainnya;
      form.otaUrls.putIfAbsent(key, () => <String>[]).add(url);

      if (key == OtaPlatform.lainnya && form.otaLainnyaNama.isEmpty) {
        form.otaLainnyaNama = o.namaPlatform ?? '';
      }
    }

    form.statusKetidaksesuaian = List<String>.of(d.statusKetidaksesuaian);
    form.keterangan = d.keterangan ?? '';
    form.catatanPetugas = d.catatanPetugas ?? '';
    form.tanggalPengawasan = d.tanggalPengawasan ?? DateTime.now();

    for (final RiwayatDetailFoto f in d.foto) {
      if (f.url.isNotEmpty) form.fotoLama.add((id: f.id, url: f.url));
    }

    return form;
  }

  /// Field untuk POST edit. Field yang dikunci tidak dikirim; server tetap
  /// mengabaikannya kalau terkirim. Field opsional yang dikosongkan memang
  /// tidak ada di hasil toFields(), dan server menyimpannya sebagai null.
  Map<String, String> toUpdateFields() {
    final Map<String, String> fields = toFields();

    for (final String kunci in const <String>[
      'client_uuid',
      'memiliki_nib',
      'bidang_usaha',
      'tanggal_pengawasan',
      'baseline_ota_id',
    ]) {
      fields.remove(kunci);
    }

    fields['updated_at'] = versiServer ?? '';
    for (int i = 0; i < fotoHapusIds.length; i++) {
      fields['hapus_foto_ids[$i]'] = fotoHapusIds[i].toString();
    }
    return fields;
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
      'tanggal_pengawasan': formatTanggalApi(tanggalPengawasan),
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

  String debugJson() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toFields());
  }
}
