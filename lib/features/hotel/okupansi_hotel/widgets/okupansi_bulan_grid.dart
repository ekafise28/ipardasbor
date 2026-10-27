import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../models/okupansi_hotel_data.dart';
import '../okupansi_hotel_style.dart';

/// Grid 12 bulan (4 kolom x 3 baris). [bulan] harus 12 elemen,
/// null = belum ada data.
class OkupansiBulanGrid extends StatelessWidget {
  const OkupansiBulanGrid({super.key, required this.bulan});

  final List<double?> bulan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int baris = 0; baris < 3; baris++) ...<Widget>[
          if (baris > 0) const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (int k = 0; k < 4; k++) ...<Widget>[
                if (k > 0) const SizedBox(width: 6),
                Expanded(
                  child: _SelBulan(
                    nama: kNamaBulanSingkat[baris * 4 + k],
                    nilai: bulan[baris * 4 + k],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _SelBulan extends StatelessWidget {
  const _SelBulan({required this.nama, required this.nilai});

  final String nama;
  final double? nilai;

  @override
  Widget build(BuildContext context) {
    final Color w = warnaOkupansi(nilai);
    final bool kosong = nilai == null;

    return Semantics(
      label: '$nama: ${kosong ? 'belum ada data' : fmtPersen(nilai)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: kosong
              ? AppTheme.surfaceMuted(context)
              : w.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: kosong ? AppTheme.border(context) : w.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              nama,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fmtPersen(nilai),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: kosong
                    ? AppTheme.textMuted
                    : AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}