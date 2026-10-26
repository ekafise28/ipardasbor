// Alamat API dashboard Profil Pasar Wisman (Wisman Rekap).
// route dashboard-wisman-rekap.* di web, dipasang di prefix /mobile.

class RekapEndpoints {
  RekapEndpoints._();

  static const String _base = '/mobile/dashboard-wisman-rekap';

  /// GET -> opsi filter (tahun, kewarganegaraan, pintu).
  static const String filters = '$_base/filters';

  /// GET -> data dashboard (summary, meta, charts) sesuai filter.
  static const String data = '$_base/data';
}
