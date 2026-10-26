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

/// Label kecil huruf kapital di atas kolom filter, dengan petunjuk opsional
/// di kanan (mis. "Jawa Timur", "Siap Dipilih").
class FilterLabel extends StatelessWidget {
  const FilterLabel(this.text, {super.key, this.hint, this.hintColor});

  final String text;
  final String? hint;
  final Color? hintColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          if (hint != null)
            Text(
              hint!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: hintColor ?? AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Satu bagian filter: [FilterLabel] + isi + jarak bawah standar.
class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.hintColor,
  });

  final String label;
  final String? hint;
  final Color? hintColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilterLabel(label, hint: hint, hintColor: hintColor),
          child,
        ],
      ),
    );
  }
}

/// Kerangka bottom sheet filter: handle, header (ikon, judul, badge Aktif,
/// subjudul, tombol X), isi yang bisa di-scroll, dan footer tetap
/// (Reset + Terapkan). Pakai dengan showModalBottomSheet yang
/// isScrollControlled: true dan backgroundColor: Colors.transparent.
class FilterSheetFrame extends StatelessWidget {
  const FilterSheetFrame({
    super.key,
    required this.title,
    required this.children,
    required this.onReset,
    required this.onApply,
    this.subtitle,
    this.icon,
    this.activeCount = 0,
    this.trailing,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Badge "N Aktif" di samping judul; disembunyikan saat 0.
  final int activeCount;

  /// Widget kecil opsional di samping badge (mis. chip "98 Riwayat").
  final Widget? trailing;

  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  /// Null = menutup sheet tanpa hasil.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double maxTinggi = (mq.size.height - mq.viewInsets.bottom) * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxTinggi),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.border(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                _header(context),
                Divider(height: 1, color: AppTheme.border(context)),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount Aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ?trailing,
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton.filledTonal(
              tooltip: 'Tutup',
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Terapkan'),
            ),
          ),
        ],
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
    this.icon,
    this.hint,
  });

  final IconData? icon;

  /// Petunjuk di kanan label (mis. "Siap Dipilih").
  final String? hint;
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
          FilterLabel(label, hint: hint),
          DropdownButtonFormField<T?>(
            // Key ikut berubah: initialValue hanya dibaca sekali.
            key: ValueKey<String>('$label-$nilai-${options.length}-$enabled'),
            initialValue: nilai,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border(context)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 19, color: AppTheme.primaryColor),
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

/// Satu pilihan pada [FilterChoiceGroup]. [color] diisi = gaya berwarna
/// (titik warna + tint saat dipilih); null = gaya netral (biru + centang).
class FilterChoice {
  const FilterChoice({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;
}

/// Pilihan berbentuk chip. [multi] false = satu pilihan, true = banyak.
/// [columns] diisi = grid lebar sama (mis. 3 untuk Semua/PMDN/PMA);
/// null = wrap mengikuti lebar teks.
class FilterChoiceGroup extends StatelessWidget {
  const FilterChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multi = false,
    this.semuaLabel = 'Semua',
    this.columns,
  });

  final List<FilterChoice> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool multi;

  /// Null = tanpa chip "Semua".
  final String? semuaLabel;
  final int? columns;

  void _tekan(String value) {
    if (selected.contains(value)) {
      onChanged(selected.where((String e) => e != value).toList());
    } else if (multi) {
      onChanged(<String>[...selected, value]);
    } else {
      onChanged(<String>[value]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      if (semuaLabel != null)
        _ChoiceChip(
          label: semuaLabel!,
          aktif: selected.isEmpty,
          onTap: () => onChanged(<String>[]),
        ),
      for (final FilterChoice o in options)
        _ChoiceChip(
          label: o.label,
          color: o.color,
          aktif: selected.contains(o.value),
          onTap: () => _tekan(o.value),
        ),
    ];

    const double jarak = 8;

    if (columns == null) {
      return Wrap(spacing: jarak, runSpacing: jarak, children: chips);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double lebar = (c.maxWidth - jarak * (columns! - 1)) / columns!;
        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: <Widget>[
            for (final Widget w in chips) SizedBox(width: lebar, child: w),
          ],
        );
      },
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.aktif,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color? w = color;
    final Color latar;
    final Color garis;
    final Color teks;

    if (w == null) {
      latar = aktif ? AppTheme.primaryColor : AppTheme.surface(context);
      garis = aktif ? AppTheme.primaryColor : AppTheme.border(context);
      teks = aktif ? Colors.white : AppTheme.textColor(context);
    } else {
      latar = aktif ? w.withValues(alpha: 0.12) : AppTheme.surface(context);
      garis = aktif ? w : AppTheme.border(context);
      teks = aktif ? w : AppTheme.textColor(context);
    }

    return Material(
      color: latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: garis, width: aktif ? 1.4 : 1),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (w == null && aktif) ...<Widget>[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 5),
              ] else if (w != null) ...<Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: w, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: teks,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolom tanggal: label kecil di atas, nilai di dalam kotak berikon.
class FilterDateField extends StatelessWidget {
  const FilterDateField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.text,
  });

  final String label;
  final String placeholder;

  /// Tanggal yang sudah diformat; null = tampilkan [placeholder].
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool kosong = text == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: kosong ? FontWeight.w400 : FontWeight.w600,
                      color: kosong
                          ? AppTheme.textSecondary(context)
                          : AppTheme.textColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
