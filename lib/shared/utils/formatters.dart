/// Memformat bilangan bulat dengan pemisah ribuan titik.
/// Contoh: 1234567 -> "1.234.567".
String formatNumber(int value) {
  final bool negative = value < 0;
  final String source = value.abs().toString();
  final StringBuffer result = StringBuffer(negative ? '-' : '');

  for (int index = 0; index < source.length; index++) {
    final int remaining = source.length - index;

    result.write(source[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      result.write('.');
    }
  }

  return result.toString();
}

/// "350 m", "2,4 km", "12 km".
String formatJarak(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// Menambah https:// bila belum ada skema. Null/kosong menghasilkan null.
String? normalisasiUrl(String? url) {
  final String bersih = (url ?? '').trim();
  if (bersih.isEmpty) return null;
  if (bersih.startsWith('http://') || bersih.startsWith('https://')) {
    return bersih;
  }
  return 'https://$bersih';
}

/// Tautan Google Maps dari lat/lng. Menerima String maupun angka.
/// Null bila salah satunya kosong.
String? mapsUrl(Object? lat, Object? lng) {
  final String a = '${lat ?? ''}'.trim();
  final String b = '${lng ?? ''}'.trim();
  if (a.isEmpty || b.isEmpty) return null;
  return 'https://www.google.com/maps?q=$a,$b';
}

const List<String> _bulan = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "5 Mar 2026". Null bila [d] null.
String? formatTanggal(DateTime? d) {
  if (d == null) return null;
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

/// "5 Mar 2026, 09:05". Null bila [d] null.
String? formatTanggalJam(DateTime? d) {
  if (d == null) return null;
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${formatTanggal(d)}, ${dua(d.hour)}:${dua(d.minute)}';
}
