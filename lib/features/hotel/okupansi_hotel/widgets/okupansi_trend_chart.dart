import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/okupansi_hotel_data.dart';
import '../okupansi_hotel_style.dart';

/// Grafik garis okupansi per bulan (Jan-Des). Satu garis = satu provinsi
/// pada satu tahun. Ketuk legenda untuk menyembunyikan/menampilkan garis.
/// Bulan tanpa data memutus garis, bukan dianggap 0.
class OkupansiTrendChart extends StatefulWidget {
  const OkupansiTrendChart({
    super.key,
    required this.series,
    this.seriesDipotong = false,
    this.totalSeries = 0,
  });

  final List<OkupansiSeries> series;
  final bool seriesDipotong;
  final int totalSeries;

  @override
  State<OkupansiTrendChart> createState() => _OkupansiTrendChartState();
}

class _OkupansiTrendChartState extends State<OkupansiTrendChart> {
  final Set<String> _sembunyi = <String>{};

  void _toggle(OkupansiSeries s) {
    final String k = kunciSeries(s);
    setState(() => _sembunyi.contains(k) ? _sembunyi.remove(k) : _sembunyi.add(k));
  }

  LineChartBarData _garis(OkupansiSeries s, Color warna) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < 12; i++)
          s.values[i] == null
              ? FlSpot.nullSpot
              : FlSpot(i.toDouble(), s.values[i]!),
      ],
      color: warna,
      barWidth: s.nasional ? 2 : 2.5,
      dashArray: s.nasional ? <int>[6, 4] : null,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OkupansiSeries> semua = widget.series;

    // Pasangan (deret, warna) yang sedang tampil. Warna ditentukan oleh
    // posisi di daftar lengkap, jadi tidak berubah saat ada yang disembunyikan.
    final List<(OkupansiSeries, Color)> tampil = <(OkupansiSeries, Color)>[
      for (int i = 0; i < semua.length; i++)
        if (!_sembunyi.contains(kunciSeries(semua[i])))
          (semua[i], warnaSeries(i, semua[i])),
    ];

    double? tertinggi;
    for (final (OkupansiSeries s, Color _) in tampil) {
      for (final double? v in s.values) {
        if (v != null && (tertinggi == null || v > tertinggi)) tertinggi = v;
      }
    }
    final double maxY = tertinggi == null
        ? 100
        : math.min(100, ((tertinggi / 10).ceil() * 10 + 10).toDouble());
    final double interval = maxY > 60 ? 20 : 10;

    return DetailCard(
      icon: Icons.show_chart_rounded,
      title: 'Okupansi per Bulan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          if (semua.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data okupansi untuk pilihan ini.',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          else ...<Widget>[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (int i = 0; i < semua.length; i++)
                  _LegendChip(
                    label: semua[i].label,
                    warna: warnaSeries(i, semua[i]),
                    aktif: !_sembunyi.contains(kunciSeries(semua[i])),
                    putus: semua[i].nasional,
                    onTap: () => _toggle(semua[i]),
                  ),
              ],
            ),
            if (widget.seriesDipotong)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Menampilkan ${semua.where((OkupansiSeries s) => !s.nasional).length} '
                  'dari ${widget.totalSeries} deret teratas. Persempit filter '
                  'untuk melihat yang lain.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            if (tampil.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Ketuk legenda untuk menampilkan garis.',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                ),
              )
            else
              SizedBox(
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, top: 6),
                  child: LineChart(_data(context, tampil, maxY, interval)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  LineChartData _data(
    BuildContext context,
    List<(OkupansiSeries, Color)> tampil,
    double maxY,
    double interval,
  ) {
    final TextStyle sumbu = TextStyle(
      fontSize: 10.5,
      color: AppTheme.textSecondary(context),
    );

    return LineChartData(
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: maxY,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (double _) =>
            FlLine(color: AppTheme.border(context), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: interval,
            getTitlesWidget: (double v, TitleMeta meta) {
              if (v > maxY + 0.001) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text('${v.toInt()}%', style: sumbu),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: (double v, TitleMeta meta) {
              final int i = v.toInt();
              if (i < 0 || i > 11 || v != i.toDouble()) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(kNamaBulanSingkat[i], style: sumbu),
              );
            },
          ),
        ),
      ),
      lineBarsData: <LineChartBarData>[
        for (final (OkupansiSeries s, Color w) in tampil) _garis(s, w),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> spots) {
            const TextStyle putih = TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            );
            return <LineTooltipItem?>[
              for (int n = 0; n < spots.length; n++)
                () {
                  final (OkupansiSeries s, Color w) = tampil[spots[n].barIndex];
                  final String bulan = kNamaBulanPanjang[spots[n].x.toInt()];
                  return LineTooltipItem(
                    n == 0 ? '$bulan\n' : '',
                    putih,
                    children: <TextSpan>[
                      TextSpan(text: '● ', style: TextStyle(color: w)),
                      TextSpan(
                        text: '${s.label}: ${fmtPersen(spots[n].y, desimal: 2)}',
                        style: putih.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }(),
            ];
          },
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.warna,
    required this.aktif,
    required this.putus,
    required this.onTap,
  });

  final String label;
  final Color warna;
  final bool aktif;
  final bool putus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: aktif,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: aktif ? warna.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aktif ? warna : AppTheme.border(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: putus ? 12 : 9,
                height: putus ? 3 : 9,
                decoration: BoxDecoration(
                  color: aktif ? warna : AppTheme.textMuted,
                  shape: putus ? BoxShape.rectangle : BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    decoration: aktif ? null : TextDecoration.lineThrough,
                    color: aktif
                        ? AppTheme.textColor(context)
                        : AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}