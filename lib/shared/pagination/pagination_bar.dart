import 'package:flutter/material.dart';

/// Bar paginasi: pilih jumlah per halaman + navigasi halaman.
/// Dipasang di Scaffold.bottomNavigationBar supaya FAB "ke atas" otomatis
/// berada di atasnya.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.onPageChanged,
    required this.onPerPageChanged,
    this.enabled = true,
  });

  static const List<int> opsi = <int>[10, 25, 50];

  final int currentPage;
  final int totalPages;
  final int perPage;
  final bool enabled;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final bool adaSebelum = enabled && currentPage > 1;
    final bool adaBerikut = enabled && currentPage < totalPages;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: <Widget>[
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: opsi.contains(perPage) ? perPage : null,
                  isDense: true,
                  items: opsi
                      .map((int n) => DropdownMenuItem<int>(
                            value: n,
                            child: Text('$n / hal'),
                          ))
                      .toList(),
                  onChanged: enabled
                      ? (int? v) {
                          if (v != null && v != perPage) onPerPageChanged(v);
                        }
                      : null,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Halaman pertama',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.first_page_rounded),
                onPressed: adaSebelum ? () => onPageChanged(1) : null,
              ),
              IconButton(
                tooltip: 'Sebelumnya',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed:
                    adaSebelum ? () => onPageChanged(currentPage - 1) : null,
              ),
              Text(
                '$currentPage / $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                tooltip: 'Berikutnya',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed:
                    adaBerikut ? () => onPageChanged(currentPage + 1) : null,
              ),
              IconButton(
                tooltip: 'Halaman terakhir',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.last_page_rounded),
                onPressed:
                    adaBerikut ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}