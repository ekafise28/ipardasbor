import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart' show AppTheme;
import 'package:ipardasbor/shared/region/models/region_option.dart';
import 'package:ipardasbor/shared/region/region_cascade.dart'
    show RegionCascade;
import 'package:ipardasbor/shared/region/services/region_service.dart';
import 'package:ipardasbor/features/oss/models/oss_proyek_filter.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show
        FilterLabel,
        FilterSheetFrame,
        FilterDropdown,
        FilterChoice,
        FilterChoiceGroup,
        FilterSection;

/// Bottom sheet filter wilayah untuk daftar proyek OSS.
///
/// - Provinsi: hanya tampil kalau user boleh mengakses lebih dari satu.
/// - Kabupaten/kota: dari API (sudah dibatasi akses user).
/// - Kecamatan dan kelurahan: dari SQLite lokal (ID sama dengan Laravel).
///
/// Mengembalikan [OssProyekFilter] baru saat "Terapkan", atau null kalau dibatalkan.
Future<OssProyekFilter?> showOssProyekFilterSheet(
  BuildContext context, {
  required OssProyekFilter filter,
  required int? provinsiAktifId,
  required List<RegionOption> provinsiOptions,
  required List<RegionOption> kabupatenOptions,
}) {
  return showModalBottomSheet<OssProyekFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OssProyekFilterSheet(
      filter: filter,
      provinsiAktifId: provinsiAktifId,
      provinsiOptions: provinsiOptions,
      kabupatenOptions: kabupatenOptions,
    ),
  );
}

class _OssProyekFilterSheet extends StatefulWidget {
  const _OssProyekFilterSheet({
    required this.filter,
    required this.provinsiAktifId,
    required this.provinsiOptions,
    required this.kabupatenOptions,
  });

  final OssProyekFilter filter;
  final int? provinsiAktifId;
  final List<RegionOption> provinsiOptions;
  final List<RegionOption> kabupatenOptions;

  @override
  State<_OssProyekFilterSheet> createState() => _OssProyekFilterSheetState();
}

class _OssProyekFilterSheetState extends State<_OssProyekFilterSheet> {
  late int? _provinsiId = widget.filter.provinsiId ?? widget.provinsiAktifId;
  late int? _kabupatenId = widget.filter.kabupatenId;
  late int? _kecamatanId = widget.filter.kecamatanId;
  late int? _kelurahanId = widget.filter.kelurahanId;
  late String? _statusModal = widget.filter.statusPenanamanModal;
  late String? _skalaUsaha = widget.filter.uraianSkalaUsaha;
  late String? _risiko = widget.filter.uraianRisiko;
  late final RegionCascade _cascade = RegionCascade(RegionService());

  /// Jumlah bagian yang terisi di sheet (provinsi tidak dihitung, sama dengan
  /// jumlahFilterSheet di model).
  int get _aktif =>
      (_kabupatenId != null ? 1 : 0) +
      (_kecamatanId != null ? 1 : 0) +
      (_kelurahanId != null ? 1 : 0) +
      (_statusModal != null ? 1 : 0) +
      (_skalaUsaha != null ? 1 : 0) +
      (_risiko != null ? 1 : 0);

  /// True kalau provinsi diganti di sheet tapi belum diterapkan. Pilihan
  /// kabupaten dari backend masih milik provinsi lama, jadi dikunci dulu.
  bool get _provinsiBerubah =>
      widget.provinsiAktifId != null && _provinsiId != widget.provinsiAktifId;

  @override
  void initState() {
    super.initState();
    _cascade.addListener(_onCascade);
    if (_kabupatenId != null) _cascade.muatKecamatan(_kabupatenId);
    if (_kecamatanId != null) _cascade.muatKelurahan(_kecamatanId);
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

  void _pilihProvinsi(int? id) {
    setState(() {
      _provinsiId = id;
      _kabupatenId = null;
      _kecamatanId = null;
      _kelurahanId = null;
    });
    _cascade.muatKecamatan(null);
  }

  void _pilihKabupaten(int? id) {
    setState(() {
      _kabupatenId = id;
      _kecamatanId = null;
      _kelurahanId = null;
    });
    _cascade.muatKecamatan(id);
  }

  void _pilihKecamatan(int? id) {
    setState(() {
      _kecamatanId = id;
      _kelurahanId = null;
    });
    _cascade.muatKelurahan(id);
  }

  void _reset() {
    setState(() {
      _kabupatenId = null;
      _kecamatanId = null;
      _kelurahanId = null;
      _statusModal = null;
      _skalaUsaha = null;
      _risiko = null;
    });
    _cascade.muatKecamatan(null);
  }

  void _terapkan() {
    Navigator.of(context).pop(
      widget.filter.copyWith(
        provinsiId: _provinsiId,
        clearProvinsiId: _provinsiId == null,
        kabupatenId: _kabupatenId,
        clearKabupatenId: _kabupatenId == null,
        kecamatanId: _kecamatanId,
        clearKecamatanId: _kecamatanId == null,
        kelurahanId: _kelurahanId,
        clearKelurahanId: _kelurahanId == null,
        statusPenanamanModal: _statusModal,
        clearStatusPenanamanModal: _statusModal == null,
        uraianSkalaUsaha: _skalaUsaha,
        clearUraianSkalaUsaha: _skalaUsaha == null,
        uraianRisiko: _risiko,
        clearUraianRisiko: _risiko == null,
      ),
    );
  }

  /// Opsi dropdown sebagai pasangan (nilai, label) supaya satu method bisa
  /// dipakai untuk wilayah (int) maupun filter teks (String).
  List<(int, String)> _opsiRegion(List<RegionOption> daftar) => <(int, String)>[
    for (final RegionOption o in daftar) (o.id, o.name),
  ];

  @override
  Widget build(BuildContext context) {
    final bool tampilProvinsi = widget.provinsiOptions.length > 1;

    return FilterSheetFrame(
      title: 'Filter Validasi OSS',
      subtitle: 'Verifikasi Proyek dan Usaha OSS',
      icon: Icons.tune_rounded,
      activeCount: _aktif,
      onReset: _reset,
      onApply: _terapkan,
      children: <Widget>[
        if (tampilProvinsi)
          FilterDropdown<int>(
            label: 'Provinsi',
            icon: Icons.map_outlined,
            value: _provinsiId,
            options: _opsiRegion(widget.provinsiOptions),
            onChanged: _pilihProvinsi,
          ),
        FilterDropdown<int>(
          label: 'Kabupaten/Kota',
          icon: Icons.location_on_outlined,
          value: _kabupatenId,
          options: _opsiRegion(
            _provinsiBerubah ? const <RegionOption>[] : widget.kabupatenOptions,
          ),
          onChanged: _pilihKabupaten,
          semuaLabel: 'Semua kabupaten/kota',
          enabled: !_provinsiBerubah,
          helper: _provinsiBerubah
              ? 'Terapkan provinsi dulu, lalu buka filter lagi untuk memilih kabupaten/kota.'
              : null,
        ),
        FilterDropdown<int>(
          label: 'Kecamatan',
          icon: Icons.apartment_rounded,
          value: _kecamatanId,
          options: _opsiRegion(_cascade.kecamatan),
          onChanged: _pilihKecamatan,
          semuaLabel: 'Semua kecamatan',
          enabled: !_provinsiBerubah && _kabupatenId != null,
          loading: _cascade.loadingKecamatan,
          hint:
              _kabupatenId != null &&
                  !_provinsiBerubah &&
                  !_cascade.loadingKecamatan
              ? 'Siap dipilih'
              : null,
          helper: _kabupatenId == null ? 'Pilih kabupaten/kota dulu.' : null,
        ),
        FilterDropdown<int>(
          label: 'Kelurahan/Desa',
          icon: Icons.home_work_outlined,
          value: _kelurahanId,
          options: _opsiRegion(_cascade.kelurahan),
          onChanged: (int? v) => setState(() => _kelurahanId = v),
          semuaLabel: 'Semua kelurahan/desa',
          enabled: !_provinsiBerubah && _kecamatanId != null,
          loading: _cascade.loadingKelurahan,
          helper: _kecamatanId == null ? 'Pilih kecamatan dulu.' : null,
        ),
        FilterSection(
          label: 'Status Penanaman Modal',
          child: FilterChoiceGroup(
            options: <FilterChoice>[
              for (final String o in OssProyekOpsi.statusPenanamanModal)
                FilterChoice(value: o, label: o),
            ],
            selected: <String>[?_statusModal],
            onChanged: (List<String> v) =>
                setState(() => _statusModal = v.isEmpty ? null : v.first),
          ),
        ),
        FilterSection(
          label: 'Skala Usaha',
          child: FilterChoiceGroup(
            options: <FilterChoice>[
              for (final String o in OssProyekOpsi.skalaUsaha)
                FilterChoice(
                  value: o,
                  label: o.replaceFirst('Usaha ', ''), // nilai tetap utuh
                ),
            ],
            selected: <String>[?_skalaUsaha],
            onChanged: (List<String> v) =>
                setState(() => _skalaUsaha = v.isEmpty ? null : v.first),
          ),
        ),
        FilterSection(
          label: 'Tingkat Risiko Proyek',
          child: FilterChoiceGroup(
            columns: 2,
            semuaLabel: null,
            options: <FilterChoice>[
              for (final String o in OssProyekOpsi.risikoProyek)
                FilterChoice(
                  value: o,
                  label: o,
                  color: AppTheme.warnaRisiko(o),
                ),
            ],
            selected: <String>[?_risiko],
            onChanged: (List<String> v) =>
                setState(() => _risiko = v.isEmpty ? null : v.first),
          ),
        ),
      ],
    );
  }
}
