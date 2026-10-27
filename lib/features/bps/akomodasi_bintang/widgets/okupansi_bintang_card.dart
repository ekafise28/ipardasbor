import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/okupansi_hotel_style.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/widgets/okupansi_bulan_grid.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/okupansi_bintang_data.dart';

/// Satu kartu = satu provinsi pada satu tahun, dengan grid 12 bulan.
/// Padanan baris-baris tabel "Rincian Data Okupansi" di web.
class OkupansiBintangCard extends StatelessWidget {
  const OkupansiBintangCard({super.key, required this.item});

  final OkupansiBintangRow item;

  @override
  Widget build(BuildContext context) {
    final Color warna = warnaOkupansi(item.rataRata);

    return StripCard(
      stripColor: warna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.provinsi,
            statusLabel: '${item.tahun}',
            statusColor: AppTheme.primaryColor,
          ),
          if (item.nasional) ...<Widget>[
            const SizedBox(height: 8),
            const ListInfoRow(
              icon: Icons.public_rounded,
              text: 'Angka nasional',
              maxLines: 1,
            ),
          ],
          const SizedBox(height: 8),
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
          OkupansiBulanGrid(bulan: item.bulan),
        ],
      ),
    );
  }
}