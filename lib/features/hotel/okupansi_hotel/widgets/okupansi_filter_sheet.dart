import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterSheetFrame, FilterSection, FilterChoiceGroup, FilterChoice;

import '../models/okupansi_hotel_data.dart';
import '../services/okupansi_hotel_service.dart';

typedef OkupansiPilihan = ({List<int> tahun, List<String> provinsi});

/// Sheet filter tahun dan provinsi (keduanya multi-pilih). Mengembalikan
/// pilihan baru saat "Terapkan", atau null kalau ditutup.
Future<OkupansiPilihan?> showOkupansiFilterSheet(
  BuildContext context, {
  required OkupansiHotelService service,
  required List<int> tahun,
  required List<String> provinsi,
}) {
  return showModalBottomSheet<OkupansiPilihan>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(service: service, tahun: tahun, provinsi: provinsi),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.service,
    required this.tahun,
    required this.provinsi,
  });

  final OkupansiHotelService service;
  final List<int> tahun;
  final List<String> provinsi;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<int> _tahun = <int>[...widget.tahun];
  late List<String> _provinsi = <String>[...widget.provinsi];

  OkupansiHotelOptions? _opsi;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _gagal = false);
    try {
      final OkupansiHotelOptions o = await widget.service.fetchOptions();
      if (!mounted) return;
      setState(() => _opsi = o);
    } catch (_) {
      if (mounted) setState(() => _gagal = true);
    }
  }

  Widget _isiPilihan(Widget Function(OkupansiHotelOptions o) bangun) {
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
    final OkupansiHotelOptions? o = _opsi;
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
      title: 'Filter Okupansi',
      subtitle: 'Tahun dan provinsi',
      icon: Icons.tune_rounded,
      activeCount: (_tahun.isNotEmpty ? 1 : 0) + (_provinsi.isNotEmpty ? 1 : 0),
      onReset: () => setState(() {
        _tahun = <int>[];
        _provinsi = <String>[];
      }),
      onApply: () => Navigator.of(context).pop((tahun: _tahun, provinsi: _provinsi)),
      children: <Widget>[
        FilterSection(
          label: 'Tahun',
          hint: _tahun.isEmpty ? 'Terbaru' : '${_tahun.length} dipilih',
          child: _isiPilihan(
            (OkupansiHotelOptions o) => FilterChoiceGroup(
              multi: true,
              semuaLabel: 'Terbaru',
              columns: 3,
              options: <FilterChoice>[
                for (final int t in o.tahun) FilterChoice(value: '$t', label: '$t'),
              ],
              selected: <String>[for (final int t in _tahun) '$t'],
              onChanged: (List<String> v) => setState(
                () => _tahun = v.map(int.parse).toList()..sort((int a, int b) => b.compareTo(a)),
              ),
            ),
          ),
        ),
        FilterSection(
          label: 'Provinsi',
          hint: _provinsi.isEmpty ? null : '${_provinsi.length} dipilih',
          child: _isiPilihan(
            (OkupansiHotelOptions o) => FilterChoiceGroup(
              multi: true,
              semuaLabel: 'Semua',
              options: <FilterChoice>[
                for (final String p in o.provinsi) FilterChoice(value: p, label: p),
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