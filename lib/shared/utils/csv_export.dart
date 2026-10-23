import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Satu baris CSV. Aturan kutipnya meniru fputcsv di web: field diberi kutip
/// bila mengandung pemisah, koma, kutip, spasi, tab, atau baris baru.
/// Nilai "-" (kosong di tampilan) diekspor kosong, dan nilai berawalan
/// = + - @ diberi tanda ' agar tidak dibaca sebagai rumus Excel.
String barisCsv(List<String> kolom) {
  final RegExp perluKutip = RegExp(r'[;,"\s]');
  final RegExp awalRumus = RegExp(r'^[=+\-@]');

  final String baris = kolom
      .map((String v) {
        String s = v == '-' ? '' : v;
        if (awalRumus.hasMatch(s)) s = "'$s";
        if (perluKutip.hasMatch(s)) s = '"${s.replaceAll('"', '""')}"';
        return s;
      })
      .join(';');

  return '$baris\r\n';
}

/// Stempel waktu untuk nama file, mis. "20261023-101530".
String stempelFile([DateTime? waktu]) =>
    DateFormat('yyyyMMdd-HHmmss').format(waktu ?? DateTime.now());

/// Mengubah teks (mis. nama provinsi) menjadi bagian nama file: huruf kecil,
/// angka, dan tanda hubung. "DKI Jakarta" menjadi "dki-jakarta".
String slugFile(String teks) => teks
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Menulis CSV (BOM + ";" seperti ekspor di web) ke folder sementara lalu
/// membuka lembar bagikan.
Future<void> bagikanCsv({
  required String namaFile,
  required List<List<String>> baris,
  String? subjek,
}) async {
  final StringBuffer csv = StringBuffer('\uFEFF');
  for (final List<String> b in baris) {
    csv.write(barisCsv(b));
  }

  final Directory dir = await getTemporaryDirectory();
  final File file = File('${dir.path}/$namaFile');
  await file.writeAsBytes(utf8.encode(csv.toString()), flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
      subject: subjek,
    ),
  );
}
