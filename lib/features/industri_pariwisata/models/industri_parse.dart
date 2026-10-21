// Fungsi bantu untuk membaca JSON dengan aman.
// Angka dari server kadang datang sebagai int, kadang String ("1250"),
// kadang null. Kalau langsung di-cast (as int), aplikasi bisa crash.
// Fungsi di sini selalu mengembalikan nilai yang aman.

/// Mengubah nilai dinamis menjadi int. Gagal/null -> 0.
int parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

/// Mengubah nilai dinamis menjadi String bersih.
/// Kosong/null -> [fallback]. (Di web, nilai kosong ditampilkan "-")
String parseString(dynamic value, [String fallback = '-']) {
  if (value == null) return fallback;
  final String text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

/// Memastikan nilai berupa List. Selain itu -> list kosong.
List<dynamic> parseList(dynamic value) => value is List ? value : const [];

/// Memastikan nilai berupa Map `<String, dynamic>.` Selain itu -> map kosong.
Map<String, dynamic> parseMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
