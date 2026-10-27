import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/okupansi_hotel_data.dart';
import '../okupansi_hotel_style.dart';

/// Peringkat rata-rata okupansi (tertinggi ke terendah) dari deret yang
/// tampil di grafik. Skala batang 0-100%.
class OkupansiRankingCard extends StatefulWidget {
  const OkupansiRankingCard({
    super.key,
    required this.series,
    this.batasAwal = 8,
  });

  final List<OkupansiSeries> series;
  final int batasAwal;

  @override
  State<OkupansiRankingCard> createState() => _OkupansiRankingCardState();
}

class _OkupansiRankingCardState extends State<OkupansiRankingCard> {
  bool _semua = false;

  @override
  Widget build(BuildContext context) {
    // Pertahankan warna yang sama dengan grafik: warna ikut posisi asli.
    final List<(int, OkupansiSeries)> urut = <(int, OkupansiSeries)>[
      for (int i = 0; i < widget.series.length; i++) (i, widget.series[i]),
    ]..sort(((int, OkupansiSeries) a, (int, OkupansiSeries) b) =>
        b.$2.rataRata.compareTo(a.$2.rataRata));

    final bool bisaLipat = urut.length > widget.batasAwal;
    final List<(int, OkupansiSeries)> tampil =
        _semua || !bisaLipat ? urut : urut.take(widget.batasAwal).toList();

    return DetailCard(
      icon: Icons.leaderboard_rounded,
      title: 'Peringkat Rata-rata',
      count: urut.length,
      countSuffix: ' deret',
      child: urut.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data.',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                for (int n = 0; n < tampil.length; n++)
                  _BarisPeringkat(
                    urutan: urut.indexOf(tampil[n]) + 1,
                    label: tampil[n].$2.label,
                    nilai: tampil[n].$2.rataRata,
                    warna: warnaSeries(tampil[n].$1, tampil[n].$2),
                  ),
                if (bisaLipat)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _semua = !_semua),
                      icon: Icon(
                        _semua
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _semua
                            ? 'Ringkas'
                            : 'Tampilkan semua (${formatNumber(urut.length)})',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BarisPeringkat extends StatelessWidget {
  const _BarisPeringkat({
    required this.urutan,
    required this.label,
    required this.nilai,
    required this.warna,
  });

  final int urutan;
  final String label;
  final double nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 24,
                child: Text(
                  '$urutan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fmtPersen(nilai, desimal: 2),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 9,
                width: double.infinity,
                color: AppTheme.surfaceMuted(context),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: (nilai / 100).clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double f, _) =>
                      FractionallySizedBox(
                        widthFactor: nilai <= 0 ? 0 : f.clamp(0.02, 1.0),
                        child: Container(color: warna),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}