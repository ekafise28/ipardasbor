import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Data satu chip filter aktif.
class FilterChipData {
  const FilterChipData({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}

/// Chip filter aktif; tiap chip bisa dihapus dengan satu ketukan.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.chips,
    required this.onResetAll,
  });

  final List<FilterChipData> chips;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          for (final FilterChipData c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(c.label),
                onDeleted: c.onRemove,
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                deleteButtonTooltipMessage: 'Hapus filter ${c.label}',
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.10),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (chips.length > 1)
            TextButton(
              onPressed: onResetAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Reset'),
            ),
        ],
      ),
    );
  }
}