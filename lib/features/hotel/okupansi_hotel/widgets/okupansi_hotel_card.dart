import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/widgets/okupansi_bulan_grid.dart'
    show OkupansiBulanGrid;
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
          OkupansiBulanGrid(bulan: item.bulan),
        ],
      ),
    );
  }
}
