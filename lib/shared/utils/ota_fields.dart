import 'package:ipardasbor/core/constants/ota_platform_constants.dart';

/// Konversi `Map<String, List<String>>` (key platform -> URL) dari/ke field
/// payload multipart. Satu-satunya tempat format ini didefinisikan.
class OtaFields {
  const OtaFields._();

  static final RegExp _platformKey = RegExp(r'^platform_ota\[(\d+)\]$');
  static final RegExp _urlKey = RegExp(r'^ota_urls\[([^\]]+)\]\[(\d+)\]$');

  /// Platform yang key-nya tidak kosong dan punya minimal satu URL terisi,
  /// dengan URL sudah di-trim.
  static List<MapEntry<String, List<String>>> _terpilih(
    Map<String, List<String>> otaUrls,
  ) {
    final List<MapEntry<String, List<String>>> hasil =
        <MapEntry<String, List<String>>>[];
    for (final MapEntry<String, List<String>> e in otaUrls.entries) {
      final String key = e.key.trim();
      final List<String> urls = e.value
          .map((String u) => u.trim())
          .where((String u) => u.isNotEmpty)
          .toList(growable: false);
      if (key.isEmpty || urls.isEmpty) continue;
      hasil.add(MapEntry<String, List<String>>(key, urls));
    }
    return hasil;
  }

  /// Format Tahap 1 dan Non-OSS: `platform_ota[i]`, `ota_urls[key][j]`,
  /// dan `ota_lainnya_nama` (hanya kalau "lainnya" dipilih dan nama terisi).
  static void tulis(
    Map<String, String> fields,
    Map<String, List<String>> otaUrls, {
    String lainnyaNama = '',
  }) {
    final List<MapEntry<String, List<String>>> terpilih = _terpilih(otaUrls);

    for (int i = 0; i < terpilih.length; i++) {
      final MapEntry<String, List<String>> e = terpilih[i];
      fields['platform_ota[$i]'] = e.key;
      for (int j = 0; j < e.value.length; j++) {
        fields['ota_urls[${e.key}][$j]'] = e.value[j];
      }
    }

    if (terpilih.any(
      (MapEntry<String, List<String>> e) => e.key == OtaPlatform.lainnya,
    )) {
      final String nama = lainnyaNama.trim();
      if (nama.isNotEmpty) fields['ota_lainnya_nama'] = nama;
    }
  }

  /// Format akomodasi (backend B2): `<prefix>[ota][i][nama|url]`. `nama` =
  /// label baku, URL = URL pertama yang terisi (satu platform, satu URL).
  static void tulisAkomodasi(
    Map<String, String> fields,
    String prefix,
    Map<String, List<String>> otaUrls,
  ) {
    final List<MapEntry<String, List<String>>> terpilih = _terpilih(otaUrls);
    for (int i = 0; i < terpilih.length; i++) {
      fields['$prefix[ota][$i][nama]'] = OtaPlatform.labelDari(terpilih[i].key);
      fields['$prefix[ota][$i][url]'] = terpilih[i].value.first;
    }
  }

  /// Kebalikan dari [tulis]: baca payload tersimpan (draft/antrean offline)
  /// jadi map key platform -> daftar URL, urutan platform mengikuti indeks.
  static Map<String, List<String>> parse(Map<String, String> payload) {
    final Map<int, String> platformByIndex = <int, String>{};
    final Map<String, Map<int, String>> urlByPlatform =
        <String, Map<int, String>>{};

    for (final MapEntry<String, String> e in payload.entries) {
      final Match? p = _platformKey.firstMatch(e.key);
      if (p != null) {
        platformByIndex[int.parse(p.group(1)!)] = e.value;
        continue;
      }
      final Match? u = _urlKey.firstMatch(e.key);
      if (u != null) {
        urlByPlatform.putIfAbsent(
          u.group(1)!,
          () => <int, String>{},
        )[int.parse(u.group(2)!)] = e.value;
      }
    }

    List<String> urlsDari(String platform) {
      final Map<int, String> urlMap =
          urlByPlatform[platform] ?? <int, String>{};
      final List<int> urut = urlMap.keys.toList()..sort();
      return urut.map((int k) => urlMap[k]!).toList();
    }

    final Map<String, List<String>> hasil = <String, List<String>>{};

    // Urutan platform mengikuti indeks platform_ota[i].
    final List<int> indeks = platformByIndex.keys.toList()..sort();
    for (final int i in indeks) {
      final String platform = platformByIndex[i]!;
      hasil[platform] = urlsDari(platform);
    }

    // Cadangan: platform yang hanya punya ota_urls[...] tanpa platform_ota[i].
    for (final String platform in urlByPlatform.keys) {
      hasil.putIfAbsent(platform, () => urlsDari(platform));
    }
    return hasil;
  }
}
