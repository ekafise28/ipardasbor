import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';

import '../models/chart_series.dart';

/// Peringkat Top N dalam batang horizontal, cocok untuk layar ponsel.
///
/// Urutan ditentukan oleh seri ke-[rankSeriesIndex] (mis. "Total"). Setiap
/// baris menampilkan satu batang:
///  - jalur latar sepanjang nilai seri peringkat (Total), dan
///  - segmen berwarna dari seri lainnya (mis. OSS lalu Non OSS) yang digambar
///    di atasnya dengan skala yang sama.
/// Kalau OSS + Non OSS sama dengan Total, batang terisi penuh. Kalau tidak,
/// selisihnya terlihat apa adanya sebagai jalur abu-biru, tanpa asumsi apa pun
/// tentang data.
class DashboardRankedBarChart extends StatelessWidget {
  const DashboardRankedBarChart({
    super.key,
    required this.data,
    this.rankSeriesIndex = 0,
    this.topN = 10,
    this.itemLabel = 'kabupaten/kota',
    this.onShowAll,
  });

  final ChartSeriesData data;
  final int rankSeriesIndex;
  final int topN;

  /// Sebutan item untuk teks keterangan, mis. "kabupaten/kota".
  final String itemLabel;

  /// Dipanggil saat "Lihat semua" ditekan (biasanya pindah ke tampilan tabel).
  final VoidCallback? onShowAll;

  double _valueOf(BarSeries series, int index) =>
      index < series.values.length ? series.values[index] : 0;

  @override
  Widget build(BuildContext context) {
    if (data.labels.isEmpty ||
        data.series.isEmpty ||
        rankSeriesIndex >= data.series.length) {
      return const SizedBox.shrink();
    }

    final BarSeries rank = data.series[rankSeriesIndex];
    final List<BarSeries> others = [
      for (int i = 0; i < data.series.length; i++)
        if (i != rankSeriesIndex) data.series[i],
    ];

    final List<int> sorted = List<int>.generate(data.labels.length, (i) => i)
      ..sort((a, b) => _valueOf(rank, b).compareTo(_valueOf(rank, a)));
    final List<int> shown = sorted.take(topN).toList();

    final double maxValue = shown.isEmpty ? 0 : _valueOf(rank, shown.first);
    final double safeMax = maxValue <= 0 ? 1 : maxValue;
    final Color track = AppTheme.categoryTotal.withValues(alpha: 0.22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top ${shown.length} dari ${data.labels.length} $itemLabel '
          'berdasarkan ${rank.name.toLowerCase()}',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(context, others, rank, track),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double barWidth = constraints.maxWidth;

            return Column(
              children: [
                for (int position = 0; position < shown.length; position++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: position == shown.length - 1 ? 0 : 14,
                    ),
                    child: _buildRow(
                      context: context,
                      position: position,
                      index: shown[position],
                      rank: rank,
                      others: others,
                      safeMax: safeMax,
                      barWidth: barWidth,
                      track: track,
                    ),
                  ),
              ],
            );
          },
        ),
        if (onShowAll != null && data.labels.length > shown.length) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(Icons.table_rows_rounded, size: 16),
              label: Text('Lihat semua ${data.labels.length} $itemLabel'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required int position,
    required int index,
    required BarSeries rank,
    required List<BarSeries> others,
    required double safeMax,
    required double barWidth,
    required Color track,
  }) {
    const double barHeight = 10;

    final double rankValue = _valueOf(rank, index);
    double trackWidth = (rankValue / safeMax).clamp(0.0, 1.0) * barWidth;
    if (rankValue > 0 && trackWidth < 4) trackWidth = 4;

    // Segmen berwarna, dipotong supaya tidak melewati lebar baris.
    double remaining = barWidth;
    final List<Widget> segments = [];
    for (final BarSeries series in others) {
      double w = (_valueOf(series, index) / safeMax) * barWidth;
      w = w.clamp(0.0, remaining);
      remaining -= w;
      if (w > 0) {
        segments.add(Container(width: w, height: barHeight, color: series.color));
      }
    }

    final String detail = others
        .map((s) => '${s.name} ${formatNumber(_valueOf(s, index).round())}')
        .join('  •  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${position + 1}.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                data.labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatNumber(rankValue.round()),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: SizedBox(
            width: barWidth,
            height: barHeight,
            child: Stack(
              children: [
                Container(width: trackWidth, height: barHeight, color: track),
                Row(mainAxisSize: MainAxisSize.min, children: segments),
              ],
            ),
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<BarSeries> others,
    BarSeries rank,
    Color track,
  ) {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final BarSeries series in others) item(series.color, series.name),
        item(track, rank.name),
      ],
    );
  }
}