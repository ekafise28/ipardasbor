/// Pengubah nilai JSON (bisa int, double, String, atau null) menjadi angka.
/// Dipakai semua model; jangan menulis `_asInt`/`_toInt` baru di file lain.

/// Gagal atau null -> 0.
int asInt(dynamic v) => asIntOrNull(v) ?? 0;

/// Gagal atau null -> null. Desimal dipotong (12.7 -> 12).
int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

/// Gagal atau null -> 0.
double asDouble(dynamic v) => asDoubleOrNull(v) ?? 0;

/// Gagal atau null -> null.
double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim());
}