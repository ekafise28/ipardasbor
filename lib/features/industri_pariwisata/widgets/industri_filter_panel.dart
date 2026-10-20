// Panel filter: Tahun, Provinsi, Kabupaten/Kota, KBLI + tombol Reset/Terapkan.
// Widget ini "bodoh": hanya menampilkan dan memberi tahu perubahan lewat
// callback. Penyimpanan state ada di halaman (industri_pariwisata_page.dart).

import 'package:flutter/material.dart';

import '/../../../app/app_theme.dart';
import '../models/industri_filter.dart';
import '../models/industri_option.dart';
import 'industri_multi_select_sheet.dart';

class IndustriFilterPanel extends StatelessWidget {
  const IndustriFilterPanel({
    super.key,
    required this.filter,
    required this.options,
    required this.kotaOptions,
    required this.loading,
    required this.onTahunChanged,
    required this.onProvinsiChanged,
    required this.onKotaChanged,
    required this.onKbliChanged,
    required this.onApply,
    required this.onReset,
  });

  final IndustriFilter filter;
  final IndustriFilterOptions options;
  final List<IndustriOption> kotaOptions;
  final bool loading;

  final ValueChanged<List<String>> onTahunChanged;
  final ValueChanged<List<String>> onProvinsiChanged;
  final ValueChanged<List<String>> onKotaChanged;
  final ValueChanged<List<String>> onKbliChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppTheme.textColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter Dashboard',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: loading ? null : onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          Text(
            'Pilih satu atau beberapa parameter untuk memperbarui seluruh data.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          _SelectorField(
            label: 'Tahun',
            options: options.years,
            selected: filter.tahun,
            onChanged: onTahunChanged,
          ),
          const SizedBox(height: 12),
          _SelectorField(
            label: 'Provinsi',
            options: options.provinsi,
            selected: filter.provinsi,
            onChanged: onProvinsiChanged,
          ),
          const SizedBox(height: 12),
          // Kab/Kota baru bisa dipilih setelah provinsi dipilih (seperti web).
          _SelectorField(
            label: 'Kabupaten/Kota',
            options: kotaOptions,
            selected: filter.kota,
            enabled: filter.provinsi.isNotEmpty,
            disabledHint: 'Pilih provinsi terlebih dahulu',
            onChanged: onKotaChanged,
          ),
          const SizedBox(height: 12),
          _SelectorField(
            label: 'Kode KBLI',
            options: options.kbli,
            selected: filter.kbli,
            onChanged: onKbliChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onApply,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.filter_alt_rounded, size: 18),
              label: Text(loading ? 'Memuat data...' : 'Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu kolom pilihan. Diketuk -> membuka lembar multi-pilih.
class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.disabledHint = '',
  });

  final String label;
  final List<IndustriOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String disabledHint;

  /// Mencari teks tampilan dari nilai yang tersimpan.
  String _labelOf(String value) {
    for (final IndustriOption option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Future<void> _open(BuildContext context) async {
    final List<String>? result = await showIndustriMultiSelect(
      context,
      title: label,
      options: options,
      selected: selected,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    const int maxChips = 3; // sisanya diringkas jadi "+N"

    final Widget content;
    if (selected.isEmpty) {
      content = Text(
        enabled ? 'Semua data' : disabledHint,
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      );
    } else {
      content = Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final String value in selected.take(maxChips))
            _Chip(text: _labelOf(value)),
          if (selected.length > maxChips)
            _Chip(text: '+${selected.length - maxChips}'),
        ],
      );
    }

    return InkWell(
      onTap: enabled ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: false, // label selalu di atas
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          isDense: true,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: content,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
