import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../non_oss/models/region_option.dart';
import '../../non_oss/services/region_service.dart';
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
  State<OssBaselineOtaFilterSheet> createState() => _OssBaselineOtaFilterSheetState();
}

class _OssBaselineOtaFilterSheetState extends State<OssBaselineOtaFilterSheet> {
  late BaselineOtaFilter _draft;
  late List<RegionOption> _kabupaten;
  List<RegionOption> _kecamatan = [];
  List<RegionOption> _kelurahan = [];
  bool _loadingWilayah = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.filter.copyWith();
    _kabupaten = widget.filterOptions.kabupaten;
    if (_draft.kabupatenId != null) _muatKecamatan(_draft.kabupatenId!);
    if (_draft.kecamatanId != null) _muatKelurahan(_draft.kecamatanId!);
  }

  Future<void> _muatKecamatan(int kabupatenId) async {
    setState(() => _loadingWilayah = true);
    try {
      _kecamatan = await widget.regionService.districts(kabupatenId);
    } finally {
      if (mounted) setState(() => _loadingWilayah = false);
    }
  }

  Future<void> _muatKelurahan(int kecamatanId) async {
    setState(() => _loadingWilayah = true);
    try {
      _kelurahan = await widget.regionService.villages(kecamatanId);
    } finally {
      if (mounted) setState(() => _loadingWilayah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Baseline OTA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: () => setState(() => _draft = _draft.reset()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hanya tampil kalau akun boleh mengakses lebih dari satu provinsi.
            if (widget.filterOptions.provinsi.length > 1) ...[
              DropdownButtonFormField<int>(
                initialValue:
                    widget.filterOptions.provinsi.any((p) => p.id == _draft.provinsiId)
                        ? _draft.provinsiId
                        : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Provinsi'),
                items: widget.filterOptions.provinsi
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    _draft.provinsiId = v;
                    _draft.platformOta = null;
                    _draft.kabupatenId = null;
                    _draft.kecamatanId = null;
                    _draft.kelurahanId = null;
                    _kabupaten = [];
                    _kecamatan = [];
                    _kelurahan = [];
                  });
                  if (v != null) {
                    try {
                      final List<RegionOption> hasil =
                          await widget.regionService.regencies(v);
                      if (mounted) setState(() => _kabupaten = hasil);
                    } catch (_) {}
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<String>(
              initialValue: _draft.platformOta,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Platform OTA'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Platform')),
                ...widget.filterOptions.platformOta.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p)),
                ),
              ],
              onChanged: (v) => setState(() => _draft.platformOta = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _draft.kabupatenId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kabupaten/Kota'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kabupaten/Kota')),
                ..._kabupaten.map(
                  (k) => DropdownMenuItem(value: k.id, child: Text(k.name, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _draft.kabupatenId = v;
                  _draft.kecamatanId = null;
                  _draft.kelurahanId = null;
                  _kecamatan = [];
                  _kelurahan = [];
                });
                if (v != null) _muatKecamatan(v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _draft.kecamatanId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Kecamatan',
                enabled: _draft.kabupatenId != null,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kecamatan')),
                ..._kecamatan.map(
                  (k) => DropdownMenuItem(value: k.id, child: Text(k.name, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: _draft.kabupatenId == null
                  ? null
                  : (v) {
                      setState(() {
                        _draft.kecamatanId = v;
                        _draft.kelurahanId = null;
                        _kelurahan = [];
                      });
                      if (v != null) _muatKelurahan(v);
                    },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _draft.kelurahanId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Kelurahan/Desa',
                enabled: _draft.kecamatanId != null,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kelurahan/Desa')),
                ..._kelurahan.map(
                  (k) => DropdownMenuItem(value: k.id, child: Text(k.name, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: _draft.kecamatanId == null
                  ? null
                  : (v) => setState(() => _draft.kelurahanId = v),
            ),
            const SizedBox(height: 10),
            Text('Status Verifikasi',
                style: TextStyle(color: AppTheme.textColor(context), fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                (null, 'Semua'), ('BELUM', 'Belum'), ('SUDAH', 'Sudah'),
              ].map((e) {
                final (value, label) = e;
                return ChoiceChip(
                  label: Text(label),
                  selected: _draft.status == value,
                  onSelected: (_) => setState(() => _draft.status = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _draft),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}