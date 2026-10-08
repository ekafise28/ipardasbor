import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../models/chart_series.dart';
import 'dashboard_bar_chart.dart';
import 'dashboard_data_table.dart';

/// Satu kartu per topik: judul + toggle **Grafik | Tabel**.
///
/// - Kalau hanya salah satu (grafik/tabel) yang punya data, toggle tidak
///   ditampilkan dan konten yang ada langsung dipakai.
/// - Kalau keduanya kosong, widget tidak menggambar apa-apa.
/// - [chartBuilder] (opsional) menggantikan grafik batang vertikal bawaan,
///   mis. dengan peringkat Top N. Callback kedua yang diterimanya akan
///   memindahkan kartu ke tampilan tabel ("Lihat semua").
class DashboardChartTableCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final ChartSeriesData chartData;
  final List<String> columns;
  final List<List<String>> rows;
  final double chartHeight;

  /// Warna batang mini di tabel per kolom (lihat [DashboardDataTable]).
  final List<Color?>? columnColors;

  final Widget Function(BuildContext context, VoidCallback showTable)?
  chartBuilder;

  const DashboardChartTableCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chartData,
    required this.columns,
    required this.rows,
    this.chartHeight = 280,
    this.columnColors,
    this.chartBuilder,
  });

  @override
  State<DashboardChartTableCard> createState() =>
      _DashboardChartTableCardState();
}

class _DashboardChartTableCardState extends State<DashboardChartTableCard> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final bool hasChart =
        widget.chartData.labels.isNotEmpty &&
        widget.chartData.series.isNotEmpty;
    final bool hasTable = widget.rows.isNotEmpty;

    if (!hasChart && !hasTable) return const SizedBox.shrink();

    final bool showTable = hasTable && (!hasChart || _showTable);

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
            widget.title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (hasChart && hasTable) ...[
            const SizedBox(height: 12),
            _ViewToggle(
              showTable: showTable,
              onChanged: (value) => setState(() => _showTable = value),
            ),
          ],
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              child: KeyedSubtree(
                key: ValueKey<bool>(showTable),
                child: showTable ? _buildTable() : _buildChart(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return DashboardDataTable(
      embedded: true,
      title: widget.title,
      columns: widget.columns,
      rows: widget.rows,
      columnColors: widget.columnColors,
    );
  }

  Widget _buildChart(BuildContext context) {
    final Widget Function(BuildContext, VoidCallback)? builder =
        widget.chartBuilder;

    if (builder != null) {
      return builder(context, () => setState(() => _showTable = true));
    }

    return DashboardBarChart(
      embedded: true,
      title: widget.title,
      subtitle: widget.subtitle,
      data: widget.chartData,
      height: widget.chartHeight,
    );
  }
}

/// Toggle dua segmen kecil: Grafik | Tabel.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.showTable, required this.onChanged});

  final bool showTable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Grafik',
            icon: Icons.bar_chart_rounded,
            selected: !showTable,
            onTap: () => onChanged(false),
          ),
          _Segment(
            label: 'Tabel',
            icon: Icons.table_rows_rounded,
            selected: showTable,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    final Color color = selected ? accent : AppTheme.textSecondary(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surface(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1417243A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}