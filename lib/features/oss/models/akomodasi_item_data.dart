// lib/features/oss/models/akomodasi_item_data.dart
import 'package:image_picker/image_picker.dart';
import 'package:ipardasbor/features/oss/widgets/ota_platform_selector.dart';

/// Status live-check NIB/KBLI/NKU satu kartu akomodasi (dipanggil ke
/// endpoint /mobile/oss/validasi-akomodasi - lihat AkomodasiService).
/// Hasil ini HANYA untuk feedback UI; backend selalu memvalidasi ulang
/// saat submit final (lihat catatan di OssPengawasanController::
/// mobileStorePengawasanAkomodasi).
enum AkomodasiValidasiStatus {
  belumDicek,
  sedangMemeriksa,
  valid,
  tidakValid,
  gagalKoneksi,
}

/// Data satu kartu akomodasi pada Tahap 2 - Akomodasi yang Dikelola.
/// Field mengikuti kolom `tbl_oss_pengawasan_akomodasi` (lihat model
/// Laravel OssPengawasanAkomodasi), ditambah state lokal untuk UI
/// (foto belum di-upload, status live-check, dsb).
class AkomodasiItemData {
  AkomodasiItemData();

  // --- Kepemilikan NIB ---
  /// 'YA' | 'TIDAK' | 'TIDAK TAHU'
  String memilikiNib = 'YA';

  String nib = '';
  String kbli = '';

  /// NKU tanpa prefix R- (sama seperti [OssFormData], prefix ditambahkan
  /// di backend).
  String nku = '';

  // --- Hasil live-check terakhir (lihat AkomodasiValidasiStatus) ---
  AkomodasiValidasiStatus validasiStatus = AkomodasiValidasiStatus.belumDicek;
  String? pesanValidasiTerakhir;

  /// NIB/KBLI/NKU yang terakhir kali berhasil dicek. Dipakai untuk
  /// mendeteksi kalau user mengubah salah satu field ini setelah cek -
  /// kalau berubah, [validasiStatus] harus direset ke belumDicek supaya
  /// user diminta cek ulang sebelum submit.
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

  /// Dipanggil setiap kali nib/kbli/nku diubah user, supaya status live-check
  /// yang lama tidak menyesatkan (form harus tahu ini "belum dicek lagi").
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

  // --- OTA sendiri per item, struktur sama dengan OssFormData.otaUrls
  // supaya OtaPlatformSelector bisa dipakai ulang tanpa modifikasi. ---
  String terdaftarOta = 'TIDAK';
  final Map<String, List<String>> otaUrls = <String, List<String>>{};

  // --- Hanya relevan kalau memilikiNib == 'TIDAK TAHU', atau hasil
  // live-check TIDAK_VALID. ---
  final List<String> statusKetidaksesuaian = <String>[];
  String keteranganKetidaksesuaian = '';

  // --- Foto sendiri per item ---
  final List<XFile> photos = <XFile>[];

  bool get memilikiNibYa => memilikiNib == 'YA';

  /// Validasi kelengkapan minimal SEBELUM dikirim ke server (bukan
  /// pengganti validasi backend - hanya mencegah request yang pasti
  /// gagal supaya user tidak nunggu round-trip sia-sia).
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
        photos.isNotEmpty;

    if (!identitasDasarLengkap) return false;

    if (memilikiNibYa) {
      final bool nibLengkap =
          nib.trim().isNotEmpty &&
          kbli.trim().isNotEmpty &&
          nku.trim().isNotEmpty;
      final bool sudahDicekValid =
          sudahDicekUntukNilaiSaatIni &&
          validasiStatus != AkomodasiValidasiStatus.belumDicek &&
          validasiStatus != AkomodasiValidasiStatus.sedangMemeriksa;
      return nibLengkap && sudahDicekValid;
    }

    // TIDAK / TIDAK TAHU - wajib pilih minimal satu status.
    return statusKetidaksesuaian.isNotEmpty;
  }

  bool get terdaftarOtaYa => terdaftarOta.trim().toUpperCase() == 'YA';

  /// Encode ke field multipart bracket-notation `akomodasi[index][...]`,
  /// sesuai rules validasi di OssPengawasanController::
  /// mobileStorePengawasanAkomodasi (backend B2).
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
    if (kabupatenId != null)
      fields['$p[kabupaten_id]'] = kabupatenId.toString();
    if (kecamatanId != null)
      fields['$p[kecamatan_id]'] = kecamatanId.toString();
    if (kelurahanId != null)
      fields['$p[kelurahan_id]'] = kelurahanId.toString();

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
      final List<MapEntry<String, List<String>>> selected = otaUrls.entries
          .where(
            (e) =>
                e.key.trim().isNotEmpty &&
                e.value.any((u) => u.trim().isNotEmpty),
          )
          .toList(growable: false);

      for (int i = 0; i < selected.length; i++) {
        final String url = selected[i].value.firstWhere(
          (u) => u.trim().isNotEmpty,
          orElse: () => '',
        );
        // 'nama' dikirim sebagai label manusiawi (bukan key mentah seperti
        // 'booking_com'), karena backend B2 langsung menyimpan string ini
        // apa adanya ke kolom nama_platform (tidak ada tabel terjemahan
        // key->label seperti $platformMap di mobileStorePengawasanOss).
        fields['$p[ota][$i][nama]'] =
            OtaPlatformSelector.platforms[selected[i].key] ?? selected[i].key;
        fields['$p[ota][$i][url]'] = url.trim();
      }
    }

    return fields;
  }
}
