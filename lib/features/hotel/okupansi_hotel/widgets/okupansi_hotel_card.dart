import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/okupansi_hotel_data.dart';
import '../okupansi_hotel_style.dart';

class OkupansiHotelCard extends StatelessWidget {
  const OkupansiHotelCard({super.key, required this.item});

  final OkupansiHotelRow item;

  @override
  Widget build(BuildContext context) {
    final Color warna = warnaOkupansi(item.rataRata);

    return StripCard(
      stripColor: warna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.namaHotel,
            statusLabel: '${item.tahun}',
            statusColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          ListInfoRow(
            icon: Icons.place_outlined,
            text: '${item.kabKota}, ${item.provinsi}',
            maxLines: 2,
          ),
          Row(
            children: <Widget>[
              Text(
                'Rata-rata',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fmtPersen(item.rataRata, desimal: 2),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: warna,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
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
                          nilai: item.bulan[baris * 4 + k],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
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
