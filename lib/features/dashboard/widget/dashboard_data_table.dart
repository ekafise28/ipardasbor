// dashboard_data_table.dart
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Sama seperti DashboardDataTable sebelumnya, tapi sekarang pakai
/// pagination next/prev (client-side) alih-alih expand/collapse.
///
/// Cocok untuk tabel rekap yang jumlah barisnya puluhan (misal per
/// kabupaten/kota) -- semua baris sudah ada di memori dari hasil fetch,
/// jadi paging di sini cukup potong-potong List yang sudah ada, tanpa
/// perlu request ulang ke server.
///
/// Kalau ke depan ada tabel dengan ribuan baris (misal data mentah per
/// transaksi, bukan hasil GROUP BY), pendekatan ini perlu diganti jadi
/// pagination server-side (kirim `page`/`per_page` ke API).
class DashboardDataTable extends StatefulWidget {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final int rowsPerPage;

  const DashboardDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
  });

  @override
  State<DashboardDataTable> createState() => _DashboardDataTableState();
}

class _DashboardDataTableState extends State<DashboardDataTable> {
  int _page = 0;

  int get _totalPages =>
      (widget.rows.length / widget.rowsPerPage).ceil().clamp(1, 1 << 30);

  bool get _needsPagination => widget.rows.length > widget.rowsPerPage;

  List<List<String>> get _visibleRows {
    if (!_needsPagination) return widget.rows;

    final int start = _page * widget.rowsPerPage;
    final int end = (start + widget.rowsPerPage).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
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

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

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
              Container(
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
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.surfaceMuted(context),
              ),
              columns: widget.columns
                  .map(
                    (c) => DataColumn(
                      label: Text(
                        c,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: _visibleRows.map((r) {
                return DataRow(
                  cells: r
                      .map(
                        (cell) => DataCell(
                          Text(
                            cell,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }).toList(),
            ),
          ),
          if (_needsPagination) ...[const SizedBox(height: 12), _buildPager()],
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
