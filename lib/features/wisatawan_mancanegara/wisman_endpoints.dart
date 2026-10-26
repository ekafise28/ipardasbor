// Alamat API dashboard operasional Wisman (route
// dashboard-operasional.wisman.* di web, dipasang di prefix /mobile).

class WismanEndpoints {
  WismanEndpoints._();

  static const String _base = '/mobile/dashboard-operasional/wisman';

  /// GET -> opsi filter (tahun, provinsi, pintu_masuk, nama_pintu).
  static const String filters = '$_base/filters';

  /// GET -> data dashboard (summary, meta, charts) sesuai filter.
  static const String data = '$_base/data';
}
