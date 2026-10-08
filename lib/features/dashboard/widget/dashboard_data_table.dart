// dashboard_data_table.dart
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';

/// Tabel rekap dengan:
///  - header yang bisa diketuk untuk mengurutkan (naik/turun),
///  - kolom pertama (nama) terkunci saat tabel digeser ke samping,
///  - batang mini di sel angka (opsional, lewat [columnColors]),
///  - pagination next/prev (client-side).
///
/// Cocok untuk tabel rekap yang jumlah barisnya puluhan (misal per
/// kabupaten/kota) -- semua baris sudah ada di memori dari hasil fetch,
/// jadi sorting dan paging di sini cukup memotong List yang sudah ada, tanpa
/// request ulang ke server.
///
/// Kalau ke depan ada tabel dengan ribuan baris (misal data mentah per
/// transaksi, bukan hasil GROUP BY), pendekatan ini perlu diganti jadi
/// sorting + pagination server-side (kirim `sort`/`page`/`per_page` ke API).
class DashboardDataTable extends StatefulWidget {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final int rowsPerPage;

  /// Kalau true, widget hanya menggambar badge jumlah baris + tabel, tanpa
  /// kartu dan judul. Dipakai di dalam [DashboardChartTableCard].
  final bool embedded;

  /// Warna batang mini per kolom, indeks sama dengan [columns]. Indeks 0
  /// (kolom nama) diabaikan. Elemen null atau daftar null = tanpa batang.
  final List<Color?>? columnColors;

  const DashboardDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
    this.embedded = false,
    this.columnColors,
  });

  @override
  State<DashboardDataTable> createState() => _DashboardDataTableState();
}

class _DashboardDataTableState extends State<DashboardDataTable> {
  static const double _labelWidth = 128;
  static const double _cellWidth = 96;
  static const double _rowHeight = 46;
  static const double _headerHeight = 44;

  int _page = 0;
  int? _sortColumn;
  bool _sortAscending = false;

  int get _totalPages =>
      (widget.rows.length / widget.rowsPerPage).ceil().clamp(1, 1 << 30);

  bool get _needsPagination => widget.rows.length > widget.rowsPerPage;

  int? get _activeSortColumn {
    final int? column = _sortColumn;
    if (column == null || column >= widget.columns.length) return null;
    return column;
  }

  List<List<String>> get _sortedRows {
    final int? column = _activeSortColumn;
    if (column == null) return widget.rows;

    final List<List<String>> sorted = List<List<String>>.of(widget.rows);
    sorted.sort((a, b) {
      final String x = column < a.length ? a[column] : '';
      final String y = column < b.length ? b[column] : '';

      final int result;
      if (column == 0) {
        result = x.toLowerCase().compareTo(y.toLowerCase());
      } else {
        result = (num.tryParse(x) ?? 0).compareTo(num.tryParse(y) ?? 0);
      }

      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  List<List<String>> _pageRows(List<List<String>> sorted) {
    if (!_needsPagination) return sorted;

    final int start = _page * widget.rowsPerPage;
    final int end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant DashboardDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kalau data berubah (misal habis apply filter baru) dan halaman
    // sekarang jadi di luar jangkauan, kembalikan ke halaman pertama.
    if (oldWidget.rows != widget.rows && _page >= _totalPages) {
      _page = 0;
    }
  }

  void _goToPage(int page) {
    setState(() => _page = page.clamp(0, _totalPages - 1));
  }

  void _onSort(int column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        // Kolom nama paling wajar A-Z dulu, kolom angka paling besar dulu.
        _sortAscending = column == 0;
      }
      _page = 0;
    });
  }

  List<double> _columnMaxima() {
    return List<double>.generate(widget.columns.length, (column) {
      if (column == 0) return 0;
      double max = 0;
      for (final List<String> row in widget.rows) {
        if (column >= row.length) continue;
        final double value = num.tryParse(row[column])?.toDouble() ?? 0;
        if (value > max) max = value;
      }
      return max;
    });
  }

  Color? _barColor(int column) {
    final List<Color?>? colors = widget.columnColors;
    if (colors == null || column >= colors.length) return null;
    return colors[column];
  }

  Widget _rowCountBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${widget.rows.length} baris',
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final List<List<String>> visible = _pageRows(_sortedRows);

    final Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTable(context, visible),
        if (_needsPagination) ...[const SizedBox(height: 12), _buildPager()],
      ],
    );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _rowCountBadge(context),
          ),
          const SizedBox(height: 10),
          table,
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _rowCountBadge(context),
            ],
          ),
          const SizedBox(height: 14),
          table,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tabel
  // ---------------------------------------------------------------------

  Widget _buildTable(BuildContext context, List<List<String>> visible) {
    final List<double> maxima = _columnMaxima();
    final Color borderColor = AppTheme.border(context);

    final Widget frozen = SizedBox(
      width: _labelWidth,
      child: Column(
        children: [
          _headerCell(context, 0, width: _labelWidth, showRightBorder: true),
          for (final List<String> row in visible)
            _labelCell(context, row.isNotEmpty ? row[0] : '-'),
        ],
      ),
    );

    final Widget scrolling = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: [
              for (int c = 1; c < widget.columns.length; c++)
                _headerCell(context, c, width: _cellWidth),
            ],
          ),
          for (final List<String> row in visible)
            Row(
              children: [
                for (int c = 1; c < widget.columns.length; c++)
                  _valueCell(
                    context,
                    c < row.length ? row[c] : '0',
                    maxima[c],
                    _barColor(c),
                  ),
              ],
            ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            frozen,
            Expanded(child: scrolling),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(
    BuildContext context,
    int column, {
    required double width,
    bool showRightBorder = false,
  }) {
    final bool active = _activeSortColumn == column;
    final String label = widget.columns[column];

    return Semantics(
      button: true,
      label: 'Urutkan berdasarkan $label',
      child: InkWell(
        onTap: () => _onSort(column),
        child: Container(
          width: width,
          height: _headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            border: Border(
              right: showRightBorder
                  ? BorderSide(color: AppTheme.border(context))
                  : BorderSide.none,
              bottom: BorderSide(color: AppTheme.border(context)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.2,
                    color: active
                        ? AppTheme.primaryColor
                        : AppTheme.textColor(context),
                  ),
                ),
              ),
              if (active)
                Icon(
                  _sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppTheme.primaryColor,
                )
              else
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelCell(BuildContext context, String text) {
    return Container(
      width: _labelWidth,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.border(context)),
          bottom: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor(context),
        ),
      ),
    );
  }

  Widget _valueCell(
    BuildContext context,
    String text,
    double columnMax,
    Color? barColor,
  ) {
    final int? asInt = int.tryParse(text);
    final double? asNumber = num.tryParse(text)?.toDouble();
    final String display = asInt != null ? formatNumber(asInt) : text;

    final double ratio = (barColor != null && asNumber != null && columnMax > 0)
        ? (asNumber / columnMax).clamp(0.0, 1.0)
        : 0;

    return Container(
      width: _cellWidth,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            display,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
          if (ratio > 0) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio < 0.04 ? 0.04 : ratio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPager() {
    final int start = _page * widget.rowsPerPage + 1;
    final int end = (start - 1 + widget.rowsPerPage).clamp(
      0,
      widget.rows.length,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            'Menampilkan $start-$end dari ${widget.rows.length}',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ),
        _PagerButton(
          icon: Icons.chevron_left_rounded,
          enabled: _page > 0,
          onTap: () => _goToPage(_page - 1),
        ),
        const SizedBox(width: 8),
        Text(
          'Hal ${_page + 1} / $_totalPages',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        _PagerButton(
          icon: Icons.chevron_right_rounded,
          enabled: _page < _totalPages - 1,
          onTap: () => _goToPage(_page + 1),
        ),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagerButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppTheme.primaryColor.withValues(alpha: 0.10)
          : AppTheme.surfaceMuted(context),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 19,
            color: enabled ? AppTheme.primaryColor : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}