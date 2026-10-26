import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show
        FilterSheetFrame,
        FilterLabel,
        FilterChoiceGroup,
        FilterChoice,
        FilterSection;

import '../models/proyek_data_filter.dart';
import '../models/proyek_data_option.dart';
import '../services/proyek_data_service.dart';
import 'data_proyek_option_picker.dart';

/// Sheet filter Data Proyek. [provinsiTerkunci] terisi kalau akun hanya
/// punya satu provinsi: kolom Provinsi disembunyikan dan Kab/Kota langsung
/// aktif (server yang membatasi wilayahnya).
///
/// Mengembalikan filter baru saat "Terapkan", atau null kalau dibatalkan.
Future<ProyekDataFilter?> showDataProyekFilterSheet(
  BuildContext context, {
  required ProyekDataFilter filter,
  required ProyekDataService service,
  String? provinsiTerkunci,
}) {
  return showModalBottomSheet<ProyekDataFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(
      filter: filter,
      service: service,
      provinsiTerkunci: provinsiTerkunci,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.filter,
    required this.service,
    required this.provinsiTerkunci,
  });

  final ProyekDataFilter filter;
  final ProyekDataService service;
  final String? provinsiTerkunci;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _provinsi = widget.filter.provinsi;
  late List<String> _kota = <String>[...widget.filter.kota];
  late List<String> _kbli = <String>[...widget.filter.kbli];
  late List<String> _status = <String>[...widget.filter.statusModal];
  late List<String> _risiko = <String>[...widget.filter.risiko];
  late int? _versi = widget.filter.versiKbli;

  List<ProyekDataOption>? _opsiStatus;
  List<ProyekDataOption>? _opsiRisiko;
  bool _opsiGagal = false;

  int get _aktif =>
      (_tampilProvinsi && _provinsi != null ? 1 : 0) +
      (_kota.isNotEmpty ? 1 : 0) +
      (_kbli.isNotEmpty ? 1 : 0) +
      (_status.isNotEmpty ? 1 : 0) +
      (_risiko.isNotEmpty ? 1 : 0) +
      (_versi != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _muatOpsi();
  }

  Future<void> _muatOpsi() async {
    setState(() => _opsiGagal = false);
    try {
      final List<ProyekDataOptionResult> hasil =
          await Future.wait<ProyekDataOptionResult>(
            <Future<ProyekDataOptionResult>>[
              widget.service.fetchOptions(tipe: ProyekDataOptionType.status),
              widget.service.fetchOptions(tipe: ProyekDataOptionType.risiko),
            ],
          );
      if (!mounted) return;
      setState(() {
        _opsiStatus = hasil[0].options;
        _opsiRisiko = hasil[1].options;
      });
    } catch (_) {
      if (mounted) setState(() => _opsiGagal = true);
    }
  }

  /// Chip pilihan dari server (banyak pilihan). [warna] opsional untuk gaya
  /// berwarna (risiko).
  Widget _pilihan({
    required List<ProyekDataOption>? opsi,
    required List<String> terpilih,
    required ValueChanged<List<String>> simpan,
    Color Function(ProyekDataOption o)? warna,
  }) {
    if (_opsiGagal) {
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
          TextButton(onPressed: _muatOpsi, child: const Text('Coba lagi')),
        ],
      );
    }
    if (opsi == null) {
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
    return FilterChoiceGroup(
      multi: true,
      options: <FilterChoice>[
        for (final ProyekDataOption o in opsi)
          FilterChoice(value: o.value, label: o.label, color: warna?.call(o)),
      ],
      selected: terpilih,
      onChanged: (List<String> v) => setState(() => simpan(v)),
    );
  }

  bool get _tampilProvinsi => widget.provinsiTerkunci == null;
  bool get _kotaAktif => !_tampilProvinsi || _provinsi != null;

  String _ringkas(List<String> v, String semua) => v.isEmpty
      ? semua
      : v.length == 1
      ? v.first
      : '${v.length} dipilih';

  Future<void> _pilihProvinsi() async {
    final List<String>? h = await showProyekDataOptionPicker(
      context,
      title: 'Provinsi',
      tipe: ProyekDataOptionType.provinsi,
      service: widget.service,
      selected: <String>[?_provinsi],
      single: true,
    );
    if (h == null || !mounted) return;

    final String? baru = h.isEmpty ? null : h.first;
    if (baru == _provinsi) return;
    setState(() {
      _provinsi = baru;
      _kota = <String>[]; // daftar kota milik provinsi lama
    });
  }

  Future<void> _pilihMulti({
    required String title,
    required ProyekDataOptionType tipe,
    required List<String> saat,
    required ValueChanged<List<String>> simpan,
    String? provinsi,
  }) async {
    final List<String>? h = await showProyekDataOptionPicker(
      context,
      title: title,
      tipe: tipe,
      service: widget.service,
      selected: saat,
      provinsi: provinsi,
    );
    if (h == null || !mounted) return;
    setState(() => simpan(h));
  }

  void _reset() => setState(() {
    if (_tampilProvinsi) _provinsi = null;
    _kota = <String>[];
    _kbli = <String>[];
    _status = <String>[];
    _risiko = <String>[];
    _versi = null;
  });

  void _terapkan() {
    Navigator.of(context).pop(
      ProyekDataFilter(
        provinsi: _provinsi,
        kota: _kota,
        kbli: _kbli,
        statusModal: _status,
        risiko: _risiko,
        versiKbli: _versi,
        search: widget.filter.search,
        perPage: widget.filter.perPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: 'Filter Data Proyek',
      subtitle: 'Penelusuran data proyek BKPM',
      icon: Icons.tune_rounded,
      activeCount: _aktif,
      onReset: _reset,
      onApply: _terapkan,
      children: <Widget>[
        if (_tampilProvinsi)
          _PilihField(
            label: 'Provinsi',
            icon: Icons.map_outlined,
            ringkasan: _provinsi ?? 'Pilih provinsi',
            onTap: _pilihProvinsi,
          ),
        _PilihField(
          label: 'Kabupaten/Kota',
          icon: Icons.location_on_outlined,
          hint: widget.provinsiTerkunci,
          ringkasan: _ringkas(_kota, 'Semua kabupaten/kota'),
          onTap: _kotaAktif
              ? () => _pilihMulti(
                  title: 'Kabupaten/Kota',
                  tipe: ProyekDataOptionType.kota,
                  saat: _kota,
                  provinsi: _provinsi,
                  simpan: (List<String> v) => _kota = v,
                )
              : null,
          helper: _kotaAktif ? null : 'Pilih provinsi dulu.',
        ),
        _PilihField(
          label: 'KBLI (Klasifikasi Baku Lapangan Usaha)',
          icon: Icons.search_rounded,
          ringkasan: _ringkas(_kbli, 'Semua KBLI'),
          onTap: () => _pilihMulti(
            title: 'KBLI',
            tipe: ProyekDataOptionType.kbli,
            saat: _kbli,
            simpan: (List<String> v) => _kbli = v,
          ),
          helper:
              'Memilih kode mencakup semua versi KBLI. Untuk satu versi '
              'saja, gunakan Versi KBLI di bawah.',
        ),
        FilterSection(
          label: 'Versi KBLI',
          child: FilterChoiceGroup(
            columns: 3,
            options: const <FilterChoice>[
              FilterChoice(value: '2020', label: '2020'),
              FilterChoice(value: '2025', label: '2025'),
            ],
            selected: <String>[?_versi?.toString()],
            onChanged: (List<String> v) =>
                setState(() => _versi = v.isEmpty ? null : int.parse(v.first)),
          ),
        ),
        FilterSection(
          label: 'Penanaman Modal',
          child: _pilihan(
            opsi: _opsiStatus,
            terpilih: _status,
            simpan: (List<String> v) => _status = v,
          ),
        ),
        FilterSection(
          label: 'Tingkat Risiko',
          child: _pilihan(
            opsi: _opsiRisiko,
            terpilih: _risiko,
            simpan: (List<String> v) => _risiko = v,
            warna: (ProyekDataOption o) => AppTheme.warnaRisiko(o.label),
          ),
        ),
      ],
    );
  }
}

class _PilihField extends StatelessWidget {
  const _PilihField({
    required this.label,
    required this.ringkasan,
    required this.onTap,
    this.icon,
    this.hint,
    this.helper,
  });

  final String label;
  final String ringkasan;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? hint;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return FilterSection(
      label: label,
      hint: hint,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 19, color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        ringkasan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
            if (helper != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  helper!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
