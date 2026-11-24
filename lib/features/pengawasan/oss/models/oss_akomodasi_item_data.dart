// lib/features/pengawasan/oss/models/oss_akomodasi_item_data.dart
import 'package:image_picker/image_picker.dart';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/features/pengawasan/riwayat/models/riwayat_detail.dart';
import 'package:ipardasbor/shared/utils/ota_utils.dart';

/// Status live-check NIB/KBLI/NKU satu kartu akomodasi (dipanggil ke
/// endpoint /mobile/oss/validasi-akomodasi - lihat AkomodasiService).
/// Hasil ini HANYA untuk feedback UI; backend selalu memvalidasi ulang
/// saat submit final.
enum AkomodasiValidasiStatus {
  belumDicek,
  sedangMemeriksa,
  valid,
  tidakValid,
  gagalKoneksi,
}

/// Data satu kartu akomodasi pada Tahap 2 - Akomodasi yang Dikelola.
/// Field mengikuti kolom `tbl_oss_pengawasan_akomodasi`, ditambah state
/// lokal untuk UI (foto belum di-upload, status live-check, dsb).
///
/// Mode edit: item lama punya [id] (dari server) dan identitas NIB-nya
/// [terkunci]. Item baru yang ditambah saat edit tidak punya [id].
class AkomodasiItemData {
  AkomodasiItemData();

  /// Membangun item dari detail Riwayat (mode edit).
  factory AkomodasiItemData.fromDetail(RiwayatDetailAkomodasi d) {
    final AkomodasiItemData item = AkomodasiItemData();

    item.id = d.id;
    item.memilikiNib = d.memilikiNib;
    item.nib = d.nib ?? '';
    item.kbli = d.kbli ?? '';
    item.nku = d.nku ?? '';

    // Hasil validasi tersimpan dipakai langsung, jadi item lama tidak
    // diminta "Cek Validasi" lagi. Hanya relevan kalau punya NIB.
    if (item.memilikiNibYa && d.hasilValidasi != null) {
      final bool valid = d.hasilValidasi == 'VALID';
      item.tandaiSudahDicek(
        valid: valid,
        pesan: d.pesanValidasi ?? (valid ? 'Data valid.' : 'Data tidak valid.'),
      );
    }

    item.namaPemilik = d.namaPemilik;
    item.namaBrand = d.namaBrand;
    item.jenisProduk = d.jenisProduk;

    item.provinsiId = d.wilayah.provinsiId;
    item.kabupatenId = d.wilayah.kabupatenId;
    item.kecamatanId = d.wilayah.kecamatanId;
    item.kelurahanId = d.wilayah.kelurahanId;

    item.alamat = d.alamat;
    item.latitude = d.latitude?.toStringAsFixed(8) ?? '';
    item.longitude = d.longitude?.toStringAsFixed(8) ?? '';

    item.npwpd = d.npwpd ?? '';
    item.website = d.website ?? '';
    item.noHp = d.noHp;
    item.email = d.email;

    item.terdaftarOta = d.terdaftarOta.toUpperCase();
    for (final RiwayatDetailOta o in d.ota) {
      final String url = (o.urlListing ?? '').trim();
      if (url.isEmpty) continue;
      final String key = o.platformKey ?? OtaPlatform.lainnya;
      item.otaUrls.putIfAbsent(key, () => <String>[]).add(url);
    }

    item.statusKetidaksesuaian.addAll(d.statusKetidaksesuaian);
    item.keteranganKetidaksesuaian = d.keteranganKetidaksesuaian ?? '';

    for (final RiwayatDetailFoto f in d.foto) {
      if (f.url.isNotEmpty) item.fotoLama.add((id: f.id, url: f.url));
    }

    return item;
  }

  // --- Mode edit ---

  /// ID baris di server. null = item baru (belum ada di server).
  int? id;

  /// NIB/KBLI/NKU/Kepemilikan NIB item yang sudah ada di server tidak
  /// boleh diubah. Salah ketik? Hapus item lalu tambah item baru.
  bool get terkunci => id != null;

  /// Foto yang sudah ada di server. Yang dihapus petugas dikeluarkan dari
  /// daftar ini dan id-nya dicatat di [fotoHapusIds].
  final List<({int id, String url})> fotoLama = <({int id, String url})>[];
  final List<int> fotoHapusIds = <int>[];

  // --- Kepemilikan NIB ---
  /// 'YA' | 'TIDAK' | 'TIDAK TAHU'
  String memilikiNib = 'YA';

  String nib = '';
  String kbli = '';

  /// NKU tanpa prefix R- (prefix ditambahkan di backend).
  String nku = '';

  // --- Hasil live-check terakhir ---
  AkomodasiValidasiStatus validasiStatus = AkomodasiValidasiStatus.belumDicek;
  String? pesanValidasiTerakhir;

  /// NIB/KBLI/NKU yang terakhir kali berhasil dicek. Kalau salah satunya
  /// berubah setelah cek, [validasiStatus] direset ke belumDicek.
  String? _kombinasiTerakhirDicek;

  bool get sudahDicekUntukNilaiSaatIni =>
      _kombinasiTerakhirDicek == '$nib|$kbli|$nku';

  void tandaiSudahDicek({required bool valid, required String pesan}) {
    _kombinasiTerakhirDicek = '$nib|$kbli|$nku';
    validasiStatus = valid
        ? AkomodasiValidasiStatus.valid
        : AkomodasiValidasiStatus.tidakValid;
    pesanValidasiTerakhir = pesan;
  }

  /// Dipanggil setiap kali nib/kbli/nku diubah user, supaya status
  /// live-check yang lama tidak menyesatkan.
  void resetStatusValidasi() {
    if (!sudahDicekUntukNilaiSaatIni) {
      validasiStatus = AkomodasiValidasiStatus.belumDicek;
    }
  }

  // --- Identitas usaha akomodasi ---
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

  // --- OTA per item ---
  String terdaftarOta = 'TIDAK';
  final Map<String, List<String>> otaUrls = <String, List<String>>{};

  // --- Hanya relevan kalau memilikiNib == 'TIDAK'/'TIDAK TAHU', atau hasil
  // live-check TIDAK_VALID. ---
  final List<String> statusKetidaksesuaian = <String>[];
  String keteranganKetidaksesuaian = '';

  // --- Foto baru per item (belum di-upload) ---
  final List<XFile> photos = <XFile>[];

  bool get memilikiNibYa => memilikiNib == 'YA';

  /// Jumlah foto efektif: sisa foto lama + foto baru.
  int get jumlahFoto => fotoLama.length + photos.length;

  /// Validasi kelengkapan minimal SEBELUM dikirim ke server (bukan
  /// pengganti validasi backend).
  bool get lengkapUntukDisimpan {
    final bool identitasDasarLengkap =
        namaPemilik.trim().isNotEmpty &&
        namaBrand.trim().isNotEmpty &&
        jenisProduk.trim().isNotEmpty &&
        provinsiId != null &&
        kabupatenId != null &&
        kecamatanId != null &&
        kelurahanId != null &&
        alamat.trim().isNotEmpty &&
        latitude.trim().isNotEmpty &&
        longitude.trim().isNotEmpty &&
        noHp.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        jumlahFoto > 0;

    if (!identitasDasarLengkap) return false;

    if (terdaftarOtaYa &&
        (OtaUrlRules.belumLengkap(otaUrls) ||
            OtaUrlRules.adaUrlTidakValid(otaUrls))) {
      return false;
    }

    // Status "Lainnya" wajib disertai keterangan (sama seperti backend).
    if (statusKetidaksesuaian.contains('LAINNYA') &&
        keteranganKetidaksesuaian.trim().isEmpty) {
      return false;
    }

    if (memilikiNibYa) {
      final bool nibLengkap =
          nib.trim().isNotEmpty &&
          kbli.trim().isNotEmpty &&
          nku.trim().isNotEmpty;
      final bool sudahDicekValid =
          sudahDicekUntukNilaiSaatIni &&
          validasiStatus != AkomodasiValidasiStatus.belumDicek &&
          validasiStatus != AkomodasiValidasiStatus.sedangMemeriksa;

      if (!(nibLengkap && sudahDicekValid)) return false;

      // Hasil cek tidak valid: backend mewajibkan minimal satu status.
      if (validasiStatus == AkomodasiValidasiStatus.tidakValid) {
        return statusKetidaksesuaian.isNotEmpty;
      }
      return true;
    }

    // TIDAK / TIDAK TAHU - wajib pilih minimal satu status.
    return statusKetidaksesuaian.isNotEmpty;
  }

  bool get terdaftarOtaYa => terdaftarOta.trim().toUpperCase() == 'YA';

  /// Encode ke field multipart bracket-notation `akomodasi[index][...]`,
  /// sesuai rules validasi di MobileOssPengawasanController::storeAkomodasi.
  Map<String, String> toFields(int index) {
    final String p = 'akomodasi[$index]';
    final Map<String, String> fields = <String, String>{
      '$p[memiliki_nib]': memilikiNib,
      '$p[nama_pemilik]': namaPemilik.trim(),
      '$p[nama_brand]': namaBrand.trim(),
      '$p[jenis_produk]': jenisProduk.trim(),
      '$p[alamat]': alamat.trim(),
      '$p[latitude]': latitude.trim(),
      '$p[longitude]': longitude.trim(),
      '$p[no_hp]': noHp.trim(),
      '$p[terdaftar_ota]': terdaftarOta.trim().toUpperCase(),
    };

    if (provinsiId != null) fields['$p[provinsi_id]'] = provinsiId.toString();
    if (kabupatenId != null) {
      fields['$p[kabupaten_id]'] = kabupatenId.toString();
    }
    if (kecamatanId != null) {
      fields['$p[kecamatan_id]'] = kecamatanId.toString();
    }
    if (kelurahanId != null) {
      fields['$p[kelurahan_id]'] = kelurahanId.toString();
    }

    if (npwpd.trim().isNotEmpty) fields['$p[npwpd]'] = npwpd.trim();
    if (website.trim().isNotEmpty) fields['$p[website]'] = website.trim();
    if (email.trim().isNotEmpty) fields['$p[email]'] = email.trim();

    if (memilikiNibYa) {
      fields['$p[nib]'] = nib.trim();
      fields['$p[kbli]'] = kbli.trim();
      fields['$p[nku]'] = nku.trim();
    }

    if (statusKetidaksesuaian.isNotEmpty) {
      for (int i = 0; i < statusKetidaksesuaian.length; i++) {
        fields['$p[status_ketidaksesuaian][$i]'] = statusKetidaksesuaian[i];
      }
      if (keteranganKetidaksesuaian.trim().isNotEmpty) {
        fields['$p[keterangan_ketidaksesuaian]'] = keteranganKetidaksesuaian
            .trim();
      }
    }

    if (terdaftarOtaYa) {
      OtaFields.tulisAkomodasi(fields, p, otaUrls);
    }

    return fields;
  }

  /// Field untuk POST edit. Item lama: kirim [id], dan buang field yang
  /// terkunci (server juga mengabaikannya). Item baru: tanpa id, field
  /// lengkap seperti saat simpan awal.
  Map<String, String> toUpdateFields(int index) {
    final String p = 'akomodasi[$index]';
    final Map<String, String> fields = toFields(index);

    if (id != null) {
      fields['$p[id]'] = id.toString();
      for (final String kunci in const <String>[
        'memiliki_nib',
        'nib',
        'kbli',
        'nku',
      ]) {
        fields.remove('$p[$kunci]');
      }
    }

    for (int i = 0; i < fotoHapusIds.length; i++) {
      fields['$p[hapus_foto_ids][$i]'] = fotoHapusIds[i].toString();
    }

    return fields;
  }
}