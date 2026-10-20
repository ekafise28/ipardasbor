import 'package:intl/intl.dart';
import 'package:ipardasbor/core/constants/bidang_usaha_constants.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';

/// Pembantu tampilan untuk halaman Sinkronisasi: mengubah isi payload
/// mentah menjadi teks yang mudah dibaca petugas.

const List<String> _bulan = <String>[
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

/// Slug bidang usaha; data lama tanpa nilai dianggap akomodasi (sama
/// dengan aturan di `NonOssFormData`).
String bidangSlugOf(NonOssLocalData d) {
  final String slug = (d.payload['bidang_usaha'] ?? '').trim();
  return slug.isEmpty ? 'akomodasi' : slug;
}

/// Contoh: "Non-OSS · Penyediaan Akomodasi".
String jenisUsahaLabel(NonOssLocalData d) {
  final String? bidang = BidangUsahaOpsi.namaDari(bidangSlugOf(d));
  return bidang == null ? 'Non-OSS' : 'Non-OSS · $bidang';
}

/// Label jenis produk (mis. "Hotel Bintang 1") dari kode yang tersimpan,
/// atau null kalau daftar label belum tersedia di perangkat.
String? jenisProdukLabel(
  NonOssLocalData d,
  Map<String, Map<String, String>> produkLabels,
) {
  final String kode = (d.payload['jenis_produk'] ?? '').trim();
  if (kode.isEmpty) return null;
  return produkLabels[bidangSlugOf(d)]?[kode];
}

/// Tanggal pengawasan yang diisi petugas; kalau tidak terbaca, pakai
/// tanggal data dibuat.
DateTime tanggalPengawasanOf(NonOssLocalData d) {
  final String raw = (d.payload['tanggal_pengawasan'] ?? '').trim();
  return DateTime.tryParse(raw) ?? d.createdAt.toLocal();
}

String formatTanggal(DateTime tanggal) =>
    DateFormat('dd/MM/yyyy').format(tanggal);

String alamatOf(NonOssLocalData d) {
  final String alamat = (d.payload['alamat'] ?? '').trim();
  return alamat.isEmpty ? '-' : alamat;
}

bool hasGps(NonOssLocalData d) =>
    (d.payload['latitude'] ?? '').trim().isNotEmpty &&
    (d.payload['longitude'] ?? '').trim().isNotEmpty;

/// "Hari ini, 08:30" atau "19 Okt, 16:45". Tanpa singkatan zona waktu
/// karena aplikasi bisa dipakai di WIB, WITA, maupun WIT.
String lastSyncLabel(DateTime? waktu) {
  if (waktu == null) return 'Belum ada';

  final DateTime lokal = waktu.toLocal();
  final DateTime sekarang = DateTime.now();
  final String jam = DateFormat('HH:mm').format(lokal);
  final bool hariIni =
      lokal.year == sekarang.year &&
      lokal.month == sekarang.month &&
      lokal.day == sekarang.day;

  return hariIni ? 'Hari ini, $jam' : '${lokal.day} ${_bulan[lokal.month - 1]}, $jam';
}