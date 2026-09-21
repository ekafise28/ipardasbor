import 'package:flutter/material.dart';
import 'package:ipardasbor/features/non_oss/models/region_option.dart';
import 'package:ipardasbor/features/non_oss/services/region_service.dart';
import 'package:ipardasbor/features/oss/models/oss_proyek_filter.dart';

import '../../../app/app_theme.dart';

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
  final RegionService _regions = RegionService();

  late int? _provinsiId = widget.filter.provinsiId ?? widget.provinsiAktifId;
  late int? _kabupatenId = widget.filter.kabupatenId;
  late int? _kecamatanId = widget.filter.kecamatanId;
  late int? _kelurahanId = widget.filter.kelurahanId;

  List<RegionOption> _daftarKecamatan = <RegionOption>[];
  List<RegionOption> _daftarKelurahan = <RegionOption>[];
  bool _loadingKecamatan = false;
  bool _loadingKelurahan = false;

  /// True kalau provinsi diganti di sheet tapi belum diterapkan. Pilihan
  /// kabupaten dari backend masih milik provinsi lama, jadi dikunci dulu.
  bool get _provinsiBerubah =>
      widget.provinsiAktifId != null && _provinsiId != widget.provinsiAktifId;

  @override
  void initState() {
    super.initState();
    final int? kab = _kabupatenId;
    final int? kec = _kecamatanId;
    if (kab != null) _muatKecamatan(kab);
    if (kec != null) _muatKelurahan(kec);
  }

  Future<void> _muatKecamatan(int kabupatenId) async {
    setState(() => _loadingKecamatan = true);
    try {
      final List<RegionOption> hasil = await _regions.districts(kabupatenId);
      if (!mounted || _kabupatenId != kabupatenId) return;
      setState(() {
        _daftarKecamatan = hasil;
        _loadingKecamatan = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingKecamatan = false);
    }
  }

  Future<void> _muatKelurahan(int kecamatanId) async {
    setState(() => _loadingKelurahan = true);
    try {
      final List<RegionOption> hasil = await _regions.villages(kecamatanId);
      if (!mounted || _kecamatanId != kecamatanId) return;
      setState(() {
        _daftarKelurahan = hasil;
        _loadingKelurahan = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingKelurahan = false);
    }
  }

  void _pilihProvinsi(int? id) {
    setState(() {
      _provinsiId = id;
      _kabupatenId = null;
      _kecamatanId = null;
      _kelurahanId = null;
      _daftarKecamatan = <RegionOption>[];
      _daftarKelurahan = <RegionOption>[];
    });
  }

  void _pilihKabupaten(int? id) {
    setState(() {
      _kabupatenId = id;
      _kecamatanId = null;
      _kelurahanId = null;
      _daftarKecamatan = <RegionOption>[];
      _daftarKelurahan = <RegionOption>[];
    });
    if (id != null) _muatKecamatan(id);
  }

  void _pilihKecamatan(int? id) {
    setState(() {
      _kecamatanId = id;
      _kelurahanId = null;
      _daftarKelurahan = <RegionOption>[];
    });
    if (id != null) _muatKelurahan(id);
  }

  void _reset() {
    setState(() {
      _kabupatenId = null;
      _kecamatanId = null;
      _kelurahanId = null;
      _daftarKecamatan = <RegionOption>[];
      _daftarKelurahan = <RegionOption>[];
    });
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
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<RegionOption> options,
    required ValueChanged<int?> onChanged,
    String? semuaLabel,
    bool enabled = true,
    bool loading = false,
    String? helper,
  }) {
    // Nilai hanya dipakai kalau memang ada di daftar (hindari assertion
    // Flutter saat daftar belum selesai dimuat).
    final int? nilai = options.any((RegionOption o) => o.id == value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Label(label),
          DropdownButtonFormField<int?>(
            // Key ikut berubah supaya field dibangun ulang (initialValue
            // hanya dibaca sekali) saat nilai atau daftar berubah.
            key: ValueKey<String>(
              '$label-$nilai-${options.length}-$enabled',
            ),
            initialValue: nilai,
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              helperText: helper,
              helperMaxLines: 2,
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            hint: Text(semuaLabel ?? 'Pilih'),
            items: <DropdownMenuItem<int?>>[
              if (semuaLabel != null)
                DropdownMenuItem<int?>(value: null, child: Text(semuaLabel)),
              for (final RegionOption o in options)
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(o.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool tampilProvinsi = widget.provinsiOptions.length > 1;

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
                'Filter Wilayah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 16),
              if (tampilProvinsi)
                _dropdown(
                  label: 'Provinsi',
                  value: _provinsiId,
                  options: widget.provinsiOptions,
                  onChanged: _pilihProvinsi,
                ),
              _dropdown(
                label: 'Kabupaten/Kota',
                value: _kabupatenId,
                options: _provinsiBerubah
                    ? const <RegionOption>[]
                    : widget.kabupatenOptions,
                onChanged: _pilihKabupaten,
                semuaLabel: 'Semua kabupaten/kota',
                enabled: !_provinsiBerubah,
                helper: _provinsiBerubah
                    ? 'Terapkan provinsi dulu, lalu buka filter lagi untuk memilih kabupaten/kota.'
                    : null,
              ),
              _dropdown(
                label: 'Kecamatan',
                value: _kecamatanId,
                options: _daftarKecamatan,
                onChanged: _pilihKecamatan,
                semuaLabel: 'Semua kecamatan',
                enabled: !_provinsiBerubah && _kabupatenId != null,
                loading: _loadingKecamatan,
                helper: _kabupatenId == null ? 'Pilih kabupaten/kota dulu.' : null,
              ),
              _dropdown(
                label: 'Kelurahan/Desa',
                value: _kelurahanId,
                options: _daftarKelurahan,
                onChanged: (int? v) => setState(() => _kelurahanId = v),
                semuaLabel: 'Semua kelurahan/desa',
                enabled: !_provinsiBerubah && _kecamatanId != null,
                loading: _loadingKelurahan,
                helper: _kecamatanId == null ? 'Pilih kecamatan dulu.' : null,
              ),
              const SizedBox(height: 8),
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