import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';

/// Satu pasangan label-nilai yang dirender oleh [SectionCard].
///
/// Baris dengan nilai null/kosong otomatis disembunyikan supaya section
/// tidak penuh tanda "-" untuk field yang memang tidak diisi.
class Baris {
  const Baris(this.label, this.value, {this.url});

  final String label;
  final String? value;

  /// Kalau diisi, baris ini dirender sebagai tautan yang bisa ditekan
  /// untuk membuka [url] (bukan sekadar teks biasa).
  final String? url;

  bool get adaIsi => value != null && value!.trim().isNotEmpty;
  bool get bisaDibuka => url != null && url!.trim().isNotEmpty;
}

/// Kartu section untuk satu kategori field, dengan header ikon + judul.
///
/// Dipakai bersama oleh halaman detail Riwayat (data server) dan halaman
/// detail Ajuan/Sinkronisasi (data lokal offline) supaya tampilan kedua
/// halaman konsisten.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<Baris> rows;

  @override
  Widget build(BuildContext context) {
    final List<Baris> rowsTerisi = rows.where((Baris r) => r.adaIsi).toList();

    if (rowsTerisi.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: AppTheme.menuDashboard),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final Baris baris in rowsTerisi)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 130,
                      child: Text(
                        baris.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: baris.bisaDibuka
                          ? InkWell(
                              onTap: () => bukaTautanUrl(context, baris.url!),
                              child: Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      baris.value!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              baris.value!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Membuka [url] di browser/aplikasi eksternal. Dipakai oleh [SectionCard]
/// untuk baris yang bisa dibuka, dan bisa dipakai ulang di tempat lain yang
/// butuh perilaku sama (mis. tombol buka listing OTA).
Future<void> bukaTautanUrl(BuildContext context, String url) async {
  final Uri? uri = Uri.tryParse(url);

  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tautan tidak valid.')));
    }
    return;
  }

  final bool berhasil = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!berhasil && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka tautan.')));
  }
}