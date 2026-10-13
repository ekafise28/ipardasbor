import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';

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