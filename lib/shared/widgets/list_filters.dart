import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';

/// Kolom pencarian halaman daftar: ikon cari, tombol hapus saat ada teks,
/// dan (opsional) contoh isian saat kolom difokuskan dan masih kosong.
///
/// Widget ini tidak mengosongkan controller sendiri. [onClear] yang
/// menentukan seluruh perilaku hapus (mengosongkan teks dan memuat ulang).
class ListSearchField extends StatelessWidget {
  const ListSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    required this.onClear,
    this.onChanged,
    this.focusNode,
    this.contohSaatFokus,
    this.keyboardType,
    this.inputFormatters,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  /// Wajib diisi kalau [contohSaatFokus] dipakai.
  final FocusNode? focusNode;

  /// Teks bantuan di bawah kolom, tampil hanya saat fokus dan masih kosong.
  final String? contohSaatFokus;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Aksi tambahan di ujung kanan (mis. tombol tempel dan scan OCR).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[controller, focusNode]),
      builder: (BuildContext context, _) {
        final bool adaTeks = controller.text.isNotEmpty;
        final bool tampilContoh =
            contohSaatFokus != null &&
            (focusNode?.hasFocus ?? false) &&
            !adaTeks;

        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: tampilContoh ? contohSaatFokus : null,
            helperMaxLines: 2,
            helperStyle: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary(context),
            ),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: (adaTeks || trailing != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (adaTeks)
                        IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: onClear,
                        ),
                        ?trailing,
                    ],
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surface(context),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}

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

/// Tombol filter di AppBar dengan lencana jumlah filter aktif. Lencana
/// disembunyikan saat [activeCount] nol. Warna ikon mengikuti
/// foregroundColor AppBar.
class FilterAction extends StatelessWidget {
  const FilterAction({
    super.key,
    required this.onPressed,
    this.activeCount = 0,
  });

  final VoidCallback onPressed;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: activeCount > 0 ? 'Filter ($activeCount aktif)' : 'Filter',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        backgroundColor: Colors.amberAccent,
        textColor: Colors.black87,
        child: const Icon(Icons.filter_list_rounded),
      ),
    );
  }
}