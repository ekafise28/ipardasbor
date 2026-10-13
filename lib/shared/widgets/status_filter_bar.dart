import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../utils/format_number.dart';

/// Satu pilihan pada [StatusFilterBar].
class StatusFilterOption {
  const StatusFilterOption({
    required this.value,
    required this.label,
    required this.color,
    this.count,
  });

  /// Nilai yang dikirim ke filter; null berarti "Semua".
  final String? value;
  final String label;
  final Color color;

  /// Null = chip tampil tanpa angka.
  final int? count;
}

/// Baris chip filter cepat berdasarkan status (pilih satu). Dipakai bersama
/// oleh halaman yang punya hitungan per status.
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<StatusFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final StatusFilterOption o = options[i];
          final bool aktif = o.value == selected;
          final String teks = o.count == null
              ? o.label
              : '${o.label} ${formatNumber(o.count!)}';

          return ChoiceChip(
            label: Text(teks),
            selected: aktif,
            showCheckmark: false,
            onSelected: (_) => onChanged(o.value),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: aktif ? o.color : AppTheme.textSecondary(context),
            ),
            selectedColor: o.color.withValues(alpha: 0.14),
            backgroundColor: AppTheme.surface(context),
            side: BorderSide(
              color: aktif ? o.color : AppTheme.border(context),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}