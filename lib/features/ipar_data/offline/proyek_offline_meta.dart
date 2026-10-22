/// Keterangan dataset Data Proyek yang diunduh manual.
class ProyekOfflineMeta {
  const ProyekOfflineMeta({
    required this.baris,
    required this.ukuranBytes,
    required this.savedAt,
    required this.target,
    required this.ringkasanFilter,
    this.provinsiUser,
    this.aksesSemuaWilayah = false,
    this.terpotongBatas = false,
  });

  final int baris;
  final int ukuranBytes;
  final DateTime savedAt;

  /// Jumlah baris yang diminta saat mengunduh.
  final int target;
  final String ringkasanFilter;
  final String? provinsiUser;
  final bool aksesSemuaWilayah;

  /// true kalau unduhan berhenti karena batas ukuran tercapai.
  final bool terpotongBatas;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'baris': baris,
    'ukuran_bytes': ukuranBytes,
    'saved_at': savedAt.toUtc().toIso8601String(),
    'target': target,
    'ringkasan_filter': ringkasanFilter,
    'provinsi_user': provinsiUser,
    'akses_semua_wilayah': aksesSemuaWilayah,
    'terpotong_batas': terpotongBatas,
  };

  factory ProyekOfflineMeta.fromJson(Map<String, dynamic> json) {
    return ProyekOfflineMeta(
      baris: (json['baris'] as num?)?.toInt() ?? 0,
      ukuranBytes: (json['ukuran_bytes'] as num?)?.toInt() ?? 0,
      savedAt: DateTime.parse(json['saved_at'] as String).toLocal(),
      target: (json['target'] as num?)?.toInt() ?? 0,
      ringkasanFilter: json['ringkasan_filter']?.toString() ?? 'Semua data',
      provinsiUser: json['provinsi_user']?.toString(),
      aksesSemuaWilayah: json['akses_semua_wilayah'] == true,
      terpotongBatas: json['terpotong_batas'] == true,
    );
  }
}

String formatUkuranBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}