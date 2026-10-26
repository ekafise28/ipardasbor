// 4 kartu KPI Okupansi: Rata-rata Okupansi, Perubahan YoY, Provinsi
// Tertinggi, Bulan Puncak.

import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton.dart';
import '../../wisatawan_mancanegara/wisman_format.dart' show wismanBulan;
import '../models/okupansi_dashboard_data.dart';
import '../okupansi_format.dart';

class OkupansiKpiCards extends StatelessWidget {
  const OkupansiKpiCards({super.key, required this.summary});

  /// null = belum ada data -> tampil "—".
  final OkupansiSummary? summary;

  @override
  Widget build(BuildContext context) {
    final OkupansiSummary? s = summary;

    final bool turun = s?.growthYoy != null && s!.growthYoy! < 0;
    final String info = s == null
        ? 'Dibanding tahun sebelumnya'
        : '${okPersen(s.latestAverage)} vs ${okPersen(s.previousAverage)} '
              '(${(s.changePoint ?? 0) > 0 ? '+' : ''}${okPersen(s.changePoint)} poin)';

    final int? bulan = s?.peakMonth;

    final List<Widget> cards = <Widget>[
      _KpiCard(
        icon: Icons.percent_rounded,
        label: 'Rata-rata Okupansi',
        value: s == null ? '—' : okPersen(s.average),
        detail: 'Sesuai filter aktif',
        colors: const <Color>[Color(0xFF064A91), Color(0xFF0874BD)],
      ),
      _KpiCard(
        icon: Icons.trending_up_rounded,
        label: 'Perubahan YoY',
        value: s == null ? '—' : okPertumbuhan(s.growthYoy),
        detail: info,
        colors: const <Color>[Color(0xFF087A9E), Color(0xFF11A4BD)],
        negative: turun,
      ),
      _KpiCard(
        icon: Icons.emoji_events_rounded,
        label: 'Provinsi Tertinggi',
        value: s == null ? '—' : (s.topProvince ?? '—'),
        detail: s == null ? '—' : okPersen(s.topValue),
        colors: const <Color>[Color(0xFF5450A3), Color(0xFF776CCC)],
        compactValue: true,
      ),
      _KpiCard(
        icon: Icons.event_rounded,
        label: 'Bulan Puncak',
        value: bulan == null || bulan < 1 || bulan > 12
            ? '—'
            : wismanBulan[bulan - 1],
        detail: s == null ? '—' : okPersen(s.peakValue),
        colors: const <Color>[Color(0xFFB45309), Color(0xFFF59E0B)],
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth >= 700) {
          return Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        return Column(
          children: <Widget>[
            for (int i = 0; i < cards.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.colors,
    this.compactValue = false,
    this.negative = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final List<Color> colors;

  /// true = teks nilai lebih kecil (untuk nama negara/pintu yang panjang).
  final bool compactValue;

  /// true = nilai ditandai merah muda (penurunan).
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(minHeight: 118),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: compactValue ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: negative ? const Color(0xFFFFC9C9) : Colors.white,
                    fontSize: compactValue ? 16 : 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kerangka loading 4 kartu KPI.
class OkupansiKpiSkeleton extends StatelessWidget {
  const OkupansiKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 4; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            const SkeletonBox(height: 110, radius: 18),
          ],
        ],
      ),
    );
  }
}
