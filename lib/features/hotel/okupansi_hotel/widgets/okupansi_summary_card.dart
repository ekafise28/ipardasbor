import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/okupansi_hotel_data.dart';
import '../okupansi_hotel_style.dart';

/// Tiga angka ringkas di atas grafik: rata-rata, jumlah hotel, tahun.
class OkupansiSummaryCard extends StatelessWidget {
  const OkupansiSummaryCard({super.key, required this.hasil});

  final OkupansiHotelResult hasil;

  @override
  Widget build(BuildContext context) {
    final List<int> tahun = <int>[...hasil.tahun]..sort();
    final String provinsi = hasil.provinsi.isEmpty
        ? 'Semua provinsi'
        : '${hasil.provinsi.length} provinsi dipilih';

    return DetailCard(
      icon: Icons.insights_rounded,
      title: 'Ringkasan',
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Kpi(
                  nilai: fmtPersen(hasil.rataRata, desimal: 2),
                  label: 'Rata-rata okupansi',
                ),
                _Kpi(
                  nilai: formatNumber(hasil.jumlahHotel),
                  label: 'Hotel',
                ),
                _Kpi(
                  nilai: tahun.isEmpty ? '-' : tahun.join(', '),
                  label: 'Tahun',
                  kecil: tahun.length > 2,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              provinsi,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.nilai, required this.label, this.kecil = false});

  final String nilai;
  final String label;
  final bool kecil;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            nilai,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: kecil ? 13 : 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}