import 'package:flutter/painting.dart' show Color;

/// Daftar platform OTA. Key = nilai yang dikirim ke API, label = nama tampilan.
///
/// Label HARUS sama persis dengan `$platformMap` di OssPengawasanController
/// (backend), karena `nama_platform` dipakai untuk pengelompokan laporan.
class OtaPlatform {
  const OtaPlatform._();

  static const String lainnya = 'lainnya';

  static const Map<String, String> labels = <String, String>{
    'booking_com': 'Booking.com',
    'tiket_com': 'Tiket.com',
    'oyo': 'OYO',
    'agoda': 'Agoda',
    'traveloka': 'Traveloka',
    'expedia': 'Expedia',
    'trip_com': 'Trip.com',
    'reddoorz': 'RedDoorz',
    'airbnb': 'Airbnb',
    'lainnya': 'Lainnya',
  };

  /// Label baku untuk key; key tak dikenal dikembalikan apa adanya.
  static String labelDari(String key) => labels[key.trim()] ?? key;

  /// Untuk tampilan: "Lainnya" memakai nama yang diketik petugas (kalau ada).
  static String labelTampil(String key, {String lainnyaNama = ''}) {
    if (key.trim() == lainnya && lainnyaNama.trim().isNotEmpty) {
      return lainnyaNama.trim();
    }
    return labelDari(key);
  }

  /// Warna identitas tiap OTA, dicocokkan dari nama platform (huruf kecil,
  /// memuat kata kuncinya). Urutan penting: yang pertama cocok dipakai.
  static const List<(String, Color)> _warnaMerek = <(String, Color)>[
    ('booking', Color(0xFF003B95)),
    ('agoda', Color(0xFF5C2D91)),
    ('traveloka', Color(0xFF0770CD)),
    ('tiket', Color(0xFF0064D2)),
    ('airbnb', Color(0xFFE0314B)),
    ('pegipegi', Color(0xFFE65100)),
  ];

  /// Warna merek platform; null bila tidak dikenal (pemanggil memakai
  /// warna netral dari tema).
  static Color? warnaDari(String? platform) {
    final String p = (platform ?? '').toLowerCase();
    for (final (String kata, Color warna) in _warnaMerek) {
      if (p.contains(kata)) return warna;
    }
    return null;
  }
}
