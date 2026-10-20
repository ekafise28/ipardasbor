// 3 kartu ringkasan (KPI) di bagian atas dashboard.
// Warna gradien disamakan dengan versi web.

import 'package:flutter/material.dart';

import '../industri_format.dart';
import '../models/industri_dashboard_data.dart';

class IndustriKpiCards extends StatelessWidget {
  const IndustriKpiCards({super.key, required this.kpi});

  /// null = data belum dimuat -> angka ditampilkan "—" (seperti di web).
  final IndustriKpi? kpi;

  @override
  Widget build(BuildContext context) {
    // Jika belum ada data, pakai nilai bawaan untuk judul & keterangan.
    final IndustriKpi data = kpi ?? const IndustriKpi();
    String angka(int value) => kpi == null ? '—' : formatAngka(value);

    final List<Widget> cards = [
      _KpiCard(
        icon: Icons.apartment_rounded,
        title: 'Total Usaha',
        value: angka(data.totalUsaha),
        caption: 'Jumlah seluruh baris usaha sesuai filter',
        colors: const [Color(0xFF064A91), Color(0xFF0874BD)],
      ),
      _KpiCard(
        icon: Icons.trending_up_rounded,
        title: data.usahaBaruLabel, // berubah mengikuti filter tahun
        value: angka(data.usahaBaru),
        caption: data.usahaBaruDetail,
        colors: const [Color(0xFF087A9E), Color(0xFF11A4BD)],
      ),
      _KpiCard(
        icon: Icons.fingerprint_rounded,
        title: 'Total NIB',
        value: angka(data.totalNib),
        caption: 'Jumlah NIB unik, tanpa data ganda',
        colors: const [Color(0xFF5450A3), Color(0xFF776CCC)],
      ),
    ];

    // Layar lebar (tablet): 3 kartu sejajar. HP: bertumpuk ke bawah.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
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
    required this.title,
    required this.value,
    required this.caption,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kotak ikon di kiri
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          // Teks di kanan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // FittedBox: angka besar otomatis mengecil jika tidak muat.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 10.5,
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
