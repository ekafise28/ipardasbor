import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/shared/utils/form_validators.dart';
import 'package:ipardasbor/shared/utils/ota_utils.dart';

/// Menentukan bagian form mana yang masih kosong/tidak valid pada sebuah
/// draft, berdasarkan payload mentah yang tersimpan di antrean lokal.
///
/// SENGAJA dipisah dari `_buildChecks` di `NonOssFormPage`: halaman yang
/// menampilkan draft (Sinkronisasi, Detail Ajuan) hanya punya
/// `Map<String, String>` payload, bukan objek `NonOssFormData` yang sudah
/// di-parse. Kalau aturan wajib-isi di `NonOssFormPage` berubah, checklist
/// ini juga perlu disesuaikan manual.
class DraftMissingItem {
  const DraftMissingItem(this.section, this.label);

  final String section;
  final String label;
}

/// Status satu bagian form (satu section) pada sebuah draft.
class DraftModule {
  const DraftModule({
    required this.title,
    required this.missing,
    this.completeNote,
  });

  /// Nama bagian, sama dengan judul section di form.
  final String title;

  /// Label field yang masih kurang. Kosong berarti bagian ini lengkap.
  final List<String> missing;

  /// Keterangan singkat saat bagian ini lengkap (opsional), misalnya
  /// "Tidak berlaku" untuk Platform OTA pada usaha yang tidak terdaftar.
  final String? completeNote;

  bool get isComplete => missing.isEmpty;
}

class DraftCompletenessChecker {
  DraftCompletenessChecker._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );

  /// Daftar kekurangan, dikelompokkan per section. Bersumber dari
  /// [checkModules] supaya aturan wajib-isi hanya ada di satu tempat.
  ///
  /// List kosong berarti draft ini sudah lengkap dan valid seperti data
  /// biasa (user memilih simpan sebagai draft murni karena pilihannya
  /// sendiri, bukan karena data belum lengkap).
  static List<DraftMissingItem> check(
    Map<String, String> payload,
    List<String> photoPaths,
  ) {
    return <DraftMissingItem>[
      for (final DraftModule module in checkModules(payload, photoPaths))
        for (final String label in module.missing)
          DraftMissingItem(module.title, label),
    ];
  }

  /// Status SEMUA bagian form (selalu 7 bagian, urutan sama dengan form),
  /// baik yang sudah lengkap maupun yang belum.
  static List<DraftModule> checkModules(
    Map<String, String> payload,
    List<String> photoPaths,
  ) {
    String v(String key) => (payload[key] ?? '').trim();
    bool empty(String key) => v(key).isEmpty;

    // --- Identitas Usaha ---
    final List<String> identitas = <String>[
      if (empty('nama_pemilik')) 'Nama Pemilik',
      if (empty('nama_brand')) 'Nama Brand',
      if (empty('jenis_produk')) 'Jenis Produk',
    ];

    // --- Wilayah dan Alamat ---
    final List<String> wilayah = <String>[
      if (empty('provinsi_id')) 'Provinsi',
      if (empty('kabupaten_id')) 'Kabupaten/Kota',
      if (empty('kecamatan_id')) 'Kecamatan',
      if (empty('kelurahan_id')) 'Kelurahan/Desa',
      if (empty('alamat')) 'Alamat Lengkap',
    ];

    // --- Lokasi dan Peta ---
    final List<String> lokasi = <String>[
      if (empty('latitude') || empty('longitude')) 'Koordinat GPS',
    ];

    // --- Kontak dan Legalitas ---
    final List<String> kontak = <String>[];
    if (empty('no_hp')) {
      kontak.add('Telepon/WhatsApp');
    } else if (FormValidators.phone(v('no_hp')) != null) {
      kontak.add('Format Telepon/WhatsApp (10-15 digit)');
    }
    if (!empty('website') && !_isValidUrl(v('website'))) {
      kontak.add('Format Website');
    }
    if (empty('email')) {
      kontak.add('Email');
    } else if (!_emailPattern.hasMatch(v('email'))) {
      kontak.add('Format Email');
    }

    // --- Platform OTA ---
    final bool terdaftarOta = v('terdaftar_ota') == 'YA';
    final List<String> ota = <String>[];
    if (terdaftarOta) {
      final Map<String, List<String>> otaUrls = OtaFields.parse(payload);

      if (OtaUrlRules.belumLengkap(otaUrls)) {
        ota.add('URL Listing OTA');
      } else if (OtaUrlRules.adaUrlTidakValid(otaUrls)) {
        ota.add('Format URL OTA');
      }
      if (otaUrls.containsKey(OtaPlatform.lainnya) &&
          empty('ota_lainnya_nama')) {
        ota.add('Nama Platform Lainnya');
      }
    }

    // --- Hasil Pengawasan ---
    // Mengikuti `_buildChecks` di NonOssFormPage: status hanya dipilih
    // petugas saat NIB "TIDAK TAHU"; untuk "TIDAK" statusnya otomatis.
    final List<String> statusDipilih = <String>[
      for (final MapEntry<String, String> entry in payload.entries)
        if (entry.key.startsWith('status_ketidaksesuaian[') &&
            entry.value.trim().isNotEmpty)
          entry.value.trim(),
    ];
    final List<String> hasil = <String>[];
    if (v('memiliki_nib') == 'TIDAK TAHU') {
      if (statusDipilih.isEmpty) {
        hasil.add('Status Hasil Pengawasan');
      }
      if (statusDipilih.contains('LAINNYA') && empty('keterangan')) {
        hasil.add('Keterangan Status Lainnya');
      }
    }

    // --- Foto Dokumentasi ---
    final List<String> foto = <String>[
      if (photoPaths.isEmpty) 'Minimal 1 Foto',
    ];

    return <DraftModule>[
      DraftModule(title: 'Identitas Usaha', missing: identitas),
      DraftModule(title: 'Wilayah dan Alamat', missing: wilayah),
      DraftModule(title: 'Lokasi dan Peta', missing: lokasi),
      DraftModule(title: 'Kontak dan Legalitas', missing: kontak),
      DraftModule(
        title: 'Platform OTA',
        missing: ota,
        completeNote: terdaftarOta ? null : 'Tidak berlaku (tidak terdaftar OTA)',
      ),
      DraftModule(title: 'Hasil Pengawasan', missing: hasil),
      DraftModule(title: 'Foto Dokumentasi', missing: foto),
    ];
  }

  static bool _isValidUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}