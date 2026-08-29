import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_series.dart';

class DashboardBarChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final ChartSeriesData data;
  final double height;

  const DashboardBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    if (data.labels.isEmpty || data.series.isEmpty) {
      return const SizedBox.shrink();
    }

    final double maxY = data.series
        .expand((s) => s.values)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D17243A), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF17243A), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Color(0xFF7A879A), fontSize: 12, height: 1.35)),
          const SizedBox(height: 14),
          _buildLegend(),
          const SizedBox(height: 14),
          SizedBox(
            height: height,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (data.labels.length * 70).toDouble().clamp(300, double.infinity),
                child: BarChart(
                  BarChartData(
                    maxY: maxY == 0 ? 1 : maxY * 1.2,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final String seriesName = data.series[rodIndex].name;
                          return BarTooltipItem(
                            '$seriesName: ${rod.toY.toInt()}',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Color(0xFF667085), fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            if (index < 0 || index >= data.labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Text(
                                  data.labels[index],
                                  style: const TextStyle(color: Color(0xFF667085), fontSize: 9),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY == 0 ? 1 : maxY / 4,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Color(0x2E94A3B8), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.labels.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: data.series.map((s) {
                          return BarChartRodData(
                            toY: index < s.values.length ? s.values[index] : 0,
                            color: s.color,
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          );
                        }).toList(),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: data.series.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(s.name, style: const TextStyle(color: Color(0xFF344156), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        );
      }).toList(),
    );
  }
}