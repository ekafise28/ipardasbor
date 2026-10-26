import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterLabel, FilterSheetFrame, FilterDropdown, FilterDateField, FilterChoice, FilterChoiceGroup, FilterSection;

import '../../../core/constants/bidang_usaha_constants.dart';

import '../models/riwayat_filter.dart';
import '../models/riwayat_page_result.dart';

/// Bottom sheet untuk mengatur filter: sumber data, status, kabupaten,
/// dan rentang tanggal.
///
/// Dipanggil lewat [showRiwayatFilterSheet]. Mengembalikan [RiwayatFilter]
/// baru saat user menekan "Terapkan", atau null kalau dibatalkan.
Future<RiwayatFilter?> showRiwayatFilterSheet(
  BuildContext context, {
  required RiwayatFilter filter,
  required RiwayatFilterOptions options,
}) {
  return showModalBottomSheet<RiwayatFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RiwayatFilterSheet(filter: filter, options: options),
  );
}

class _RiwayatFilterSheet extends StatefulWidget {
  const _RiwayatFilterSheet({required this.filter, required this.options});

  final RiwayatFilter filter;
  final RiwayatFilterOptions options;

  @override
  State<_RiwayatFilterSheet> createState() => _RiwayatFilterSheetState();
}

class _RiwayatFilterSheetState extends State<_RiwayatFilterSheet> {
  late String? _sumberData = widget.filter.sumberData;
  late String? _bidangUsaha = widget.filter.bidangUsaha;
  late int? _kabupatenId = widget.filter.kabupatenId;
  late DateTime? _tanggalMulai = widget.filter.tanggalMulai;
  late DateTime? _tanggalSelesai = widget.filter.tanggalSelesai;

  /// Jumlah bagian yang terisi di sheet ini (rentang tanggal dihitung satu).
  int get _aktif =>
      (_sumberData != null ? 1 : 0) +
      (_bidangUsaha != null ? 1 : 0) +
      (_kabupatenId != null ? 1 : 0) +
      ((_tanggalMulai != null || _tanggalSelesai != null) ? 1 : 0);

  Future<void> _pilihTanggal({required bool mulai}) async {
    final DateTime sekarang = DateTime.now();
    final DateTime? hasil = await showDatePicker(
      context: context,
      initialDate: (mulai ? _tanggalMulai : _tanggalSelesai) ?? sekarang,
      firstDate: DateTime(2020),
      lastDate: sekarang,
    );

    if (hasil == null) {
      return;
    }

    setState(() {
      if (mulai) {
        _tanggalMulai = hasil;
      } else {
        _tanggalSelesai = hasil;
      }
    });
  }

  void _reset() {
    setState(() {
      _sumberData = null;
      _bidangUsaha = null;
      _kabupatenId = null;
      _tanggalMulai = null;
      _tanggalSelesai = null;
    });
  }

  void _terapkan() {
    final RiwayatFilter hasil = widget.filter.copyWith(
      sumberData: _sumberData,
      clearSumberData: _sumberData == null,
      bidangUsaha: _bidangUsaha,
      clearBidangUsaha: _bidangUsaha == null,
      kabupatenId: _kabupatenId,
      clearKabupatenId: _kabupatenId == null,
      tanggalMulai: _tanggalMulai,
      clearTanggalMulai: _tanggalMulai == null,
      tanggalSelesai: _tanggalSelesai,
      clearTanggalSelesai: _tanggalSelesai == null,
    );

    Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheetFrame(
      title: 'Filter Riwayat',
      subtitle: 'Data Pengawasan yang Telah Dilakukan',
      icon: Icons.tune_rounded,
      activeCount: _aktif,
      onReset: _reset,
      onApply: _terapkan,
      children: <Widget>[
        FilterDropdown<String>(
          label: 'Bidang Usaha',
          icon: Icons.apartment_rounded,
          value: _bidangUsaha,
          semuaLabel: 'Semua bidang',
          options: <(String, String)>[
            for (final BidangUsahaOpsi b in BidangUsahaOpsi.daftar)
              (b.slug, b.nama),
          ],
          onChanged: (String? v) => setState(() => _bidangUsaha = v),
        ),
        FilterSection(
          label: 'Sumber Data',
          hint: _sumberData == null ? null : 'Tersaring: $_sumberData',
          child: FilterChoiceGroup(
            options: <FilterChoice>[
              for (final String o in widget.options.sumberData)
                FilterChoice(value: o, label: o),
            ],
            selected: <String>[?_sumberData],
            onChanged: (List<String> v) =>
                setState(() => _sumberData = v.isEmpty ? null : v.first),
          ),
        ),
        FilterDropdown<int>(
          label: 'Kabupaten/Kota',
          icon: Icons.location_on_outlined,
          value: _kabupatenId,
          semuaLabel: 'Semua kabupaten/kota',
          options: <(int, String)>[
            for (final option in widget.options.kabupaten)
              (option.id, option.nama),
          ],
          onChanged: (int? v) => setState(() => _kabupatenId = v),
        ),
        FilterSection(
          label: 'Rentang Tanggal Pengawasan',
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilterDateField(
                  label: 'Dari Tanggal',
                  placeholder: 'Pilih tanggal',
                  text: _tanggalMulai == null
                      ? null
                      : _formatTanggalSingkat(_tanggalMulai!),
                  onTap: () => _pilihTanggal(mulai: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilterDateField(
                  label: 'Sampai Tanggal',
                  placeholder: 'Pilih tanggal',
                  text: _tanggalSelesai == null
                      ? null
                      : _formatTanggalSingkat(_tanggalSelesai!),
                  onTap: () => _pilihTanggal(mulai: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTanggalSingkat(DateTime tanggal) {
    final String hari = tanggal.day.toString().padLeft(2, '0');
    final String bulan = tanggal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tanggal.year}';
  }
}