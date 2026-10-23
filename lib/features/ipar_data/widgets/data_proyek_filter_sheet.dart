import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterSheetFrame, FilterLabel;

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
      onReset: _reset,
      onApply: _terapkan,
      children: <Widget>[
        if (_tampilProvinsi)
          _PilihField(
            label: 'Provinsi',
            ringkasan: _provinsi ?? 'Pilih provinsi',
            onTap: _pilihProvinsi,
          ),
        _PilihField(
          label: 'Kabupaten/Kota',
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
          label: 'KBLI',
          ringkasan: _ringkas(_kbli, 'Semua KBLI'),
          onTap: () => _pilihMulti(
            title: 'KBLI',
            tipe: ProyekDataOptionType.kbli,
            saat: _kbli,
            simpan: (List<String> v) => _kbli = v,
          ),
          helper:
              'Memilih kode mencakup semua versi KBLI. Untuk satu '
              'versi saja, gunakan Versi KBLI di bawah.',
        ),
        FilterLabel('Versi KBLI'),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final (int? v, String teks) in <(int?, String)>[
              (null, 'Semua'),
              (2020, '2020'),
              (2025, '2025'),
            ])
              ChoiceChip(
                label: Text(teks),
                selected: _versi == v,
                onSelected: (_) => setState(() => _versi = v),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _PilihField(
          label: 'Penanaman Modal',
          ringkasan: _ringkas(_status, 'Semua'),
          onTap: () => _pilihMulti(
            title: 'Penanaman Modal',
            tipe: ProyekDataOptionType.status,
            saat: _status,
            simpan: (List<String> v) => _status = v,
          ),
        ),
        _PilihField(
          label: 'Risiko',
          ringkasan: _ringkas(_risiko, 'Semua tingkat risiko'),
          onTap: () => _pilihMulti(
            title: 'Risiko',
            tipe: ProyekDataOptionType.risiko,
            saat: _risiko,
            simpan: (List<String> v) => _risiko = v,
          ),
        ),
      ],
    );
  }
}

/// Kolom yang tampak seperti dropdown tetapi membuka pemilih. [onTap] null
/// berarti dinonaktifkan.
class _PilihField extends StatelessWidget {
  const _PilihField({
    required this.label,
    required this.ringkasan,
    required this.onTap,
    this.helper,
  });

  final String label;
  final String ringkasan;
  final VoidCallback? onTap;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FilterLabel(label),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border(context)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: <Widget>[
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
