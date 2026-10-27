import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/region/region_cascade.dart'
    show RegionCascade;
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show
        FilterDropdown,
        FilterSheetFrame,
        FilterChoice,
        FilterChoiceGroup,
        FilterSection;

import '../../../../shared/region/models/region_option.dart';
import '../../../../shared/region/services/region_service.dart';
import '../models/baseline_ota_filter.dart';
import '../models/baseline_ota_page_result.dart';

/// Bottom sheet filter untuk BaselineOtaPage. Kecamatan/kelurahan diambil
/// dari RegionService generik (bukan dari filter_opsi backend, yang cuma
/// menyediakan provinsi+kabupaten+platform) - sama seperti perilaku
/// dropdown wilayah di web, yang juga generik per kabupaten/kecamatan.
class OssBaselineOtaFilterSheet extends StatefulWidget {
  const OssBaselineOtaFilterSheet({
    super.key,
    required this.filter,
    required this.filterOptions,
    required this.regionService,
  });

  final BaselineOtaFilter filter;
  final BaselineOtaFilterOptions filterOptions;
  final RegionService regionService;

  @override
  State<OssBaselineOtaFilterSheet> createState() =>
      _OssBaselineOtaFilterSheetState();
}

class _OssBaselineOtaFilterSheetState extends State<OssBaselineOtaFilterSheet> {
  late BaselineOtaFilter _draft;
  late List<RegionOption> _kabupaten;
  late final RegionCascade _cascade;

  @override
  void initState() {
    super.initState();
    _draft = widget.filter.copyWith();
    _kabupaten = widget.filterOptions.kabupaten;
    _cascade = RegionCascade(widget.regionService)..addListener(_onCascade);
    if (_draft.kabupatenId != null) {
      _cascade.muatKecamatan(_draft.kabupatenId);
    }
    if (_draft.kecamatanId != null) {
      _cascade.muatKelurahan(_draft.kecamatanId);
    }
  }

  void _onCascade() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cascade
      ..removeListener(_onCascade)
      ..dispose();
    super.dispose();
  }

  int get _aktif =>
      (_draft.kabupatenId != null ? 1 : 0) +
      (_draft.kecamatanId != null ? 1 : 0) +
      (_draft.kelurahanId != null ? 1 : 0) +
      (_draft.platformOta.isNotEmpty ? 1 : 0);

  Future<void> _pilihProvinsi(int? v) async {
    setState(() {
      _draft.provinsiId = v;
      _draft.platformOta = <String>[];
      _draft.kabupatenId = null;
      _draft.kecamatanId = null;
      _draft.kelurahanId = null;
      _kabupaten = <RegionOption>[];
    });
    _cascade.muatKecamatan(null);
    if (v == null) return;
    try {
      final List<RegionOption> hasil = await widget.regionService.regencies(v);
      if (mounted && _draft.provinsiId == v) {
        setState(() => _kabupaten = hasil);
      }
    } catch (_) {}
  }

  void _pilihKabupaten(int? v) {
    setState(() {
      _draft.kabupatenId = v;
      _draft.kecamatanId = null;
      _draft.kelurahanId = null;
    });
    _cascade.muatKecamatan(v);
  }

  void _pilihKecamatan(int? v) {
    setState(() {
      _draft.kecamatanId = v;
      _draft.kelurahanId = null;
    });
    _cascade.muatKelurahan(v);
  }

  void _reset() {
    setState(() {
      _draft.platformOta = <String>[];
      _draft.kabupatenId = null;
      _draft.kecamatanId = null;
      _draft.kelurahanId = null;
      // provinsi tidak berubah, jadi daftar kabupaten tetap dipakai
    });
    _cascade.muatKecamatan(null);
  }

  List<(int, String)> _opsiRegion(List<RegionOption> daftar) => <(int, String)>[
    for (final RegionOption o in daftar) (o.id, o.name),
  ];

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: 'Filter Baseline OTA',
      subtitle: 'Verifikasi hasil scraping baseline OTA',
      icon: Icons.tune_rounded,
      activeCount: _aktif,
      onReset: _reset,
      onApply: () => Navigator.pop(context, _draft),
      children: <Widget>[
        // Hanya tampil kalau akun boleh mengakses lebih dari satu provinsi.
        if (widget.filterOptions.provinsi.length > 1)
          FilterDropdown<int>(
            label: 'Provinsi',
            icon: Icons.map_outlined,
            value: _draft.provinsiId,
            options: _opsiRegion(widget.filterOptions.provinsi),
            onChanged: _pilihProvinsi,
          ),
        FilterSection(
          label: 'Platform OTA',
          hint: _draft.platformOta.length > 1
              ? '${_draft.platformOta.length} dipilih'
              : null,
          child: FilterChoiceGroup(
            multi: true,
            columns: 3,
            options: <FilterChoice>[
              for (final String p in widget.filterOptions.platformOta)
                FilterChoice(value: p, label: p),
            ],
            selected: _draft.platformOta,
            onChanged: (List<String> v) =>
                setState(() => _draft.platformOta = v),
          ),
        ),
        FilterDropdown<int>(
          label: 'Kabupaten/Kota',
          icon: Icons.location_on_outlined,
          value: _draft.kabupatenId,
          semuaLabel: 'Semua Kabupaten/Kota',
          options: _opsiRegion(_kabupaten),
          onChanged: _pilihKabupaten,
        ),
        FilterDropdown<int>(
          label: 'Kecamatan',
          icon: Icons.apartment_rounded,
          value: _draft.kecamatanId,
          semuaLabel: 'Semua Kecamatan',
          options: _opsiRegion(_cascade.kecamatan),
          enabled: _draft.kabupatenId != null,
          loading: _cascade.loadingKecamatan,
          onChanged: _pilihKecamatan,
        ),
        FilterDropdown<int>(
          label: 'Kelurahan/Desa',
          icon: Icons.home_work_outlined,
          value: _draft.kelurahanId,
          semuaLabel: 'Semua Kelurahan/Desa',
          options: _opsiRegion(_cascade.kelurahan),
          enabled: _draft.kecamatanId != null,
          loading: _cascade.loadingKelurahan,
          onChanged: (int? v) => setState(() => _draft.kelurahanId = v),
        ),
      ],
    );
  }
}
