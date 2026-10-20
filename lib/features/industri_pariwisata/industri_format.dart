// Fungsi bantu untuk menampilkan angka dan waktu dalam format Indonesia.
// Dibuat sendiri (tanpa paket intl) supaya tidak menambah dependensi.

/// 1234567 -> "1.234.567" (pemisah ribuan memakai titik, seperti di web).
String formatAngka(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    // "remaining" = sisa digit termasuk digit ini.
    // Setelah digit yang sisanya kelipatan 3 (+1), sisipkan titik.
    final int remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }

  return value < 0 ? '-$buffer' : '$buffer';
}

/// DateTime -> "20 Okt 2026 08.00"
String formatWaktu(DateTime t) {
  const List<String> bulan = [
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
  String dua(int n) => n.toString().padLeft(2, '0'); // 5 -> "05"

  return '${dua(t.day)} ${bulan[t.month - 1]} ${t.year} '
      '${dua(t.hour)}.${dua(t.minute)}';
}
