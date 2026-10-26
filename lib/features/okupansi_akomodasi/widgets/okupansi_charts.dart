// Seksi "Ikhtisar Okupansi Hotel Bintang": 4 grafik + tabel data + tombol
// salin. Padanan blok ok-card di dashboard/okupansi.blade.php:
//   1. Okupansi Bulanan             (garis per provinsi+tahun, skala 0-100%)
//   2. Tren Okupansi Tahunan        (garis, area terisi)
//   3. 10 Provinsi Okupansi Tertinggi (batang horizontal, biru)
//   4. 10 Provinsi Okupansi Terendah  (batang horizontal, kuning)

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../wisatawan_mancanegara/wisman_format.dart';
import '../models/okupansi_dashboard_data.dart';
import '../okupansi_format.dart';

const Color _biru = Color(0xFF0756B4);
const Color _kuning = Color(0xFFF59E0B);

/// Warna garis per provinsi: hue dibagi rata seperti di web.
Color _warnaGaris(int index, int total) {
  final double hue = (index * 360 / (total < 1 ? 1 : total)).roundToDouble();
  return HSLColor.fromAHSL(1, hue % 360, 0.78, 0.48).toColor();
}

class _Seri {
  const _Seri(this.label, this.color, this.values);

  final String label;
  final Color color;
  final List<double?> values;
}

// ======================================================================
// Seksi
// ======================================================================

class OkupansiChartSection extends StatelessWidget {
  const OkupansiChartSection({
    super.key,
    required this.data,
    required this.loading,
  });

  /// null = belum ada data. Saat [loading] true tampil kerangka loading.
  final OkupansiDashboardData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Widget judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ikhtisar Okupansi Hotel Bintang',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Nilai merupakan persentase tingkat penghunian kamar.',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
          ),
        ),
      ],
    );

    if (data == null && loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          judul,
          const SizedBox(height: 14),
          const OkupansiChartSkeleton(),
        ],
      );
    }

    final OkupansiDashboardData? d = data;
    final List<OkupansiSeries> comparison =
        d?.comparison ?? const <OkupansiSeries>[];
    final List<OkupansiPoint> annual = d?.annual ?? const <OkupansiPoint>[];
    final List<OkupansiPoint> ranking = d?.ranking ?? const <OkupansiPoint>[];
    final List<OkupansiPoint> bottom = d?.bottom ?? const <OkupansiPoint>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        judul,
        const SizedBox(height: 14),

        // 1. Okupansi bulanan
        _ChartCard(
          title: 'Okupansi Bulanan',
          kosong: comparison.isEmpty,
          chart: _LineView(
            labels: wismanBulanSingkat,
            fixed100: true,
            height: 300,
            series: <_Seri>[
              for (int i = 0; i < comparison.length; i++)
                _Seri(
                  comparison[i].label,
                  _warnaGaris(i, comparison.length),
                  comparison[i].months,
                ),
            ],
          ),
          headers: <String>['Provinsi', 'Tahun', ...wismanBulanSingkat],
          // Lebar tetap + gulir mendatar: tabelnya 14 kolom.
          minWidths: const <double>[
            52,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
            58,
          ],
          firstWidth: 150,
          rows: <List<String>>[
            for (final OkupansiSeries r in comparison)
              <String>[
                r.province,
                r.year,
                for (final double? v in r.months) okPersen(v),
              ],
          ],
        ),

        // 2. Tren tahunan
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Tren Okupansi Tahunan',
          kosong: annual.isEmpty,
          chart: _LineView(
            labels: <String>[for (final OkupansiPoint p in annual) p.label],
            fill: true,
            showLegend: false,
            height: 260,
            series: <_Seri>[
              _Seri('Okupansi', _biru, <double?>[
                for (final OkupansiPoint p in annual) p.value,
              ]),
            ],
          ),
          headers: const <String>['Tahun', 'Okupansi'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final OkupansiPoint p in annual)
              <String>[p.label, okPersen(p.value)],
          ],
        ),

        // 3. Tertinggi
        const SizedBox(height: 14),
        _ChartCard(
          title: '10 Provinsi Okupansi Tertinggi',
          kosong: ranking.isEmpty,
          chart: _RankView(rows: ranking, color: _biru),
          headers: const <String>['Provinsi', 'Okupansi'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final OkupansiPoint p in ranking)
              <String>[p.label, okPersen(p.value)],
          ],
        ),

        // 4. Terendah
        const SizedBox(height: 14),
        _ChartCard(
          title: '10 Provinsi Okupansi Terendah',
          kosong: bottom.isEmpty,
          chart: _RankView(rows: bottom, color: _kuning),
          headers: const <String>['Provinsi', 'Okupansi'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final OkupansiPoint p in bottom)
              <String>[p.label, okPersen(p.value)],
          ],
        ),
      ],
    );
  }
}

// ======================================================================
// Kartu grafik
// ======================================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.kosong,
    required this.chart,
    required this.headers,
    required this.minWidths,
    required this.rows,
    this.firstWidth,
  });

  final String title;
  final bool kosong;
  final Widget chart;
  final List<String> headers;

  /// Lebar kolom ke-2 dan seterusnya.
  final List<double> minWidths;

  /// Jika diisi, tabel memakai lebar tetap (gulir mendatar).
  final double? firstWidth;
  final List<List<String>> rows;

  String _tsv() {
    final StringBuffer b = StringBuffer(headers.join('\t'));
    for (final List<String> row in rows) {
      b.write('\n${row.join('\t')}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(textBuilder: _tsv),
            ],
          ),
          const SizedBox(height: 13),
          if (kosong)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Tidak ada data untuk filter ini.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            chart,
          const SizedBox(height: 16),
          _GridTable(
            headers: headers,
            rows: rows,
            minWidths: minWidths,
            firstWidth: firstWidth,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Grafik garis
// ======================================================================

class _LineView extends StatelessWidget {
  const _LineView({
    required this.labels,
    required this.series,
    required this.height,
    this.fill = false,
    this.showLegend = true,
    this.fixed100 = false,
  });

  final List<String> labels;
  final List<_Seri> series;
  final double height;

  /// true = area di bawah garis diwarnai (grafik tahunan).
  final bool fill;
  final bool showLegend;

  /// true = sumbu Y 0-100% (grafik bulanan, seperti suggestedMax 100 di web).
  final bool fixed100;

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    for (final _Seri s in series) {
      for (final double? v in s.values) {
        if (v != null && v > maxValue) maxValue = v;
      }
    }
    final double interval = fixed100 ? 20 : wismanNiceInterval(maxValue);
    final double maxY = fixed100
        ? (maxValue > 100 ? (maxValue / 20).ceil() * 20.0 : 100)
        : (maxValue <= 0
              ? interval * 4
              : ((maxValue * 1.1) / interval).ceil() * interval);
    final Color muted = AppTheme.textSecondary(context);
    final double maxX = labels.length < 2 ? 1 : (labels.length - 1).toDouble();

    final Widget chart = SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> spots) {
                return spots.map((LineBarSpot s) {
                  final String nama = s.barIndex < series.length
                      ? series[s.barIndex].label
                      : '';
                  final int i = s.x.toInt();
                  final String waktu = i >= 0 && i < labels.length
                      ? labels[i]
                      : '';
                  return LineTooltipItem(
                    '$nama\n$waktu: ${okPersen(s.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (double value, TitleMeta meta) => Text(
                  '${value.round()}%',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int i = value.toInt();
                  if (value != i.toDouble() || i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (double value) =>
                FlLine(color: AppTheme.border(context), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: <LineChartBarData>[
            for (final _Seri s in series)
              LineChartBarData(
                spots: <FlSpot>[
                  for (int i = 0; i < labels.length; i++)
                    if (i < s.values.length && s.values[i] != null)
                      FlSpot(i.toDouble(), s.values[i]!)
                    else
                      FlSpot.nullSpot,
                ],
                isCurved: true,
                curveSmoothness: 0.25,
                color: s.color,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter:
                      (
                        FlSpot spot,
                        double percent,
                        LineChartBarData bar,
                        int i,
                      ) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: s.color,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: fill,
                  color: s.color.withValues(alpha: 0.12),
                ),
              ),
          ],
        ),
      ),
    );

    if (!showLegend) return chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        chart,
        const SizedBox(height: 12),
        // Provinsi bisa banyak: legenda digulir di kotak sendiri.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 110),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                for (final _Seri s in series)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Peringkat (batang horizontal)
// ======================================================================

class _RankView extends StatelessWidget {
  const _RankView({required this.rows, required this.color});

  final List<OkupansiPoint> rows;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    for (final OkupansiPoint r in rows) {
      if (r.value > maxValue) maxValue = r.value;
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < rows.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${i + 1}. ${rows[i].label}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      okPersen(rows[i].value),
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: 10,
                        color: AppTheme.surfaceMuted(context),
                      ),
                      FractionallySizedBox(
                        widthFactor: maxValue <= 0
                            ? 0
                            : (rows[i].value / maxValue).clamp(0.0, 1.0),
                        child: Container(height: 10, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ======================================================================
// Tabel + tombol salin
// ======================================================================

class _GridTable extends StatelessWidget {
  const _GridTable({
    required this.headers,
    required this.rows,
    required this.minWidths,
    this.firstWidth,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final List<double> minWidths;
  final double? firstWidth;

  @override
  Widget build(BuildContext context) {
    final Color border = AppTheme.border(context);
    final bool tetap = firstWidth != null;

    Widget sel(int col, String text, TextStyle style) {
      final Text t = Text(
        text,
        style: style,
        textAlign: col == 0 ? TextAlign.start : TextAlign.end,
      );
      if (col == 0) {
        return tetap
            ? SizedBox(width: firstWidth, child: t)
            : Expanded(child: t);
      }
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: SizedBox(width: minWidths[col - 1], child: t),
      );
    }

    Widget baris(List<String> cells, TextStyle style) {
      return Row(
        children: <Widget>[
          for (int c = 0; c < cells.length; c++) sel(c, cells[c], style),
        ],
      );
    }

    final TextStyle styleHeader = TextStyle(
      color: AppTheme.textSecondary(context),
      fontSize: 9,
      fontWeight: FontWeight.w800,
    );
    final TextStyle styleIsi = TextStyle(
      color: AppTheme.textColor(context),
      fontSize: 11,
    );

    double lebarTetap = 0;
    if (tetap) {
      lebarTetap = firstWidth! + 22;
      for (final double w in minWidths) {
        lebarTetap += w + 8;
      }
    }

    final Widget isi = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 230),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: AppTheme.surfaceMuted(context),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: baris(headers, styleHeader),
          ),
          Flexible(
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(22),
                    child: Center(
                      child: Text(
                        'Tidak ada data untuk filter ini.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < rows.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: i == rows.length - 1
                                  ? null
                                  : Border(bottom: BorderSide(color: border)),
                            ),
                            child: baris(rows[i], styleIsi),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: tetap
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: lebarTetap, child: isi),
            )
          : isi,
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.textBuilder});

  final String Function() textBuilder;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Timer? _timer;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.textBuilder()));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color warnaTeks = _copied ? Colors.white : AppTheme.primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: _copy,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _copied
              ? AppTheme.success
              : AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: _copied
                ? AppTheme.success
                : AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _copied ? Icons.check_rounded : Icons.content_paste_rounded,
              size: 14,
              color: warnaTeks,
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Tersalin' : 'Salin',
              style: TextStyle(
                color: warnaTeks,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Kerangka loading
// ======================================================================

class OkupansiChartSkeleton extends StatelessWidget {
  const OkupansiChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 2; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 14),
            SkeletonCard(
              radius: 18,
              padding: const EdgeInsets.all(18),
              margin: EdgeInsets.zero,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonBox(height: 12, radius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(height: 16, radius: 6),
                  SizedBox(height: 16),
                  SkeletonBox(height: 190, radius: 14),
                  SizedBox(height: 16),
                  SkeletonBox(height: 70, radius: 12),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
