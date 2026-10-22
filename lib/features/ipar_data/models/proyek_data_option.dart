import 'proyek_data_parse.dart';

/// Jenis daftar pilihan filter di endpoint filter-options.
enum ProyekDataOptionType {
  provinsi('provinsi'),
  kota('kota'),
  kbli('kbli'),
  status('status'),
  risiko('risiko');

  const ProyekDataOptionType(this.param);
  final String param;
}

class ProyekDataOption {
  const ProyekDataOption({
    required this.value,
    required this.label,
    this.versi,
    this.bedaVersi = false,
  });

  /// Nilai yang dikirim ke server (untuk KBLI: kodenya).
  final String value;
  final String label;

  /// Hanya terisi untuk KBLI.
  final int? versi;

  /// true kalau kode yang sama muncul di lebih dari satu versi KBLI.
  final bool bedaVersi;

  /// Label untuk ditampilkan: versi hanya disebut kalau memang ambigu.
  String get labelTampil =>
      bedaVersi && versi != null ? '$label (KBLI $versi)' : label;

  factory ProyekDataOption.fromJson(Map<String, dynamic> json) {
    final String value = teksAtauNull(json['value']) ?? '';
    return ProyekDataOption(
      value: value,
      label: teksAtauNull(json['label']) ?? value,
      versi: angkaAtauNull(json['versi']),
      bedaVersi: json['beda_versi'] == true,
    );
  }
}

/// Hasil filter-options: daftar pilihan + pesan opsional dari server
/// (mis. "Pilih provinsi terlebih dahulu.").
class ProyekDataOptionResult {
  const ProyekDataOptionResult({required this.options, this.message});

  final List<ProyekDataOption> options;
  final String? message;
}