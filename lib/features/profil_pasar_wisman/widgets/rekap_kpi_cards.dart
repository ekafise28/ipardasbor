// 3 kartu KPI Profil Pasar Wisman: Total Kunjungan, Pasar Terbesar,
// Pintu Masuk Utama. (Kartu YoY tidak ada: di web juga tidak ditampilkan.)

import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton.dart';
import '../../wisatawan_mancanegara/wisman_format.dart' show wismanAngka;
import '../models/rekap_dashboard_data.dart';

class RekapKpiCards extends StatelessWidget {
  const RekapKpiCards({super.key, required this.summary});

  /// null = belum ada data -> tampil "—".
  final RekapSummary? summary;

  @override
  Widget build(BuildContext context) {
    final RekapSummary? s = summary;

    final List<Widget> cards = <Widget>[
      _KpiCard(
        icon: Icons.groups_rounded,
        label: 'Total Kunjungan',
        value: s == null ? '—' : wismanAngka(s.total),
        detail: 'Sesuai filter aktif',
        colors: const <Color>[Color(0xFF064A91), Color(0xFF0874BD)],
      ),
      _KpiCard(
        icon: Icons.public_rounded,
        label: 'Pasar Terbesar',
        value: s == null ? '—' : (s.topNationality ?? '—'),
        detail: s == null
            ? '—'
            : '${wismanAngka(s.topNationalityTotal)} kunjungan',
        colors: const <Color>[Color(0xFF087A9E), Color(0xFF11A4BD)],
        compactValue: true,
      ),
      _KpiCard(
        icon: Icons.signpost_rounded,
        label: 'Pintu Masuk Utama',
        value: s == null ? '—' : (s.topPort ?? 'Belum dipetakan'),
        detail: s == null ? '—' : '${wismanAngka(s.topPortTotal)} kunjungan',
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

  /// true = teks nilai lebih kecil (untuk nama negara/pintu yang panjang).
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
class RekapKpiSkeleton extends StatelessWidget {
  const RekapKpiSkeleton({super.key});

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
