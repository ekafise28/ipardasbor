// Seksi "Ikhtisar Wisman Rekap": 5 grafik + tabel data + tombol salin.
// Padanan blok wr-card di wisman_rekap.blade.php:
//   1. Total Kunjungan per Tahun   (garis, area terisi)
//   2. Perbandingan Bulanan Antar-Tahun (garis per tahun)
//   3. 10 Kewarganegaraan Terbesar (batang horizontal)
//   4. Komposisi Kewarganegaraan   (donat)
//   5. 10 Pintu Masuk Terbesar     (batang horizontal)

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../wisatawan_mancanegara/wisman_format.dart';
import '../models/rekap_dashboard_data.dart';

// Palet sama dengan web (variabel `palette`).
const List<Color> _palette = <Color>[
  Color(0xFF0756B4),
  Color(0xFF08A8C7),
  Color(0xFF16A34A),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFF64748B),
  Color(0xFF84CC16),
  Color(0xFFF97316),
];

const Color _biru = Color(0xFF0756B4);

String _persen(double v) => v.toStringAsFixed(1).replaceFirst('.', ',');

class _Seri {
  const _Seri(this.label, this.color, this.values);

  final String label;
  final Color color;
  final List<int?> values;
}

// ======================================================================
// Seksi
// ======================================================================

class RekapChartSection extends StatelessWidget {
  const RekapChartSection({
    super.key,
    required this.data,
    required this.loading,
  });

  /// null = belum ada data. Saat [loading] true tampil kerangka loading.
  final RekapDashboardData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Widget judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ikhtisar Wisman Rekap',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Data Rekap Wisatawan Mancanegara',
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
          const RekapChartSkeleton(),
        ],
      );
    }

    final RekapDashboardData? d = data;
    final List<RekapPoint> annual = d?.annual ?? const <RekapPoint>[];
    final List<RekapMonthlySeries> monthly =
        d?.monthly ?? const <RekapMonthlySeries>[];
    final List<RekapPoint> countries = d?.nationalities ?? const <RekapPoint>[];
    final List<RekapPoint> share = d?.marketShare ?? const <RekapPoint>[];
    final List<RekapPoint> ports = d?.ports ?? const <RekapPoint>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        judul,
        const SizedBox(height: 14),

        // 1. Tren historis
        _ChartCard(
          kicker: 'Tren Historis',
          title: 'Total Kunjungan per Tahun',
          kosong: annual.isEmpty,
          chart: _LineView(
            labels: <String>[for (final RekapPoint p in annual) p.label],
            series: <_Seri>[
              _Seri('Kunjungan', _biru, <int?>[
                for (final RekapPoint p in annual) p.total,
              ]),
            ],
            fill: true,
            showLegend: false,
          ),
          headers: const <String>['Tahun', 'Jumlah'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final RekapPoint p in annual)
              <String>[p.label, wismanAngka(p.total)],
          ],
        ),

        // 2. Tren bulanan antar-tahun
        const SizedBox(height: 14),
        _ChartCard(
          kicker: 'Tren Bulanan',
          title: 'Perbandingan Bulanan Antar-Tahun',
          kosong: monthly.every(
            (RekapMonthlySeries s) => s.data.every((int? v) => v == null),
          ),
          chart: _LineView(
            labels: wismanBulanSingkat,
            series: <_Seri>[
              for (int i = 0; i < monthly.length; i++)
                _Seri(
                  '${monthly[i].tahun}',
                  _palette[i % _palette.length],
                  monthly[i].data,
                ),
            ],
          ),
          headers: const <String>['Tahun', 'Bulan', 'Jumlah'],
          minWidths: const <double>[80, 76],
          rows: <List<String>>[
            for (final RekapMonthlySeries s in monthly)
              for (int i = 0; i < 12; i++)
                if (s.data[i] != null)
                  <String>[
                    '${s.tahun}',
                    wismanBulan[i],
                    wismanAngka(s.data[i]!),
                  ],
          ],
        ),

        // 3. Peringkat pasar
        const SizedBox(height: 14),
        _ChartCard(
          kicker: 'Peringkat Pasar',
          title: '10 Kewarganegaraan Terbesar',
          kosong: countries.isEmpty,
          chart: _RankView(rows: countries),
          headers: const <String>['Kategori', 'Jumlah'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final RekapPoint p in countries)
              <String>[p.label, wismanAngka(p.total)],
          ],
        ),

        // 4. Pangsa pasar
        const SizedBox(height: 14),
        _ChartCard(
          kicker: 'Pangsa Pasar',
          title: 'Komposisi Kewarganegaraan',
          kosong: share.isEmpty || share.every((RekapPoint p) => p.total == 0),
          chart: _DoughnutView(rows: share),
          headers: const <String>['Negara', 'Jumlah'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final RekapPoint p in share)
              <String>[p.label, wismanAngka(p.total)],
          ],
        ),

        // 5. Pintu kanonik
        const SizedBox(height: 14),
        _ChartCard(
          kicker: 'Pintu Kanonik',
          title: '10 Pintu Masuk Terbesar',
          kosong: ports.isEmpty,
          chart: _RankView(rows: ports),
          headers: const <String>['Kategori', 'Jumlah'],
          minWidths: const <double>[84],
          rows: <List<String>>[
            for (final RekapPoint p in ports)
              <String>[p.label, wismanAngka(p.total)],
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
    required this.kicker,
    required this.title,
    required this.kosong,
    required this.chart,
    required this.headers,
    required this.minWidths,
    required this.rows,
  });

  final String kicker;
  final String title;
  final bool kosong;
  final Widget chart;
  final List<String> headers;

  /// Lebar minimum kolom ke-2 dan seterusnya.
  final List<double> minWidths;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      kicker.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
          _GridTable(headers: headers, rows: rows, minWidths: minWidths),
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
    this.fill = false,
    this.showLegend = true,
  });

  /// Label sumbu X (satu per titik).
  final List<String> labels;
  final List<_Seri> series;

  /// true = area di bawah garis diwarnai (grafik tahunan).
  final bool fill;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    for (final _Seri s in series) {
      for (final int? v in s.values) {
        if (v != null && v > maxValue) maxValue = v.toDouble();
      }
    }
    final double interval = wismanNiceInterval(maxValue);
    final double maxY = maxValue <= 0
        ? interval * 4
        : ((maxValue * 1.1) / interval).ceil() * interval;
    final Color muted = AppTheme.textSecondary(context);
    final double maxX = labels.length < 2 ? 1 : (labels.length - 1).toDouble();

    final Widget chart = SizedBox(
      height: 260,
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
                    '$nama\n$waktu: ${wismanAngka(s.y.round())}',
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
                  wismanRingkas(value),
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
                      FlSpot(i.toDouble(), s.values[i]!.toDouble())
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
        Wrap(
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
                  Text(
                    s.label,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ======================================================================
// Peringkat (batang horizontal)
// ======================================================================

class _RankView extends StatelessWidget {
  const _RankView({required this.rows});

  final List<RekapPoint> rows;

  @override
  Widget build(BuildContext context) {
    int maxValue = 0;
    for (final RekapPoint r in rows) {
      if (r.total > maxValue) maxValue = r.total;
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
                      wismanAngka(rows[i].total),
                      style: const TextStyle(
                        color: _biru,
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
                            : (rows[i].total / maxValue).clamp(0.0, 1.0),
                        child: Container(height: 10, color: _biru),
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
// Donat
// ======================================================================

class _DoughnutView extends StatefulWidget {
  const _DoughnutView({required this.rows});

  final List<RekapPoint> rows;

  @override
  State<_DoughnutView> createState() => _DoughnutViewState();
}

class _DoughnutViewState extends State<_DoughnutView> {
  static const double _tinggi = 250;
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final List<RekapPoint> rows = widget.rows;
    int total = 0;
    for (final RekapPoint r in rows) {
      total += r.total;
    }

    final bool terpilih = _touched >= 0 && _touched < rows.length;
    final String judul = terpilih ? rows[_touched].label : 'Total';
    final int nilai = terpilih ? rows[_touched].total : total;
    final String? persen = terpilih && total > 0
        ? '${_persen(nilai / total * 100)}%'
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: _tinggi,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: _tinggi * 0.28,
                  pieTouchData: PieTouchData(
                    touchCallback:
                        (FlTouchEvent event, PieTouchResponse? response) {
                          final int index =
                              (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null)
                              ? -1
                              : response.touchedSection!.touchedSectionIndex;
                          if (index != _touched) {
                            setState(() => _touched = index);
                          }
                        },
                  ),
                  sections: <PieChartSectionData>[
                    for (int i = 0; i < rows.length; i++)
                      PieChartSectionData(
                        value: rows[i].total.toDouble(),
                        color: _palette[i % _palette.length],
                        radius: _tinggi * (i == _touched ? 0.17 : 0.15),
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              IgnorePointer(
                child: SizedBox(
                  width: _tinggi * 0.42,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 10.5,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          wismanAngka(nilai),
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (persen != null)
                        Text(
                          persen,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: <Widget>[
            for (int i = 0; i < rows.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      rows[i].label,
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
  });

  final List<String> headers;
  final List<List<String>> rows;

  /// Lebar kolom ke-2 dan seterusnya; kolom pertama mengisi sisa ruang.
  final List<double> minWidths;

  @override
  Widget build(BuildContext context) {
    final Color border = AppTheme.border(context);

    Widget baris(List<String> cells, TextStyle style) {
      return Row(
        children: <Widget>[
          for (int c = 0; c < cells.length; c++)
            if (c == 0)
              Expanded(child: Text(cells[c], style: style))
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: minWidths[c - 1],
                  child: Text(cells[c], style: style, textAlign: TextAlign.end),
                ),
              ),
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

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 230),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              color: AppTheme.surfaceMuted(context),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: baris(
                headers.map((String h) => h.toUpperCase()).toList(),
                styleHeader,
              ),
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
      ),
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

class RekapChartSkeleton extends StatelessWidget {
  const RekapChartSkeleton({super.key});

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
