import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart'
    show catatanBulanTerakhir;
import 'package:ipardasbor/shared/utils/formatters.dart'
    show formatNumber, formatPersen;
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/wisman_bps_data.dart';

/// Total kunjungan wisman sesuai filter (seluruh data, bukan satu halaman)
/// dan porsi tiap jenis pintu.
class WismanBpsSummaryCard extends StatelessWidget {
  const WismanBpsSummaryCard({
    super.key,
    required this.hasil,
    required this.tahunOtomatis,
  });

  final WismanBpsResult hasil;

  /// true = pengguna belum memilih tahun, server memakai tahun terbaru.
  final bool tahunOtomatis;

  @override
  Widget build(BuildContext context) {
    final String tahun = hasil.tahun.join(', ');
    final String? catatan = catatanBulanTerakhir(hasil.bulanTerakhir);
    final TextStyle kecil = TextStyle(
      fontSize: 12,
      color: AppTheme.textSecondary(context),
    );

    return DetailCard(
      icon: Icons.groups_rounded,
      title: 'Total Kunjungan Wisman',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          Text(
            formatNumber(hasil.total),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tahunOtomatis ? 'Tahun terbaru: $tahun' : 'Tahun: $tahun',
            style: kecil,
          ),
          if (catatan != null)
            Text(
              'Data $catatan',
              style: kecil.copyWith(fontStyle: FontStyle.italic),
            ),
          if (hasil.perPintu.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            for (final WismanBpsPintuTotal p in hasil.perPintu)
              _BarisPintu(item: p, total: hasil.total),
          ],
        ],
      ),
    );
  }
}

class _BarisPintu extends StatelessWidget {
  const _BarisPintu({required this.item, required this.total});

  final WismanBpsPintuTotal item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.warnaPintu(item.pintuMasuk);
    final double porsi = total > 0 ? (item.total / total).clamp(0.0, 1.0) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              AppTheme.ikonPintu(item.pintuMasuk),
              size: 18,
              color: warna,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.pintuMasuk,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                    Text(
                      formatNumber(item.total),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: porsi,
                          minHeight: 6,
                          color: warna,
                          backgroundColor: AppTheme.surfaceMuted(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        formatPersen(porsi * 100, desimal: 1),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
