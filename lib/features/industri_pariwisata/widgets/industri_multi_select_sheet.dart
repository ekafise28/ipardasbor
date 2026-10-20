// Lembar pilihan (bottom sheet) multi-pilih dengan kolom pencarian.
// Padanan <select multiple> + Select2 di web.
// Pencarian penting karena daftar KBLI bisa ratusan item.

import 'package:flutter/material.dart';

import '/../../../app/app_theme.dart';
import '../models/industri_option.dart';

/// Membuka lembar pilihan. Mengembalikan daftar nilai yang dipilih,
/// atau null jika pengguna menutup lembar tanpa menekan tombol pilih.
Future<List<String>?> showIndustriMultiSelect(
  BuildContext context, {
  required String title,
  required List<IndustriOption> options,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true, // boleh tinggi, tidak dibatasi setengah layar
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _MultiSelectSheet(title: title, options: options, initial: selected),
  );
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<IndustriOption> options;
  final List<String> initial;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  // Set = kumpulan nilai tanpa duplikat; cocok untuk menyimpan yang tercentang.
  late final Set<String> _selected = {...widget.initial};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim().toLowerCase();
    final List<IndustriOption> shown = q.isEmpty
        ? widget.options
        : widget.options
              .where((o) => o.label.toLowerCase().contains(q))
              .toList();

    return Padding(
      // Naikkan isi sheet saat keyboard muncul agar kolom cari tidak tertutup.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Judul + tombol hapus semua pilihan
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Row(
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
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: const Text('Hapus pilihan'),
                  ),
                ],
              ),
            ),
            // Kolom pencarian
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Daftar pilihan (ListView.builder: hanya yang terlihat digambar)
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada pilihan.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final IndustriOption option = shown[index];
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selected.contains(option.value),
                          title: Text(
                            option.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(option.value);
                              } else {
                                _selected.remove(option.value);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            // Tombol konfirmasi
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selected.toList()),
                    child: Text(
                      _selected.isEmpty
                          ? 'Tampilkan semua data'
                          : 'Pilih (${_selected.length})',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
