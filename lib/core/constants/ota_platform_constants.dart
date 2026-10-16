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
}