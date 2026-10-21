import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

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
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Data Proyek',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 16),
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
              _Label('Versi KBLI'),
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
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _terapkan,
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary(context),
        ),
      ),
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
            _Label(label),
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