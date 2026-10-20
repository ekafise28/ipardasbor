import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bar paginasi di dasar layar: pilih jumlah per halaman, rentang data yang
/// tampil, dan tombol sebelumnya/berikutnya. Dipasang di
/// Scaffold.bottomNavigationBar supaya FAB otomatis berada di atasnya.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.total,
    required this.onPageChanged,
    required this.onPerPageChanged,
    this.enabled = true,
  });

  static const List<int> opsi = <int>[10, 25, 50];

  final int currentPage;
  final int totalPages;
  final int perPage;
  final int total;
  final bool enabled;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool adaSebelum = enabled && currentPage > 1;
    final bool adaBerikut = enabled && currentPage < totalPages;

    final int awal = total == 0 ? 0 : (currentPage - 1) * perPage + 1;
    final int akhir = math.min(currentPage * perPage, total);

    return Material(
      color: cs.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: <Widget>[
                _PerPagePill(
                  value: perPage,
                  enabled: enabled,
                  onChanged: onPerPageChanged,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$awal–$akhir dari $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Halaman $currentPage dari $totalPages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Sebelumnya',
                  style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed:
                      adaSebelum ? () => onPageChanged(currentPage - 1) : null,
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Berikutnya',
                  style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed:
                      adaBerikut ? () => onPageChanged(currentPage + 1) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerPagePill extends StatelessWidget {
  const _PerPagePill({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return PopupMenuButton<int>(
      enabled: enabled,
      initialValue: value,
      tooltip: 'Jumlah per halaman',
      position: PopupMenuPosition.over,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (int n) {
        if (n != value) onChanged(n);
      },
      itemBuilder: (_) => PaginationBar.opsi
          .map(
            (int n) => PopupMenuItem<int>(
              value: n,
              child: Text('$n per halaman'),
            ),
          )
          .toList(),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}