// Seksi "Ikhtisar Strategis": 4 grafik + tabel data + tombol salin + perbesar.
// Padanan blok chart-wrap, chart-data-panel, dan modal detail di
// resources/views/dashboard/pariwisata/index.blade.php.
//
// Grafik memakai paket fl_chart (sudah dipakai di fitur Dashboard).

import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../industri_format.dart';
import '../models/industri_dashboard_data.dart';

// Palet warna sama persis dengan versi web (variabel `palette`).
const List<Color> _palette = <Color>[
  Color(0xFF0756A4),
  Color(0xFF0F91B9),
  Color(0xFF18A27C),
  Color(0xFF675FC1),
  Color(0xFFF0A43A),
  Color(0xFFE26565),
  Color(0xFF5F84A8),
  Color(0xFF45B7AA),
  Color(0xFF9B72CF),
  Color(0xFFD77F44),
];

// Warna batang grafik Perkembangan Total Usaha di web.
const Color _warnaBatang = Color(0xFF0B6BB6);

/// 1234567 -> "1,2 jt", 85000 -> "85 rb". Untuk label sumbu Y yang sempit.
String _ringkas(double v) {
  String rapikan(double x) {
    final String s = x.toStringAsFixed(1);
    return s.endsWith('.0')
        ? s.substring(0, s.length - 2)
        : s.replaceFirst('.', ',');
  }

  if (v >= 1000000) return '${rapikan(v / 1000000)} jt';
  if (v >= 1000) return '${rapikan(v / 1000)} rb';
  return v.round().toString();
}

/// 12.5 -> "12,5"
String _persen(double v) => v.toStringAsFixed(1).replaceFirst('.', ',');

/// Jarak antar garis sumbu Y yang "bulat" (1, 2, 5 x 10^n), sekitar 4 garis.
double _niceInterval(double max) {
  if (max <= 0) return 1;
  final double raw = max / 4;
  final double magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final double normalized = raw / magnitude;
  final double nice = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return nice * magnitude;
}

// ======================================================================
// Judul seksi (dipakai juga oleh tabel peringkat)
// ======================================================================

class IndustriSectionTitle extends StatelessWidget {
  const IndustriSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Seksi 4 grafik
// ======================================================================

class IndustriChartSection extends StatelessWidget {
  const IndustriChartSection({
    super.key,
    required this.data,
    required this.loading,
  });

  /// null = belum ada data. Saat [loading] true tampil skeleton, selain itu
  /// kartu tampil kosong ("Tidak ada data untuk filter ini.").
  final IndustriDashboardData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const Widget judul = IndustriSectionTitle(
      title: 'Ikhtisar Strategis',
      subtitle: 'Visualisasi utama kondisi usaha pariwisata.',
    );

    if (data == null && loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          judul,
          SizedBox(height: 14),
          IndustriChartSkeleton(),
        ],
      );
    }

    final IndustriDashboardData? d = data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        judul,
        const SizedBox(height: 14),
        IndustriChartCard(
          kicker: 'Tren Tahunan',
          title: 'Perkembangan Total Usaha',
          tableTitle: 'Data Perkembangan Usaha',
          labelHeader: 'Tahun',
          data: d?.tahun,
          bar: true,
        ),
        const SizedBox(height: 14),
        IndustriChartCard(
          kicker: 'Komposisi',
          title: 'Skala Usaha',
          tableTitle: 'Data Skala Usaha',
          labelHeader: 'Skala Usaha',
          data: d?.skala,
        ),
        const SizedBox(height: 14),
        IndustriChartCard(
          kicker: 'Profil Risiko',
          title: 'Tingkat Risiko Proyek',
          tableTitle: 'Data Tingkat Risiko',
          labelHeader: 'Tingkat Risiko',
          data: d?.risiko,
        ),
        const SizedBox(height: 14),
        IndustriChartCard(
          kicker: 'Investasi',
          title: 'Status Penanaman Modal',
          tableTitle: 'Data Penanaman Modal',
          labelHeader: 'Status Modal',
          data: d?.modal,
        ),
      ],
    );
  }
}

// ======================================================================
// Satu kartu grafik
// ======================================================================

class IndustriChartCard extends StatelessWidget {
  const IndustriChartCard({
    super.key,
    required this.kicker,
    required this.title,
    required this.tableTitle,
    required this.labelHeader,
    required this.data,
    this.bar = false,
  });

  final String kicker;
  final String title;
  final String tableTitle;
  final String labelHeader;
  final IndustriChartData? data;

  /// true = grafik batang (Tahun), false = donat.
  final bool bar;

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
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
                      color: AppTheme.border(sheetContext),
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
                          color: AppTheme.textColor(sheetContext),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: _ChartView(
                      data: data,
                      bar: bar,
                      height: bar ? 340 : 300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  onTap: () => _openDetail(context),
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
          _ChartView(data: data, bar: bar, height: bar ? 260 : 210),
          _DataPanel(title: tableTitle, labelHeader: labelHeader, data: data),
        ],
      ),
    );
  }
}

// ======================================================================
// Grafik
// ======================================================================

class _ChartView extends StatelessWidget {
  const _ChartView({
    required this.data,
    required this.bar,
    required this.height,
  });

  final IndustriChartData? data;
  final bool bar;
  final double height;

  @override
  Widget build(BuildContext context) {
    final IndustriChartData? d = data;
    final bool kosong = d == null || d.isEmpty || (!bar && d.total == 0);

    if (kosong) {
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

    if (bar) {
      return SizedBox(
        height: height,
        child: _BarView(data: d),
      );
    }
    return _DoughnutView(data: d, height: height);
  }
}

class _BarView extends StatelessWidget {
  const _BarView({required this.data});

  final IndustriChartData data;

  @override
  Widget build(BuildContext context) {
    final List<double> values = data.values
        .map((int v) => v.toDouble())
        .toList();
    final double maxValue = values.fold<double>(0, math.max);
    final double interval = _niceInterval(maxValue);
    final double maxY = maxValue <= 0
        ? interval * 4
        : ((maxValue * 1.1) / interval).ceil() * interval;
    final Color muted = AppTheme.textSecondary(context);
    final double lebarBatang = values.length > 8 ? 12 : 22;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final String label = groupIndex < data.labels.length
                  ? data.labels[groupIndex]
                  : '';
              return BarTooltipItem(
                '$label: ${formatAngka(rod.toY.round())}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
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
              getTitlesWidget: (value, meta) => Text(
                _ringkas(value),
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= data.labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data.labels[index],
                    style: TextStyle(color: muted, fontSize: 10),
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppTheme.border(context), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List<BarChartGroupData>.generate(values.length, (int i) {
          return BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: values[i],
                color: _warnaBatang,
                width: lebarBatang,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DoughnutView extends StatefulWidget {
  const _DoughnutView({required this.data, required this.height});

  final IndustriChartData data;
  final double height;

  @override
  State<_DoughnutView> createState() => _DoughnutViewState();
}

class _DoughnutViewState extends State<_DoughnutView> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final IndustriChartData data = widget.data;
    final double h = widget.height;
    final int total = data.total;

    final bool terpilih =
        _touched >= 0 &&
        _touched < data.labels.length &&
        _touched < data.values.length;
    final String judul = terpilih ? data.labels[_touched] : 'Total';
    final int nilai = terpilih ? data.values[_touched] : total;
    final String? persen = terpilih && total > 0
        ? '${_persen(nilai / total * 100)}%'
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: h * 0.28,
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
                    for (int i = 0; i < data.values.length; i++)
                      PieChartSectionData(
                        value: data.values[i].toDouble(),
                        color: _palette[i % _palette.length],
                        radius: h * (i == _touched ? 0.17 : 0.15),
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              // Teks di tengah donat: total, atau irisan yang disentuh.
              IgnorePointer(
                child: SizedBox(
                  width: h * 0.42,
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
                          formatAngka(nilai),
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
        // Legenda di bawah grafik (sama seperti web).
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: <Widget>[
            for (int i = 0; i < data.labels.length; i++)
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
                      data.labels[i],
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
// Tabel data di bawah grafik + tombol "Salin ke Excel"
// ======================================================================

class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.title,
    required this.labelHeader,
    required this.data,
  });

  final String title;
  final String labelHeader;
  final IndustriChartData? data;

  /// Teks yang disalin: kolom dipisah tab, supaya langsung rapi saat
  /// ditempel ke Excel. Angka disalin mentah (tanpa titik ribuan).
  String _tsv() {
    final StringBuffer b = StringBuffer('$labelHeader\tJumlah Usaha');
    final IndustriChartData? d = data;
    if (d != null) {
      for (int i = 0; i < d.labels.length; i++) {
        final int v = i < d.values.length ? d.values[i] : 0;
        b.write('\n${d.labels[i]}\t$v');
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sesuai grafik dan filter aktif',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(textBuilder: _tsv),
            ],
          ),
          const SizedBox(height: 11),
          _DataTable(labelHeader: labelHeader, data: data),
        ],
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
              _copied ? 'Berhasil Disalin' : 'Salin ke Excel',
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

class _DataTable extends StatelessWidget {
  const _DataTable({required this.labelHeader, required this.data});

  final String labelHeader;
  final IndustriChartData? data;

  @override
  Widget build(BuildContext context) {
    final IndustriChartData? d = data;
    final List<String> labels = d?.labels ?? const <String>[];
    final List<int> values = d?.values ?? const <int>[];
    final Color border = AppTheme.border(context);
    final TextStyle styleHeader = TextStyle(
      color: AppTheme.textSecondary(context),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(labelHeader.toUpperCase(), style: styleHeader),
                  ),
                  Text('JUMLAH USAHA', style: styleHeader),
                ],
              ),
            ),
            Flexible(
              child: labels.isEmpty
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
                          for (int i = 0; i < labels.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                border: i == labels.length - 1
                                    ? null
                                    : Border(bottom: BorderSide(color: border)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      labels[i],
                                      style: TextStyle(
                                        color: AppTheme.textColor(context),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatAngka(
                                      i < values.length ? values[i] : 0,
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
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

// ======================================================================
// Skeleton seksi grafik (dipakai saat data pertama belum datang)
// ======================================================================

class IndustriChartSkeleton extends StatelessWidget {
  const IndustriChartSkeleton({super.key});

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
