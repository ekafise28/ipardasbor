import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/bps/shared/widgets/wisatawan_bulan_grid.dart';
import 'package:ipardasbor/shared/utils/formatters.dart' show formatNumber;
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/wisman_bps_data.dart';

class WismanBpsCard extends StatelessWidget {
  const WismanBpsCard({super.key, required this.item});

  final WismanBpsRow item;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.warnaPintu(item.pintuMasuk);

    return StripCard(
      stripColor: warna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.namaPintu,
            statusLabel: '${item.tahun}',
            statusColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          ListInfoRow(
            icon: Icons.place_outlined,
            text: item.provinsi,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TintChip(
                    label: item.pintuMasuk,
                    color: warna,
                    icon: AppTheme.ikonPintu(item.pintuMasuk),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(width: 6),
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
