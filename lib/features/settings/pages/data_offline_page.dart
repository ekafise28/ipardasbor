import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/cache/api_cache.dart';
import '../../../core/cache/cache_preferences.dart';
import '../../../core/cache/cache_status.dart';

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

  String _format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _konfirmasi(String judul, String isi, String aksi) async {
    final bool? ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
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
      'Nonaktifkan data offline?',
      'Data offline yang sudah tersimpan akan dihapus dari perangkat ini. '
          'Tanpa koneksi, dashboard, riwayat, dan daftar tidak bisa dibuka.',
      'Nonaktifkan',
    );
    if (!lanjut) return;
    await _pref.setEnabled(false);
    await ApiCache.instance.clearForCurrentUser();
    CacheStatus.instance.markLive();
    await _muatUkuran();
  }

  Future<void> _hapus() async {
    final bool lanjut = await _konfirmasi(
      'Hapus data offline?',
      'Cache akun ini dihapus. Data akan tersimpan lagi saat Anda membuka '
          'halaman dengan koneksi internet.',
      'Hapus',
    );
    if (!lanjut) return;
    await ApiCache.instance.clearForCurrentUser();
    CacheStatus.instance.markLive();
    await _muatUkuran();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data offline dihapus.')),
    );
  }

  Widget _kartu(List<Widget> anak) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border(context)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: anak),
  );

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
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _kartu([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simpan data untuk mode offline',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dashboard, riwayat, profil, daftar OTA, dan daftar '
                          'OSS tetap bisa dilihat tanpa internet (hanya baca). '
                          'Data disimpan terenkripsi per akun.',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _pref.enabled,
                    activeTrackColor: AppTheme.menuTampilan,
                    onChanged: _toggle,
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            _kartu([
              DropdownButtonFormField<int>(
                initialValue: _pref.maxMb,
                decoration: const InputDecoration(
                  labelText: 'Batas ukuran per akun',
                ),
                items: CachePreferences.pilihanMb
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v MB')))
                    .toList(),
                onChanged: _pref.enabled
                    ? (v) async {
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
                ),
                items: CachePreferences.pilihanHari
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v hari')))
                    .toList(),
                onChanged: _pref.enabled ? (v) => v == null ? null : _pref.setMaxDays(v) : null,
              ),
            ]),
            const SizedBox(height: 12),
            _kartu([
              Text(
                'Terpakai: ${_format(_terpakai)} dari ${_pref.maxMb} MB',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Data tetap tersimpan saat Anda keluar dari akun, dan hanya '
                'bisa dibuka oleh akun ini.',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _terpakai > 0 ? _hapus : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus data offline'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}