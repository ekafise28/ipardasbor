// 3 kartu KPI Wisman: Total Wisman, Wisman YTD, Pintu Masuk Terbesar.
// (Kartu Pertumbuhan YoY sengaja tidak ada: di web juga dinonaktifkan.)

import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton.dart';
import '../models/wisman_dashboard_data.dart';
import '../wisman_format.dart';

class WismanKpiCards extends StatelessWidget {
  const WismanKpiCards({super.key, required this.summary});

  /// null = belum ada data -> tampil "—".
  final WismanSummary? summary;

  @override
  Widget build(BuildContext context) {
    final WismanSummary? s = summary;

    final String ytdLabel = s == null || s.ytdYear == 0
        ? 'Wisman YTD'
        : 'Wisman YTD ${s.ytdYear}';
    final String ytdDetail = s == null || s.ytdMonth < 1 || s.ytdMonth > 12
        ? 'Periode tahun berjalan'
        : 'Januari–${wismanBulan[s.ytdMonth - 1]}';

    final List<Widget> cards = <Widget>[
      _KpiCard(
        icon: Icons.groups_rounded,
        label: 'Total Wisman',
        value: s == null ? '—' : wismanAngka(s.total),
        detail: 'Sesuai seluruh filter aktif',
        colors: const <Color>[Color(0xFF064A91), Color(0xFF0874BD)],
      ),
      _KpiCard(
        icon: Icons.event_available_rounded,
        label: ytdLabel,
        value: s == null ? '—' : wismanAngka(s.ytd),
        detail: ytdDetail,
        colors: const <Color>[Color(0xFF087A9E), Color(0xFF11A4BD)],
      ),
      _KpiCard(
        icon: Icons.signpost_rounded,
        label: 'Pintu Masuk Terbesar',
        value: s == null ? '—' : (s.topGate ?? 'Tidak ada data'),
        detail: s == null
            ? '— kunjungan'
            : '${wismanAngka(s.topGateTotal)} kunjungan',
        colors: const <Color>[Color(0xFF5450A3), Color(0xFF776CCC)],
        compactValue: true,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < cards.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
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
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final List<Color> colors;

  /// true = teks nilai lebih kecil (untuk nama pintu yang panjang).
  final bool compactValue;

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
                    color: Colors.white,
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

/// Kerangka loading 3 kartu KPI.
class WismanKpiSkeleton extends StatelessWidget {
  const WismanKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 3; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            const SkeletonBox(height: 110, radius: 18),
          ],
        ],
      ),
    );
  }
}
