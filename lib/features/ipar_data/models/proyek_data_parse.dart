/// Pembaca nilai JSON yang toleran: MySQL bisa mengirim angka sebagai
/// int maupun string, dan kolom kosong bisa null.
String? teksAtauNull(dynamic v) {
  final String s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

int? angkaAtauNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}