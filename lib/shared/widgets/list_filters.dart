import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';

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
            side: BorderSide(color: aktif ? o.color : AppTheme.border(context)),
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

/// Label kecil di atas kolom filter.
class FilterLabel extends StatelessWidget {
  const FilterLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Kerangka bottom sheet filter: latar, sudut atas membulat, handle, judul,
/// isi yang bisa di-scroll, lalu tombol Reset dan Terapkan.
/// Pakai bersama showModalBottomSheet dengan backgroundColor transparan.
class FilterSheetFrame extends StatelessWidget {
  const FilterSheetFrame({
    super.key,
    required this.title,
    required this.children,
    required this.onReset,
    required this.onApply,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown filter berlabel. [options] berupa pasangan (nilai, label).
/// [semuaLabel] diisi = ada pilihan "semua" bernilai null.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.semuaLabel,
    this.enabled = true,
    this.loading = false,
    this.helper,
  });

  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;
  final String? semuaLabel;
  final bool enabled;
  final bool loading;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    // Nilai hanya dipakai kalau ada di daftar (hindari assertion Flutter
    // saat daftar belum selesai dimuat).
    final T? nilai = options.any(((T, String) o) => o.$1 == value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilterLabel(label),
          DropdownButtonFormField<T?>(
            // Key ikut berubah: initialValue hanya dibaca sekali.
            key: ValueKey<String>('$label-$nilai-${options.length}-$enabled'),
            initialValue: nilai,
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              helperText: helper,
              helperMaxLines: 2,
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            hint: Text(semuaLabel ?? 'Pilih'),
            items: <DropdownMenuItem<T?>>[
              if (semuaLabel != null)
                DropdownMenuItem<T?>(value: null, child: Text(semuaLabel!)),
              for (final (T, String) o in options)
                DropdownMenuItem<T?>(
                  value: o.$1,
                  child: Text(o.$2, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}