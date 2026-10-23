import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show FilterLabel, FilterSheetFrame, FilterDropdown;

import '../../../app/app_theme.dart';
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
      onReset: _reset,
      onApply: _terapkan,
      children: <Widget>[
        FilterDropdown<String>(
          label: 'Bidang Usaha',
          value: _bidangUsaha,
          semuaLabel: 'Semua bidang',
          options: <(String, String)>[
            for (final BidangUsahaOpsi b in BidangUsahaOpsi.daftar)
              (b.slug, b.nama),
          ],
          onChanged: (String? v) => setState(() => _bidangUsaha = v),
        ),

        FilterLabel('Sumber Data'),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final String opsi in widget.options.sumberData)
              ChoiceChip(
                label: Text(opsi),
                selected: _sumberData == opsi,
                onSelected: (bool selected) {
                  setState(() => _sumberData = selected ? opsi : null);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        FilterDropdown<int>(
          label: 'Kabupaten/Kota',
          value: _kabupatenId,
          semuaLabel: 'Semua kabupaten/kota',
          options: <(int, String)>[
            for (final o in widget.options.kabupaten) (o.id, o.nama),
          ],
          onChanged: (int? v) => setState(() => _kabupatenId = v),
        ),

        FilterLabel('Rentang Tanggal'),
        Row(
          children: <Widget>[
            Expanded(
              child: _TanggalButton(
                label: _tanggalMulai == null
                    ? 'Dari tanggal'
                    : _formatTanggalSingkat(_tanggalMulai!),
                onTap: () => _pilihTanggal(mulai: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TanggalButton(
                label: _tanggalSelesai == null
                    ? 'Sampai tanggal'
                    : _formatTanggalSingkat(_tanggalSelesai!),
                onTap: () => _pilihTanggal(mulai: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static String _formatTanggalSingkat(DateTime tanggal) {
    final String hari = tanggal.day.toString().padLeft(2, '0');
    final String bulan = tanggal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tanggal.year}';
  }
}

class _TanggalButton extends StatelessWidget {
  const _TanggalButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
