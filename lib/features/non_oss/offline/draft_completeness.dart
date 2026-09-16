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

class DraftCompletenessChecker {
  DraftCompletenessChecker._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );

  /// List kosong berarti draft ini sudah lengkap dan valid seperti data
  /// biasa (user memilih simpan sebagai draft murni karena pilihannya
  /// sendiri, bukan karena data belum lengkap).
  static List<DraftMissingItem> check(
    Map<String, String> payload,
    List<String> photoPaths,
  ) {
    final List<DraftMissingItem> missing = <DraftMissingItem>[];

    String v(String key) => (payload[key] ?? '').trim();
    bool empty(String key) => v(key).isEmpty;

    // --- Identitas Usaha ---
    if (empty('nama_pemilik')) {
      missing.add(const DraftMissingItem('Identitas Usaha', 'Nama Pemilik'));
    }
    if (empty('nama_brand')) {
      missing.add(const DraftMissingItem('Identitas Usaha', 'Nama Brand'));
    }
    if (empty('jenis_produk')) {
      missing.add(const DraftMissingItem('Identitas Usaha', 'Jenis Produk'));
    }

    // --- Wilayah dan Alamat ---
    if (empty('provinsi_id')) {
      missing.add(const DraftMissingItem('Wilayah dan Alamat', 'Provinsi'));
    }
    if (empty('kabupaten_id')) {
      missing.add(
        const DraftMissingItem('Wilayah dan Alamat', 'Kabupaten/Kota'),
      );
    }
    if (empty('kecamatan_id')) {
      missing.add(const DraftMissingItem('Wilayah dan Alamat', 'Kecamatan'));
    }
    if (empty('kelurahan_id')) {
      missing.add(
        const DraftMissingItem('Wilayah dan Alamat', 'Kelurahan/Desa'),
      );
    }
    if (empty('alamat')) {
      missing.add(
        const DraftMissingItem('Wilayah dan Alamat', 'Alamat Lengkap'),
      );
    }

    // --- Lokasi dan Peta ---
    if (empty('latitude') || empty('longitude')) {
      missing.add(const DraftMissingItem('Lokasi dan Peta', 'Koordinat GPS'));
    }

    // --- Kontak dan Legalitas ---
    if (empty('no_hp')) {
      missing.add(
        const DraftMissingItem('Kontak dan Legalitas', 'Telepon/WhatsApp'),
      );
    } else {
      final int panjang = v('no_hp').length;
      if (panjang < 9 || panjang > 15) {
        missing.add(
          const DraftMissingItem(
            'Kontak dan Legalitas',
            'Format Telepon/WhatsApp (9-15 digit)',
          ),
        );
      }
    }
    if (!empty('website') && !_isValidUrl(v('website'))) {
      missing.add(
        const DraftMissingItem('Kontak dan Legalitas', 'Format Website'),
      );
    }
    if (!empty('email') && !_emailPattern.hasMatch(v('email'))) {
      missing.add(
        const DraftMissingItem('Kontak dan Legalitas', 'Format Email'),
      );
    }

    // --- Platform OTA ---
    if (v('terdaftar_ota') == 'YA') {
      final Map<String, List<String>> otaUrls = _parseOtaUrls(payload);
      final bool adaUrlTerisi = otaUrls.values.any(
        (List<String> urls) => urls.any((String u) => u.trim().isNotEmpty),
      );

      if (otaUrls.isEmpty || !adaUrlTerisi) {
        missing.add(const DraftMissingItem('Platform OTA', 'URL Listing OTA'));
      } else {
        final bool adaUrlTidakValid = otaUrls.values.any(
          (List<String> urls) => urls.any(
            (String u) => u.trim().isNotEmpty && !_isValidUrl(u.trim()),
          ),
        );
        if (adaUrlTidakValid) {
          missing.add(
            const DraftMissingItem('Platform OTA', 'Format URL OTA'),
          );
        }
      }
    }

    // --- Hasil Pengawasan ---
    final int status = int.tryParse(payload['status_pengawasan'] ?? '') ?? 0;
    if ((status == 3 || status == 8) && empty('keterangan')) {
      missing.add(const DraftMissingItem('Hasil Pengawasan', 'Keterangan'));
    }

    // --- Foto Dokumentasi ---
    if (photoPaths.isEmpty) {
      missing.add(
        const DraftMissingItem('Foto Dokumentasi', 'Minimal 1 Foto'),
      );
    }

    return missing;
  }

  static bool _isValidUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Map<String, List<String>> _parseOtaUrls(Map<String, String> payload) {
    final RegExp urlPattern = RegExp(r'^ota_urls\[([^\]]+)\]\[(\d+)\]$');
    final Map<String, Map<int, String>> byPlatform =
        <String, Map<int, String>>{};

    for (final MapEntry<String, String> entry in payload.entries) {
      final Match? match = urlPattern.firstMatch(entry.key);
      if (match != null) {
        final String platform = match.group(1)!;
        final int index = int.parse(match.group(2)!);
        byPlatform.putIfAbsent(
          platform,
          () => <int, String>{},
        )[index] = entry.value;
      }
    }

    return byPlatform.map((String platform, Map<int, String> urlMap) {
      final List<int> sortedKeys = urlMap.keys.toList()..sort();
      return MapEntry<String, List<String>>(
        platform,
        sortedKeys.map((int key) => urlMap[key]!).toList(),
      );
    });
  }
}