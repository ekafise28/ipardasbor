import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/okupansi_hotel_style.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/okupansi_non_bintang_data.dart';

class OkupansiNonBintangCard extends StatelessWidget {
  const OkupansiNonBintangCard({super.key, required this.item});

  final OkupansiNonBintangRow item;

  @override
  Widget build(BuildContext context) {
    final Color warna = warnaOkupansi(item.persentase);

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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Okupansi',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              Text(
                fmtPersen(item.persentase, desimal: 2),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: warna,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (item.persentase / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: AppTheme.surfaceMuted(context),
              valueColor: AlwaysStoppedAnimation<Color>(warna),
            ),
          ),
        ],
      ),
    );
  }
}