// Alamat API dashboard Okupansi Akomodasi (padanan route
// dashboard-okupansi.* di web, dipasang di prefix /mobile).

class OkupansiEndpoints {
  OkupansiEndpoints._();

  static const String _base = '/mobile/dashboard-okupansi';

  /// GET -> opsi filter (tahun, provinsi).
  static const String filters = '$_base/filters';

  /// GET -> data dashboard (summary, meta, charts) sesuai filter.
  static const String data = '$_base/data';
}
