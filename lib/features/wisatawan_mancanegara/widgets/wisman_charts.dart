// Seksi "Ikhtisar Operasional": 6 grafik Wisman + tabel data + tombol salin
// + tampilan diperbesar. Padanan x-wisman-chart-card di web.
//
// Grafik garis memakai fl_chart; peringkat 10 teratas digambar sebagai
// batang horizontal sederhana (fl_chart tidak punya bar horizontal).

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../models/wisman_dashboard_data.dart';
import '../wisman_format.dart';

const List<Color> _warnaTahun = <Color>[
  Color(0xFF0B5ED7),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
];

const Color _warnaBatang = Color(0xFF0B5ED7);

/// Warna garis perbandingan pintu: hue dibagi rata seperti di web.
Color _warnaGaris(int index, int total) {
  final double hue = (index * 360 / (total < 1 ? 1 : total)).roundToDouble();
  return HSLColor.fromAHSL(1, hue % 360, 0.78, 0.48).toColor();
}

class _Seri {
  const _Seri(this.label, this.color, this.values);

  final String label;
  final Color color;
  final List<int?> values;
}

// ======================================================================
// Seksi
// ======================================================================

class WismanChartSection extends StatelessWidget {
  const WismanChartSection({
    super.key,
    required this.data,
    required this.loading,
  });

  /// null = belum ada data. Saat [loading] true tampil kerangka loading.
  final WismanDashboardData? data;
  final bool loading;

  static const String _kosong = 'Tidak ada data untuk filter ini.';

  @override
  Widget build(BuildContext context) {
    final Widget judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ikhtisar Operasional',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Perbandingan kunjungan bulanan menurut jenis pintu masuk, '
          'provinsi/lokasi, dan tahun.',
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
          const WismanChartSkeleton(),
        ],
      );
    }

    final WismanDashboardData? d = data;
    final List<WismanMonthlySeries> monthly =
        d?.monthly ?? const <WismanMonthlySeries>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        judul,
        const SizedBox(height: 14),

        // 1. Perbandingan kunjungan antar-tahun
        _ChartCard(
          kicker: 'Tren Bulanan',
          title: 'Perbandingan Kunjungan Antar-Tahun',
          kosong: monthly.every(
            (WismanMonthlySeries s) => s.data.every((int? v) => v == null),
          ),
          chart: (bool besar) => _LineView(
            series: <_Seri>[
              for (int i = 0; i < monthly.length; i++)
                _Seri(
                  '${monthly[i].tahun}',
                  _warnaTahun[i % _warnaTahun.length],
                  monthly[i].data,
                ),
            ],
            height: besar ? 340 : 260,
          ),
          headers: const <String>['Tahun', 'Bulan', 'Jumlah'],
          minWidths: const <double>[80, 76],
          rows: <List<String>>[
            for (final WismanMonthlySeries s in monthly)
              for (int i = 0; i < 12; i++)
                if (s.data[i] != null)
                  <String>[
                    '${s.tahun}',
                    wismanBulan[i],
                    wismanAngka(s.data[i]!),
                  ],
          ],
        ),

        // 2-4. Perbandingan pintu darat / laut / udara
        const SizedBox(height: 14),
        _gateCard(
          'Perbandingan Pintu Darat',
          d?.gateLand ?? const <WismanGateSeries>[],
        ),
        const SizedBox(height: 14),
        _gateCard(
          'Perbandingan Pintu Laut',
          d?.gateSea ?? const <WismanGateSeries>[],
        ),
        const SizedBox(height: 14),
        _gateCard(
          'Perbandingan Pintu Udara',
          d?.gateAir ?? const <WismanGateSeries>[],
        ),

        // 5-6. Peringkat (tetap, tidak ikut filter)
        const SizedBox(height: 14),
        _rankCard(
          'Peringkat',
          '10 Pintu Masuk Terbesar',
          d?.topGates ?? const <WismanRank>[],
        ),
        const SizedBox(height: 14),
        _rankCard(
          'Persebaran',
          '10 Provinsi/Lokasi Terbesar',
          d?.topProvinces ?? const <WismanRank>[],
        ),
      ],
    );
  }

  Widget _gateCard(String title, List<WismanGateSeries> rows) {
    return _ChartCard(
      kicker: 'Tren Bulanan',
      title: title,
      kosong: rows.isEmpty,
      chart: (bool besar) => _LineView(
        series: <_Seri>[
          for (int i = 0; i < rows.length; i++)
            _Seri(rows[i].label, _warnaGaris(i, rows.length), rows[i].months),
        ],
        height: besar ? 340 : 260,
      ),
      headers: <String>['Provinsi/Lokasi', 'Tahun', ...wismanBulanSingkat],
      // Lebar tetap + gulir mendatar: tabelnya 14 kolom.
      minWidths: const <double>[
        52,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
      ],
      firstWidth: 150,
      rows: <List<String>>[
        for (final WismanGateSeries r in rows)
          <String>[
            r.province,
            '${r.year}',
            for (final int? v in r.months) v == null ? '—' : wismanAngka(v),
          ],
      ],
    );
  }

  Widget _rankCard(String kicker, String title, List<WismanRank> rows) {
    return _ChartCard(
      kicker: kicker,
      title: title,
      kosong: rows.isEmpty,
      note: 'Peringkat tetap seluruh data',
      chart: (bool besar) => _RankView(rows: rows),
      headers: const <String>['Kategori', 'Jumlah'],
      minWidths: const <double>[84],
      rows: <List<String>>[
        for (final WismanRank r in rows)
          <String>[r.label, wismanAngka(r.total)],
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
    this.firstWidth,
    this.note = 'Data sesuai filter aktif',
  });

  final String kicker;
  final String title;
  final bool kosong;

  /// Pembuat grafik. Parameter true = tampilan diperbesar.
  final Widget Function(bool besar) chart;

  final List<String> headers;

  /// Lebar minimum kolom ke-2 dan seterusnya.
  final List<double> minWidths;

  /// Jika diisi, tabel memakai lebar tetap (gulir mendatar).
  final double? firstWidth;

  final List<List<String>> rows;
  final String note;

  void _perbesar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheet) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(sheet),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textColor(sheet),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheet).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: kosong ? _kosongView(sheet, 300) : chart(true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kosongView(BuildContext context, double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          'Tidak ada data untuk filter ini.',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

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
              Tooltip(
                message: 'Perbesar grafik',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _perbesar(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          kosong ? _kosongView(context, 180) : chart(false),
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyButton(textBuilder: _tsv),
                  ],
                ),
                const SizedBox(height: 11),
                _GridTable(
                  headers: headers,
                  rows: rows,
                  minWidths: minWidths,
                  firstWidth: firstWidth,
                ),
              ],
            ),
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
  const _LineView({required this.series, required this.height});

  final List<_Seri> series;
  final double height;

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

    final Widget chart = SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> spots) {
                return spots.map((LineBarSpot s) {
                  final String nama = s.barIndex < series.length
                      ? series[s.barIndex].label
                      : '';
                  final int bulan = s.x.toInt().clamp(0, 11);
                  return LineTooltipItem(
                    '$nama\n${wismanBulanSingkat[bulan]}: ${wismanAngka(s.y.round())}',
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
                  if (value != i.toDouble() || i < 0 || i > 11) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      wismanBulanSingkat[i],
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
                  for (int i = 0; i < 12; i++)
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
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        chart,
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 96),
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
  const _RankView({required this.rows});

  final List<WismanRank> rows;

  @override
  Widget build(BuildContext context) {
    int maxValue = 0;
    for (final WismanRank r in rows) {
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
                        color: _warnaBatang,
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
                        child: Container(height: 10, color: _warnaBatang),
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
              _copied ? 'Tersalin' : 'Salin ke Excel',
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

class WismanChartSkeleton extends StatelessWidget {
  const WismanChartSkeleton({super.key});

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
