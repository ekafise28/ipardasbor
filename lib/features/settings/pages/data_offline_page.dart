import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/cache/api_cache.dart';
import '../../../core/cache/cache_preferences.dart';
import '../../../core/cache/cache_status.dart';
import '../../../shared/utils/formatters.dart';

/// Pengaturan penyimpanan data offline (cache otomatis).
///
/// Data yang pernah dibuka dengan internet (dashboard, riwayat, daftar OSS,
/// Data Proyek, dsb) disimpan terenkripsi per akun dan bisa dilihat lagi saat
/// offline. Antrean pengajuan Non-OSS TIDAK termasuk di sini: antrean itu
/// tidak pernah dihapus oleh pengaturan ini.
class DataOfflinePage extends StatefulWidget {
  const DataOfflinePage({super.key});

  @override
  State<DataOfflinePage> createState() => _DataOfflinePageState();
}

class _DataOfflinePageState extends State<DataOfflinePage> {
  final CachePreferences _pref = CachePreferences.instance;
  int _terpakai = 0;

  @override
  void initState() {
    super.initState();
    _muatUkuran();
  }

  Future<void> _muatUkuran() async {
    final int n = await ApiCache.instance.usageBytes();
    if (mounted) setState(() => _terpakai = n);
  }

  Future<bool> _konfirmasi(String judul, String isi, String aksi) async {
    final bool? ya = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(aksi),
          ),
        ],
      ),
    );
    return ya == true;
  }

  Future<void> _toggle(bool nyala) async {
    if (nyala) {
      await _pref.setEnabled(true);
      return;
    }
    final bool lanjut = await _konfirmasi(
      'Matikan penyimpanan otomatis?',
      'Data yang sudah tersimpan akan dihapus dari perangkat ini. Tanpa '
          'koneksi, dashboard, riwayat, dan daftar tidak bisa dibuka.',
      'Matikan',
    );
    if (!lanjut) return;
    await _pref.setEnabled(false);
    await ApiCache.instance.clearForCurrentUser();
    CacheStatus.instance.markLive();
    await _muatUkuran();
  }

  Future<void> _hapus() async {
    final bool lanjut = await _konfirmasi(
      'Hapus data tersimpan?',
      'Data tersimpan akun ini dihapus. Data akan tersimpan lagi saat Anda '
          'membuka halaman dengan koneksi internet.',
      'Hapus',
    );
    if (!lanjut) return;
    await ApiCache.instance.clearForCurrentUser();
    CacheStatus.instance.markLive();
    await _muatUkuran();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data tersimpan dihapus.')));
  }

  /* ---------- bagian tampilan ---------- */

  Widget _judulBagian(String teks) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(
      teks.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppTheme.textSecondary(context),
      ),
    ),
  );

  Widget _kartu(List<Widget> anak) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: anak,
    ),
  );

  Widget _ringkasanPenyimpanan() {
    final int batas = _pref.maxBytes;
    final double rasio = batas == 0
        ? 0
        : (_terpakai / batas).clamp(0.0, 1.0).toDouble();
    final bool hampirPenuh = rasio >= 0.9;
    final Color warna = hampirPenuh
        ? AppTheme.warning
        : AppTheme.primaryColor;

    return _kartu(<Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            formatUkuranBytes(_terpakai),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              'dari ${_pref.maxMb} MB',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: rasio,
          minHeight: 8,
          color: warna,
          backgroundColor: AppTheme.surfaceMuted(context),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        hampirPenuh
            ? 'Hampir penuh. Data yang paling lama tidak dibuka akan '
                  'dihapus otomatis.'
            : 'Dipakai oleh data yang tersimpan untuk mode offline.',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary(context),
        ),
      ),
    ]);
  }

  Widget _kartuCacheOtomatis() {
    final bool nyala = _pref.enabled;

    return _kartu(<Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Simpan data otomatis',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dashboard, riwayat, profil, daftar OTA, daftar OSS, dan '
                  'Data Proyek yang pernah dibuka tetap bisa dilihat tanpa '
                  'internet (hanya baca). Disimpan terenkripsi per akun.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: nyala,
            activeTrackColor: AppTheme.menuTampilan,
            onChanged: _toggle,
          ),
        ],
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<int>(
        initialValue: _pref.maxMb,
        decoration: const InputDecoration(labelText: 'Batas ukuran per akun'),
        items: CachePreferences.pilihanMb
            .map(
              (int v) => DropdownMenuItem<int>(
                value: v,
                child: Text('$v MB'),
              ),
            )
            .toList(),
        onChanged: nyala
            ? (int? v) async {
                if (v == null) return;
                await _pref.setMaxMb(v);
                await _muatUkuran();
              }
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        initialValue: _pref.maxDays,
        decoration: const InputDecoration(
          labelText: 'Simpan data selama',
          helperText: 'Data yang lebih lama dihapus otomatis.',
        ),
        items: CachePreferences.pilihanHari
            .map(
              (int v) => DropdownMenuItem<int>(
                value: v,
                child: Text('$v hari'),
              ),
            )
            .toList(),
        onChanged: nyala
            ? (int? v) {
                if (v != null) _pref.setMaxDays(v);
              }
            : null,
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _terpakai > 0 ? _hapus : null,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Hapus data tersimpan'),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Offline',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: _pref,
        builder: (BuildContext context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: <Widget>[
            _judulBagian('Penyimpanan'),
            _ringkasanPenyimpanan(),
            _judulBagian('Penyimpanan otomatis'),
            _kartuCacheOtomatis(),
            const SizedBox(height: 12),
            Text(
              'Data tetap tersimpan saat Anda keluar dari akun, dan hanya '
              'bisa dibuka oleh akun ini. Pengajuan Non-OSS yang belum '
              'terkirim tidak ikut terhapus.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}