import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/bps/shared/wisatawan_bulanan.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterSheetFrame, FilterSection, FilterChoiceGroup, FilterChoice;

typedef WisatawanPilihan = ({
  List<int> tahun,
  List<String> pintuMasuk,
  List<String> provinsi,
});

/// Sheet filter Wisatawan: tahun, provinsi, dan (bila [tampilPintu]) pintu
/// masuk; semuanya multi-pilih. Mengembalikan pilihan baru saat "Terapkan",
/// atau null kalau ditutup.
Future<WisatawanPilihan?> showWisatawanFilterSheet(
  BuildContext context, {
  required Future<WisatawanOptions> Function() loadOptions,
  required List<int> tahun,
  required List<String> provinsi,
  List<String> pintuMasuk = const <String>[],
  bool tampilPintu = false,
  String title = 'Filter Wisatawan',
  String? subtitle,
}) {
  return showModalBottomSheet<WisatawanPilihan>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  final Future<WisatawanOptions> Function() loadOptions;
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

  WisatawanOptions? _opsi;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _gagal = false);
    try {
      final WisatawanOptions o = await widget.loadOptions();
      if (!mounted) return;
      setState(() => _opsi = o);
    } catch (_) {
      if (mounted) setState(() => _gagal = true);
    }
  }

  Widget _isiPilihan(Widget Function(WisatawanOptions o) bangun) {
    if (_gagal) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Pilihan gagal dimuat.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          TextButton(onPressed: _muat, child: const Text('Coba lagi')),
        ],
      );
    }
    final WisatawanOptions? o = _opsi;
    if (o == null) {
      return const SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return bangun(o);
  }

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
            (WisatawanOptions o) => FilterChoiceGroup(
              multi: true,
              semuaLabel: 'Terbaru',
              columns: 3,
              options: <FilterChoice>[
                for (final int t in o.tahun)
                  FilterChoice(value: '$t', label: '$t'),
              ],
              selected: <String>[for (final int t in _tahun) '$t'],
              onChanged: (List<String> v) => setState(
                () => _tahun = v.map(int.parse).toList()
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
              (WisatawanOptions o) => FilterChoiceGroup(
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
            (WisatawanOptions o) => FilterChoiceGroup(
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