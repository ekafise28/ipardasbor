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