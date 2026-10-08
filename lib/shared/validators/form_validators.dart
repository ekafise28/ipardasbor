/// Validator format yang dipakai bersama form OSS dan Non-OSS.
/// Pengecekan "wajib diisi" sengaja terpisah (ditangani _buildChecks di form).
class FormValidators {
  const FormValidators._();

  /// Harus sama dengan backend: regex ^[0-9+]{10,15}$.
  static const int phoneMin = 10;
  static const int phoneMax = 15;

  static String? phone(String? v) {
    final String value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.length < phoneMin || value.length > phoneMax) {
      return 'Nomor telepon harus $phoneMin-$phoneMax digit.';
    }
    return null;
  }

  static String? url(String? v) {
    final String value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    final Uri? uri = Uri.tryParse(value);
    final bool valid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Masukkan URL yang valid, contoh: https://contoh.com';
  }

  static final RegExp _email = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');

  /// [wajib] true: kosong ditolak ("Wajib diisi."), dipakai form Non-OSS.
  static String? email(String? v, {bool wajib = false}) {
    final String value = v?.trim() ?? '';
    if (value.isEmpty) return wajib ? 'Wajib diisi.' : null;
    return _email.hasMatch(value) ? null : 'Masukkan alamat email yang valid.';
  }
}