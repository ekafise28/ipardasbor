import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterSheetFrame, FilterSection, FilterChoiceGroup, FilterChoice;

/// Sheet filter provinsi (multi-pilih). Mengembalikan daftar terpilih
/// (kosong = semua provinsi), atau null kalau ditutup tanpa menerapkan.
Future<List<String>?> showHotelFilterSheet(
  BuildContext context, {
  required List<String> pilihan,
  required List<String> terpilih,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(pilihan: pilihan, terpilih: terpilih),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.pilihan, required this.terpilih});

  final List<String> pilihan;
  final List<String> terpilih;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<String> _pilih = <String>[...widget.terpilih];

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: 'Filter Data Hotel',
      subtitle: 'Pilih satu atau lebih provinsi',
      icon: Icons.tune_rounded,
      activeCount: _pilih.length,
      onReset: () => setState(() => _pilih = <String>[]),
      onApply: () => Navigator.of(context).pop(_pilih),
      children: <Widget>[
        FilterSection(
          label: 'Provinsi',
          hint: _pilih.isEmpty ? null : '${_pilih.length} dipilih',
          child: FilterChoiceGroup(
            multi: true,
            semuaLabel: 'Semua',
            options: <FilterChoice>[
              for (final String p in widget.pilihan)
                FilterChoice(value: p, label: p),
            ],
            selected: _pilih,
            onChanged: (List<String> v) => setState(() => _pilih = v),
          ),
        ),
      ],
    );
  }
}