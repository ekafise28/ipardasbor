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

