import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Menampilkan satu snackbar (yang lama otomatis diganti).
///
/// [sukses] null  : snackbar standar tema.
/// [sukses] true  : hijau, melayang.
/// [sukses] false : oranye tua, melayang.
void tampilkanPesan(BuildContext context, String pesan, {bool? sukses}) {
  final bool gaya = sukses != null;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: gaya ? const TextStyle(color: Colors.white) : null,
        ),
        backgroundColor: !gaya
            ? null
            : (sukses ? const Color(0xFF238636) : const Color(0xFFC2410C)),
        behavior: gaya ? SnackBarBehavior.floating : null,
        shape: gaya
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            : null,
      ),
    );
}

/// Membuka [url] di browser/aplikasi eksternal. Bila gagal, menampilkan
/// snackbar. Mengembalikan true bila berhasil dibuka.
///
/// Sengaja TIDAK memakai canLaunchUrl: di Android 11+ ia bisa bernilai
/// false (tanpa `<queries>` di manifest) padahal launchUrl berhasil.
Future<bool> bukaTautan(
  BuildContext context,
  String? url, {
  String pesanGagal = 'Tidak dapat membuka tautan.',
}) async {
  // Diambil sebelum await, jadi aman dipakai sesudahnya.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  void beritahu(String pesan) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));

  final String bersih = (url ?? '').trim();
  final Uri? uri = bersih.isEmpty ? null : Uri.tryParse(bersih);
  if (uri == null) {
    beritahu('Tautan tidak valid.');
    return false;
  }

  bool berhasil;
  try {
    berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    berhasil = false;
  }

  if (!berhasil) beritahu(pesanGagal);
  return berhasil;
}