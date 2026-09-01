import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../models/chart_series.dart';

/// Bar chart horizontal buatan sendiri (bukan fl_chart), karena fl_chart's
/// BarChart tidak punya mode horizontal native. Cocok untuk kategori
/// dengan label banyak/panjang, seperti kode KBLI pada Jenis Produk Akomodasi.
class DashboardHorizontalBarChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final ChartSeriesData data;
  final double rowHeight;

  const DashboardHorizontalBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    this.rowHeight = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (data.labels.isEmpty || data.series.isEmpty) {
      return const SizedBox.shrink();
    }

    final double maxValue = data.series
        .expand((s) => s.values)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    final double safeMax = maxValue == 0 ? 1 : maxValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _buildLegend(context),
          const SizedBox(height: 18),
          ...List.generate(data.labels.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCategoryRow(context, index, safeMax),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, int index, double safeMax) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            data.labels[index],
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.series.map((s) {
              final double value = index < s.values.length
                  ? s.values[index]
                  : 0;
              final double ratio = (value / safeMax).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: rowHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceMuted(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                height: rowHeight,
                                width: constraints.maxWidth * ratio,
                                decoration: BoxDecoration(
                                  color: s.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: data.series.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              s.name,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
