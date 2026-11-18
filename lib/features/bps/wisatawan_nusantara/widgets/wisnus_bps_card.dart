import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/bps/shared/widgets/wisatawan_bulan_grid.dart';
import 'package:ipardasbor/shared/utils/formatters.dart' show formatNumber;
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/wisnus_bps_data.dart';

/// Satu kartu = satu provinsi pada satu tahun, dengan grid 12 bulan.
/// Padanan baris tabel "Rekap Wisatawan Nusantara" di web.
class WisnusBpsCard extends StatelessWidget {
  const WisnusBpsCard({super.key, required this.item});

  final WisnusBpsRow item;

  @override
  Widget build(BuildContext context) {
    final Color warna = item.nasional
        ? AppTheme.menuProfil
        : AppTheme.primaryColor;

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
                'Total',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatNumber(item.total),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: warna,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          WisatawanBulanGrid(bulan: item.bulan),
        ],
      ),
    );
  }
}