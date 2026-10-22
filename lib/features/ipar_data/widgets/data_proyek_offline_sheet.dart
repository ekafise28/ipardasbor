import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_exception.dart';
import 'package:ipardasbor/core/cache/cache_preferences.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';

import '../models/proyek_data_filter.dart';
import '../offline/proyek_offline_meta.dart';
import '../offline/proyek_offline_service.dart';
import '../offline/proyek_offline_store.dart';

/// Sheet unduh manual data untuk dipakai offline. [total] adalah jumlah
/// proyek pada filter aktif (untuk menghitung target dan progres).
Future<void> showDataProyekOfflineSheet(
  BuildContext context, {
  required ProyekDataFilter filter,
  required int total,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _OfflineSheet(filter: filter, total: total),
  );
}

enum _Tahap { siap, mengunduh, selesai, gagal }

class _OfflineSheet extends StatefulWidget {
  const _OfflineSheet({required this.filter, required this.total});

  final ProyekDataFilter filter;
  final int total;

  @override
  State<_OfflineSheet> createState() => _OfflineSheetState();
}

class _OfflineSheetState extends State<_OfflineSheet> {
  final ProyekOfflineService _service = ProyekOfflineService();
  final CachePreferences _pref = CachePreferences.instance;

  int _batas = ProyekOfflineService.pilihanBaris.first;
  _Tahap _tahap = _Tahap.siap;
  int _baris = 0;
  int _ukuran = 0;
  bool _batal = false;
  String? _pesan;
  ProyekOfflineHasil? _hasil;
  ProyekOfflineMeta? _meta;

  int get _target => math.min(_batas, widget.total);

  double? get _progres =>
      _target <= 0 ? null : (_baris / _target).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _muatMeta();
  }

  Future<void> _muatMeta() async {
    final ProyekOfflineMeta? m = await ProyekOfflineStore.instance.meta();
    if (mounted) setState(() => _meta = m);
  }

  Future<void> _mulai() async {
    if (!_pref.enabled) {
      setState(() {
        _tahap = _Tahap.gagal;
        _pesan =
            'Aktifkan "Simpan data untuk mode offline" di Pengaturan > '
            'Data Offline terlebih dahulu.';
      });
      return;
    }
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;

    setState(() {
      _tahap = _Tahap.mengunduh;
      _baris = 0;
      _ukuran = 0;
      _batal = false;
      _pesan = null;
    });

    try {
      final ProyekOfflineHasil? h = await _service.unduh(
        filter: widget.filter,
        targetBaris: _target,
        dibatalkan: () => _batal,
        onProgress: (int b, int u) {
          if (mounted) {
            setState(() {
              _baris = b;
              _ukuran = u;
            });
          }
        },
      );
      if (!mounted) return;

      await _muatMeta();
      if (!mounted) return;

      if (h == null) {
        setState(() => _tahap = _Tahap.siap); // dibatalkan
      } else if (h.baris == 0) {
        setState(() {
          _tahap = _Tahap.gagal;
          _pesan = h.terpotongBatas
              ? 'Batas ukuran terlalu kecil untuk menyimpan data ini. '
                    'Naikkan batas di Pengaturan > Data Offline.'
              : 'Tidak ada data yang bisa diunduh.';
        });
      } else {
        setState(() {
          _hasil = h;
          _tahap = _Tahap.selesai;
        });
      }
    } catch (e) {
      if (!mounted) return;
      await _muatMeta();
      if (!mounted) return;
      setState(() {
        _tahap = _Tahap.gagal;
        _pesan = pesanErrorRamah(e);
      });
    }
  }

  Future<void> _hapus() async {
    await ProyekOfflineStore.instance.hapus();
    await _muatMeta();
  }

  String _tanggal(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bool sibuk = _tahap == _Tahap.mengunduh;

    return PopScope(
      canPop: !sibuk,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) setState(() => _batal = true);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Unduh untuk Offline',
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
                ..._siapUI(context),
              if (sibuk) ..._progresUI(),
              if (_tahap == _Tahap.selesai) ..._selesaiUI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kotak(BuildContext context, List<Widget> anak) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceMuted(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: anak),
  );

  List<Widget> _siapUI(BuildContext context) {
    final ProyekOfflineMeta? m = _meta;
    final TextStyle kecil = TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: AppTheme.textSecondary(context),
    );

    return <Widget>[
      if (m != null) ...<Widget>[
        _kotak(context, <Widget>[
          Text(
            'Tersimpan: ${formatNumber(m.baris)} baris · '
            '${formatUkuranBytes(m.ukuranBytes)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text('${m.ringkasanFilter} · ${_tanggal(m.savedAt)}', style: kecil),
        ]),
        const SizedBox(height: 14),
      ],
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
          for (final int n in ProyekOfflineService.pilihanBaris)
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
            : 'Akan mengunduh ${formatNumber(_target)} baris pertama. '
                  'Batas ukuran: ${_pref.proyekOfflineMaxMb} MB '
                  '(atur di Pengaturan > Data Offline).',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _kotak(context, <Widget>[
        Text(
          'Data yang diunduh menggantikan data offline sebelumnya. Saat '
          'tidak ada koneksi, daftar, filter, dan pencarian hanya berlaku '
          'pada data yang sudah diunduh. Untuk data yang lebih lengkap, '
          'silakan unduh melalui web.',
          style: kecil,
        ),
      ]),
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
          if (m != null) ...<Widget>[
            IconButton.outlined(
              tooltip: 'Hapus data offline',
              onPressed: _hapus,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 8),
          ],
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
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(_tahap == _Tahap.gagal ? 'Coba lagi' : 'Unduh'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _progresUI() {
    return <Widget>[
      LinearProgressIndicator(value: _progres, minHeight: 6),
      const SizedBox(height: 10),
      Text(
        _batal
            ? 'Membatalkan...'
            : '${formatNumber(_baris)} dari ${formatNumber(_target)} baris · '
                  '${formatUkuranBytes(_ukuran)} dari '
                  '${_pref.proyekOfflineMaxMb} MB',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _batal ? null : () => setState(() => _batal = true),
          child: const Text('Batal'),
        ),
      ),
    ];
  }

  List<Widget> _selesaiUI() {
    final ProyekOfflineHasil h = _hasil!;
    return <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            h.terpotongBatas
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            color: h.terpotongBatas
                ? AppTheme.warning
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              h.terpotongBatas
                  ? 'Dihentikan karena batas ukuran tercapai. '
                        '${formatNumber(h.baris)} baris tersimpan '
                        '(${formatUkuranBytes(h.ukuranBytes)}). Naikkan batas '
                        'di Pengaturan > Data Offline untuk menyimpan lebih '
                        'banyak.'
                  : '${formatNumber(h.baris)} baris tersimpan untuk offline '
                        '(${formatUkuranBytes(h.ukuranBytes)}).',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ),
    ];
  }
}