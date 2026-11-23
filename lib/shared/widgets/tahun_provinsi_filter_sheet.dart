import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/app_sheet.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart' show FilterOptions;

typedef FilterPilihan = ({
  List<int> tahun,
  List<String> pintuMasuk,
  List<String> provinsi,
});

/// Sheet filter Wisatawan: tahun, provinsi, dan (bila [tampilPintu]) pintu
/// masuk; semuanya multi-pilih. Mengembalikan pilihan baru saat "Terapkan",
/// atau null kalau ditutup.
Future<FilterPilihan?> showTahunProvinsiFilterSheet(
  BuildContext context, {
  required Future<FilterOptions> Function() loadOptions,
  required List<int> tahun,
  required List<String> provinsi,
  List<String> pintuMasuk = const <String>[],
  bool tampilPintu = false,
  String title = 'Filter',
  String? subtitle,
}) {
  return showAppSheet<FilterPilihan>(
    context,
    transparan: true,
    builder: (_) => _FilterSheet(
      loadOptions: loadOptions,
      tahun: tahun,
      provinsi: provinsi,
      pintuMasuk: pintuMasuk,
      tampilPintu: tampilPintu,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.loadOptions,
    required this.tahun,
    required this.provinsi,
    required this.pintuMasuk,
    required this.tampilPintu,
    required this.title,
    required this.subtitle,
  });

  final Future<FilterOptions> Function() loadOptions;
  final List<int> tahun;
  final List<String> provinsi;
  final List<String> pintuMasuk;
  final bool tampilPintu;
  final String title;
  final String? subtitle;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<int> _tahun = <int>[...widget.tahun];
  late List<String> _provinsi = <String>[...widget.provinsi];
  late List<String> _pintu = <String>[...widget.pintuMasuk];

  late final PemuatOpsi<FilterOptions> _opsi;

  @override
  void initState() {
    super.initState();
    _opsi = PemuatOpsi<FilterOptions>(widget.loadOptions);
  }

  @override
  void dispose() {
    _opsi.dispose();
    super.dispose();
  }

  Widget _isiPilihan(Widget Function(FilterOptions o) bangun) =>
      IsiPilihan<FilterOptions>(pemuat: _opsi, bangun: bangun);

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: Icons.tune_rounded,
      activeCount:
          (_tahun.isNotEmpty ? 1 : 0) +
          (widget.tampilPintu && _pintu.isNotEmpty ? 1 : 0) +
          (_provinsi.isNotEmpty ? 1 : 0),
      onReset: () => setState(() {
        _tahun = <int>[];
        _pintu = <String>[];
        _provinsi = <String>[];
      }),
      onApply: () => Navigator.of(
        context,
      ).pop((tahun: _tahun, pintuMasuk: _pintu, provinsi: _provinsi)),
      children: <Widget>[
        FilterSection(
          label: 'Tahun',
          hint: _tahun.isEmpty ? 'Terbaru' : '${_tahun.length} dipilih',
          child: _isiPilihan(
            (FilterOptions o) => FilterChoiceGroup(
              multi: true,
              semuaLabel: 'Terbaru',
              columns: 3,
              options: <FilterChoice>[
                for (final int t in o.tahun)
                  FilterChoice(value: '$t', label: '$t'),
              ],
              selected: <String>[for (final int t in _tahun) '$t'],
              onChanged: (List<String> v) => setState(
                () =>
                    _tahun = v.map(int.parse).toList()
                      ..sort((int a, int b) => b.compareTo(a)),
              ),
            ),
          ),
        ),
        if (widget.tampilPintu)
          FilterSection(
            label: 'Pintu Masuk',
            hint: _pintu.isEmpty ? null : '${_pintu.length} dipilih',
            child: _isiPilihan(
              (FilterOptions o) => FilterChoiceGroup(
                multi: true,
                semuaLabel: 'Semua',
                options: <FilterChoice>[
                  for (final String p in o.pintuMasuk)
                    FilterChoice(value: p, label: p),
                ],
                selected: _pintu,
                onChanged: (List<String> v) => setState(() => _pintu = v),
              ),
            ),
          ),
        FilterSection(
          label: 'Provinsi',
          hint: _provinsi.isEmpty ? null : '${_provinsi.length} dipilih',
          child: _isiPilihan(
            (FilterOptions o) => FilterChoiceGroup(
              multi: true,
              semuaLabel: 'Semua',
              options: <FilterChoice>[
                for (final String p in o.provinsi)
                  FilterChoice(value: p, label: p),
              ],
              selected: _provinsi,
              onChanged: (List<String> v) => setState(() => _provinsi = v),
            ),
          ),
        ),
      ],
    );
  }
}
