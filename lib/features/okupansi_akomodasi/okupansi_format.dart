// Format persentase untuk fitur Okupansi Akomodasi.

/// 55.2 -> "55,20%"; null -> "—" (sama seperti formatPercentage di web).
String okPersen(double? v) {
  if (v == null) return '—';
  return '${v.toStringAsFixed(2).replaceFirst('.', ',')}%';
}

/// Persentase pertumbuhan: maksimal 2 desimal tanpa nol di ujung, dengan
/// tanda +. Contoh: 2.5 -> "+2,5%", -1.25 -> "-1,25%", null -> "N/A".
String okPertumbuhan(double? v) {
  if (v == null) return 'N/A';
  String s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return '${v > 0 ? '+' : ''}${s.replaceFirst('.', ',')}%';
}
