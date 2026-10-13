import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../utils/format_number.dart';

/// Baris keterangan di atas daftar: "Provinsi · N data · M belum
/// diverifikasi". Bagian opsional hanya tampil kalau diisi.
class ListSummaryLine extends StatelessWidget {
  const ListSummaryLine({
    super.key,
    this.provinsi,
    required this.total,
    required this.satuan,
    this.belum,
    this.akhiran,
    this.catatan,
  });

  /// Null = baris hanya menampilkan jumlah (mis. halaman yang tidak
  /// dibatasi provinsi).
  final String? provinsi;
  final int total;

  /// Kata benda setelah angka total, mis. "usaha" atau "data".
  final String satuan;

  /// Jumlah yang belum diverifikasi, disorot oranye. Null = disembunyikan
  /// (mis. saat daftar sudah disaring per status).
  final int? belum;

  /// Teks tambahan di ujung baris, mis. "terdekat dulu".
  final String? akhiran;

  /// Catatan di baris kedua berwarna kuning tua, mis. info lokasi tersimpan.
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text.rich(
              TextSpan(
                text: provinsi == null
                    ? '${formatNumber(total)} $satuan'
                    : '$provinsi · ${formatNumber(total)} $satuan',
                children: <InlineSpan>[
                  if (belum != null)
                    TextSpan(
                      text: ' · ${formatNumber(belum!)} belum diverifikasi',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (akhiran != null) TextSpan(text: ' · $akhiran'),
                ],
              ),
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
            if (catatan != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  catatan!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD08A00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
