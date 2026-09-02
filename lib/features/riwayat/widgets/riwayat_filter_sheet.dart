import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
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
  late String? _statusVerifikasi = widget.filter.statusVerifikasi;
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
      _statusVerifikasi = null;
      _kabupatenId = null;
      _tanggalMulai = null;
      _tanggalSelesai = null;
    });
  }

  void _terapkan() {
    final RiwayatFilter hasil = widget.filter.copyWith(
      sumberData: _sumberData,
      clearSumberData: _sumberData == null,
      statusVerifikasi: _statusVerifikasi,
      clearStatusVerifikasi: _statusVerifikasi == null,
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
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              'Filter Riwayat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Sumber Data'),
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

            _Label('Status Verifikasi'),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final String opsi in widget.options.statusVerifikasi)
                  ChoiceChip(
                    label: Text(opsi),
                    selected: _statusVerifikasi == opsi,
                    onSelected: (bool selected) {
                      setState(() => _statusVerifikasi = selected ? opsi : null);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _Label('Kabupaten/Kota'),
            DropdownButtonFormField<int?>(
              initialValue: _kabupatenId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Semua kabupaten/kota'),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua kabupaten/kota'),
                ),
                for (final option in widget.options.kabupaten)
                  DropdownMenuItem<int?>(
                    value: option.id,
                    child: Text(option.nama),
                  ),
              ],
              onChanged: (int? value) => setState(() => _kabupatenId = value),
            ),
            const SizedBox(height: 16),

            _Label('Rentang Tanggal'),
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
            const SizedBox(height: 24),

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
    );
  }

  static String _formatTanggalSingkat(DateTime tanggal) {
    final String hari = tanggal.day.toString().padLeft(2, '0');
    final String bulan = tanggal.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${tanggal.year}';
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