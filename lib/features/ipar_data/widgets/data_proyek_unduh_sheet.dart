import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_exception.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:share_plus/share_plus.dart';

import '../models/proyek_data_filter.dart';
import '../services/proyek_data_service.dart';

/// Sheet unduh CSV sesuai filter yang sedang aktif. [total] adalah jumlah
/// proyek pada filter itu (dari daftar), dipakai untuk menghitung progres.
Future<void> showDataProyekUnduhSheet(
  BuildContext context, {
  required ProyekDataFilter filter,
  required ProyekDataService service,
  required int total,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) =>
        _UnduhSheet(filter: filter, service: service, total: total),
  );
}

enum _Tahap { siap, mengunduh, selesai, gagal }

class _UnduhSheet extends StatefulWidget {
  const _UnduhSheet({
    required this.filter,
    required this.service,
    required this.total,
  });

  final ProyekDataFilter filter;
  final ProyekDataService service;
  final int total;

  @override
  State<_UnduhSheet> createState() => _UnduhSheetState();
}

class _UnduhSheetState extends State<_UnduhSheet> {
  int _batas = ProyekDataService.batasUnduh.first;
  _Tahap _tahap = _Tahap.siap;
  int _baris = 0;
  bool _batal = false;
  File? _file;
  String? _pesan;

  /// Jumlah baris yang benar-benar akan diunduh.
  int get _target => math.min(_batas, widget.total);

  double? get _progres =>
      _target <= 0 ? null : (_baris / _target).clamp(0.0, 1.0);

  Future<void> _mulai() async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;

    setState(() {
      _tahap = _Tahap.mengunduh;
      _baris = 0;
      _batal = false;
      _pesan = null;
    });

    try {
      final File? hasil = await widget.service.unduhCsv(
        filter: widget.filter,
        batasBaris: _batas,
        dibatalkan: () => _batal,
        onProgress: (int baris) {
          if (mounted) setState(() => _baris = baris);
        },
      );
      if (!mounted) return;

      if (hasil == null) {
        setState(() => _tahap = _Tahap.siap);
        return;
      }
      setState(() {
        _file = hasil;
        _tahap = _Tahap.selesai;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tahap = _Tahap.gagal;
        _pesan = pesanErrorRamah(e);
      });
    }
  }

  void _batalkan() => setState(() => _batal = true);

  Future<void> _bagikan() async {
    final File? f = _file;
    if (f == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(f.path, mimeType: 'text/csv')],
          subject: 'Data Proyek BKPM',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File tidak dapat dibagikan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool sibuk = _tahap == _Tahap.mengunduh;

    return PopScope(
      canPop: !sibuk,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _batalkan(); // tombol kembali saat mengunduh = batal
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Unduh Data (CSV)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mengikuti filter dan pencarian yang sedang aktif. '
              'Total ${formatNumber(widget.total)} proyek.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            if (_tahap == _Tahap.siap || _tahap == _Tahap.gagal)
              ..._pilihan(context),
            if (sibuk) ..._progresUI(context),
            if (_tahap == _Tahap.selesai) ..._selesaiUI(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _pilihan(BuildContext context) {
    return <Widget>[
      Text(
        'Jumlah baris maksimal',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary(context),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: <Widget>[
          for (final int n in ProyekDataService.batasUnduh)
            ChoiceChip(
              label: Text(formatNumber(n)),
              selected: _batas == n,
              onSelected: (_) => setState(() => _batas = n),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        widget.total == 0
            ? 'Tidak ada data untuk diunduh.'
            : 'Akan mengunduh ${formatNumber(_target)} baris pertama.',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unduhan di aplikasi dibatasi agar hemat kuota dan memori. '
                'Untuk data yang lebih lengkap, silakan unduh melalui web.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_pesan != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          _pesan!,
          style: const TextStyle(fontSize: 12.5, color: AppTheme.danger),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: widget.total == 0 ? null : _mulai,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(_tahap == _Tahap.gagal ? 'Coba lagi' : 'Unduh'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _progresUI(BuildContext context) {
    return <Widget>[
      LinearProgressIndicator(value: _progres, minHeight: 6),
      const SizedBox(height: 10),
      Text(
        _batal
            ? 'Membatalkan...'
            : '${formatNumber(math.min(_baris, _target))} dari '
                  '${formatNumber(_target)} baris',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _batal ? null : _batalkan,
          child: const Text('Batal'),
        ),
      ),
    ];
  }

  List<Widget> _selesaiUI(BuildContext context) {
    return <Widget>[
      Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${formatNumber(_baris)} baris siap dibagikan atau disimpan.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _bagikan,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Bagikan / simpan'),
            ),
          ),
        ],
      ),
    ];
  }
}