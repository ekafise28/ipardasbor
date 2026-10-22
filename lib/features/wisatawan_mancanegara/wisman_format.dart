// Fungsi format kecil untuk fitur Wisatawan Mancanegara.

import 'dart:math' as math;

const List<String> wismanBulan = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> wismanBulanSingkat = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 1234567 -> "1.234.567" (titik sebagai pemisah ribuan, seperti web).
String wismanAngka(int value) {
  final String s = value.abs().toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return value < 0 ? '-$b' : b.toString();
}

/// 1234567 -> "1,2 jt", 85000 -> "85 rb". Untuk label sumbu Y yang sempit.
String wismanRingkas(double v) {
  String rapikan(double x) {
    final String s = x.toStringAsFixed(1);
    return s.endsWith('.0')
        ? s.substring(0, s.length - 2)
        : s.replaceFirst('.', ',');
  }

  if (v >= 1000000) return '${rapikan(v / 1000000)} jt';
  if (v >= 1000) return '${rapikan(v / 1000)} rb';
  return v.round().toString();
}

/// Jarak garis sumbu Y yang "bulat" (1, 2, 5 x 10^n), sekitar 4 garis.
double wismanNiceInterval(double max) {
  if (max <= 0) return 1;
  final double raw = max / 4;
  final double magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final double normalized = raw / magnitude;
  final double nice = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return nice * magnitude;
}
