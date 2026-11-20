import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart';
import 'package:ipardasbor/shared/utils/formatters.dart'
    show bulanSingkat, formatNumber, formatRingkas, namaBulan, niceInterval;
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;
import 'package:ipardasbor/shared/widgets/legend_chip.dart';

/// Grafik garis jumlah wisatawan per bulan (Jan-Des). Satu garis = satu
/// provinsi pada satu tahun. Ketuk legenda untuk menyembunyikan/menampilkan
/// garis. Bulan tanpa data memutus garis, bukan dianggap 0.
class WisatawanTrendChart extends StatefulWidget {
  const WisatawanTrendChart({
    super.key,
    required this.title,
    required this.series,
    this.icon = Icons.show_chart_rounded,
    this.seriesDipotong = false,
    this.totalSeries = 0,
    this.catatan,
  });

  final String title;
  final IconData icon;
  final List<WisatawanSeries> series;
  final bool seriesDipotong;

  /// Jumlah deret (selain nasional) sebelum dipotong server.
  final int totalSeries;

  /// Catatan kecil di bawah legenda, mis. "2026: Jan–Jun".
  final String? catatan;

  @override
  State<WisatawanTrendChart> createState() => _WisatawanTrendChartState();
}

class _WisatawanTrendChartState extends State<WisatawanTrendChart> {
  final Set<String> _sembunyi = <String>{};

  void _toggle(WisatawanSeries s) {
    setState(
      () => _sembunyi.contains(s.kunci)
          ? _sembunyi.remove(s.kunci)
          : _sembunyi.add(s.kunci),
    );
  }

  LineChartBarData _garis(WisatawanSeries s, Color warna) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < 12; i++)
          s.values[i] == null
              ? FlSpot.nullSpot
              : FlSpot(i.toDouble(), s.values[i]!.toDouble()),
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
    final List<WisatawanSeries> semua = widget.series;

    // Warna ditentukan oleh posisi di daftar lengkap, jadi tidak berubah
    // saat ada garis yang disembunyikan.
    final List<(WisatawanSeries, Color)> tampil = <(WisatawanSeries, Color)>[
      for (int i = 0; i < semua.length; i++)
        if (!_sembunyi.contains(semua[i].kunci))
          (semua[i], AppTheme.warnaDeret(i, nasional: semua[i].nasional)),
    ];

    int tertinggi = 0;
    for (final (WisatawanSeries s, Color _) in tampil) {
      for (final int? v in s.values) {
        if (v != null && v > tertinggi) tertinggi = v;
      }
    }
    final double interval = niceInterval(tertinggi.toDouble());
    final double maxY = tertinggi <= 0
        ? interval * 4
        : (tertinggi / interval).ceil() * interval;

    final int tampilBukanNasional = semua
        .where((WisatawanSeries s) => !s.nasional)
        .length;

    return DetailCard(
      icon: widget.icon,
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          if (semua.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data untuk pilihan ini.',
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
                  LegendChip(
                    label: semua[i].label,
                    warna: AppTheme.warnaDeret(i, nasional: semua[i].nasional),
                    aktif: !_sembunyi.contains(semua[i].kunci),
                    putus: semua[i].nasional,
                    onTap: () => _toggle(semua[i]),
                  ),
              ],
            ),
            if (widget.seriesDipotong)
              _Catatan(
                'Menampilkan $tampilBukanNasional dari ${widget.totalSeries} '
                'deret teratas. Persempit filter untuk melihat yang lain.',
              ),
            if (widget.catatan != null) _Catatan(widget.catatan!),
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
    List<(WisatawanSeries, Color)> tampil,
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
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            interval: interval,
            getTitlesWidget: (double v, TitleMeta meta) {
              if (v > maxY + 0.001) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(formatRingkas(v), style: sumbu),
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
                child: Text(bulanSingkat[i], style: sumbu),
              );
            },
          ),
        ),
      ),
      lineBarsData: <LineChartBarData>[
        for (final (WisatawanSeries s, Color w) in tampil) _garis(s, w),
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
                  final (WisatawanSeries s, Color w) =
                      tampil[spots[n].barIndex];
                  final String bulan = namaBulan[spots[n].x.toInt()];
                  return LineTooltipItem(
                    n == 0 ? '$bulan\n' : '',
                    putih,
                    children: <TextSpan>[
                      TextSpan(
                        text: '● ',
                        style: TextStyle(color: w),
                      ),
                      TextSpan(
                        text:
                            '${s.label}: '
                            '${formatNumber(spots[n].y.round())}',
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

class _Catatan extends StatelessWidget {
  const _Catatan(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
}
