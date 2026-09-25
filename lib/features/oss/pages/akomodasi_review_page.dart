import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../non_oss/models/region_option.dart';
import '../../non_oss/services/region_service.dart';
import '../models/akomodasi_item_data.dart';
import '../models/jenis_produk_akomodasi.dart';
import '../models/oss_form_data.dart';
import '../services/akomodasi_service.dart';

/// Halaman review sebelum submit final: menampilkan SELURUH isian
/// Tahap 1 + semua kartu Tahap 2, read-only, dikelompokkan per-section
/// yang bisa dibuka/tutup. Submit sungguhan (AkomodasiService.submit)
/// terjadi DI SINI - AkomodasiFormPage sekarang cuma memvalidasi lalu
/// push ke halaman ini, tidak lagi mengirim ke server langsung.
class AkomodasiReviewPage extends StatefulWidget {
  const AkomodasiReviewPage({
    super.key,
    required this.tahap1,
    required this.akomodasi,
  });

  final OssFormData tahap1;
  final List<AkomodasiItemData> akomodasi;

  @override
  State<AkomodasiReviewPage> createState() => _AkomodasiReviewPageState();
}

class _AkomodasiReviewPageState extends State<AkomodasiReviewPage> {
  static const _navy = Color(0xFF0B3F78);

  final RegionService _regions = RegionService();
  late final AkomodasiService _service;

  bool _loadingWilayah = true;
  bool _saving = false;

  String _wilayahTahap1 = '-';
  final List<String> _wilayahAkomodasi = [];

  @override
  void initState() {
    super.initState();
    _service = AkomodasiService(ApiClient());
    _muatSemuaWilayah();
  }

  Future<String> _resolveWilayah({
    required int? provinsiId,
    required int? kabupatenId,
    required int? kecamatanId,
    required int? kelurahanId,
  }) async {
    if (provinsiId == null) return '-';

    const kosong = RegionOption(id: 0, name: '-');

    final provinces = await _regions.provinces();
    final provinsi = provinces.firstWhere((r) => r.id == provinsiId, orElse: () => kosong);

    String kabupaten = '-', kecamatan = '-', kelurahan = '-';

    if (kabupatenId != null) {
      final regencies = await _regions.regencies(provinsiId);
      kabupaten = regencies.firstWhere((r) => r.id == kabupatenId, orElse: () => kosong).name;
    }
    if (kecamatanId != null && kabupatenId != null) {
      final districts = await _regions.districts(kabupatenId);
      kecamatan = districts.firstWhere((r) => r.id == kecamatanId, orElse: () => kosong).name;
    }
    if (kelurahanId != null && kecamatanId != null) {
      final villages = await _regions.villages(kecamatanId);
      kelurahan = villages.firstWhere((r) => r.id == kelurahanId, orElse: () => kosong).name;
    }

    return '$kelurahan, $kecamatan, $kabupaten, ${provinsi.name}';
  }

  Future<void> _muatSemuaWilayah() async {
    final String tahap1 = await _resolveWilayah(
      provinsiId: widget.tahap1.provinsiId,
      kabupatenId: widget.tahap1.kabupatenId,
      kecamatanId: widget.tahap1.kecamatanId,
      kelurahanId: widget.tahap1.kelurahanId,
    );

    final List<String> item = [];
    for (final a in widget.akomodasi) {
      item.add(await _resolveWilayah(
        provinsiId: a.provinsiId,
        kabupatenId: a.kabupatenId,
        kecamatanId: a.kecamatanId,
        kelurahanId: a.kelurahanId,
      ));
    }

    if (!mounted) return;
    setState(() {
      _wilayahTahap1 = tahap1;
      _wilayahAkomodasi
        ..clear()
        ..addAll(item);
      _loadingWilayah = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await _service.submit(tahap1: widget.tahap1, akomodasi: widget.akomodasi);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
          title: const Text('Berhasil'),
          content: const Text('Data Manajemen Akomodasi berhasil disimpan ke server.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data. Periksa koneksi internet.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Review Sebelum Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loadingWilayah
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReviewSection(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Tahap 1 — Identitas Manajemen Akomodasi',
                  child: _tahap1Content(),
                ),
                for (int i = 0; i < widget.akomodasi.length; i++)
                  _ReviewSection(
                    icon: Icons.apartment_rounded,
                    title:
                        'Akomodasi ${i + 1} — ${widget.akomodasi[i].namaBrand.trim().isEmpty ? '(belum ada nama)' : widget.akomodasi[i].namaBrand}',
                    initiallyExpanded: false,
                    child: _akomodasiContent(widget.akomodasi[i], _wilayahAkomodasi[i]),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                    label: Text(
                      _saving ? 'Menyimpan data...' : 'Simpan Manajemen Akomodasi',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tahap1Content() {
    final t = widget.tahap1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('NIB', t.nib),
        _kv('KBLI', t.kbli),
        _kv('NKU', t.nku),
        _kv('Status Validasi', t.isValid ? 'Valid' : 'Tidak Valid'),
        if (!t.isValid) _kv('Status Ketidaksesuaian', t.statusKetidaksesuaian.join(', ')),
        if (!t.isValid && t.keteranganKetidaksesuaian.trim().isNotEmpty)
          _kv('Keterangan', t.keteranganKetidaksesuaian),
        const Divider(height: 24),
        _kv('Nama Pemilik', t.namaPemilik),
        _kv('Nama Brand', t.namaBrand),
        const Divider(height: 24),
        _kv('Wilayah', _wilayahTahap1),
        _kv('Alamat', t.alamat),
        _kv('Koordinat', '${t.latitude}, ${t.longitude}'),
        const Divider(height: 24),
        _kv('NPWPD', t.npwpd.isEmpty ? '-' : t.npwpd),
        _kv('Website', t.website.isEmpty ? '-' : t.website),
        _kv('No. HP', t.noHp),
        _kv('Email', t.email.isEmpty ? '-' : t.email),
        _kv('Tanggal Pengawasan', DateFormat('dd-MM-yyyy').format(t.tanggalPengawasan)),
      ],
    );
  }

  Widget _akomodasiContent(AkomodasiItemData a, String wilayah) {
    final String jenisProdukLabel = JenisProdukAkomodasi.options
        .firstWhere((e) => e.key == a.jenisProduk, orElse: () => MapEntry(a.jenisProduk, a.jenisProduk))
        .value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Kepemilikan NIB', a.memilikiNib),
        if (a.memilikiNibYa) ...[
          _kv('NIB', a.nib),
          _kv('KBLI', a.kbli),
          _kv('NKU', a.nku),
          _kv(
            'Status Live-Check',
            switch (a.validasiStatus) {
              AkomodasiValidasiStatus.valid => 'Valid',
              AkomodasiValidasiStatus.tidakValid => 'Tidak Valid',
              _ => 'Belum dicek',
            },
          ),
        ],
        if (a.statusKetidaksesuaian.isNotEmpty)
          _kv('Status Ketidaksesuaian', a.statusKetidaksesuaian.join(', ')),
        if (a.keteranganKetidaksesuaian.trim().isNotEmpty)
          _kv('Keterangan', a.keteranganKetidaksesuaian),
        const Divider(height: 24),
        _kv('Nama Pemilik', a.namaPemilik),
        _kv('Nama Brand', a.namaBrand),
        _kv('Jenis Produk', jenisProdukLabel),
        const Divider(height: 24),
        _kv('Wilayah', wilayah),
        _kv('Alamat', a.alamat),
        _kv('Koordinat', '${a.latitude}, ${a.longitude}'),
        const Divider(height: 24),
        _kv('NPWPD', a.npwpd.isEmpty ? '-' : a.npwpd),
        _kv('Website', a.website.isEmpty ? '-' : a.website),
        _kv('No. HP', a.noHp),
        _kv('Email', a.email.isEmpty ? '-' : a.email),
        const Divider(height: 24),
        _kv('Terdaftar OTA', a.terdaftarOta),
        if (a.terdaftarOtaYa)
          ...a.otaUrls.entries
              .where((e) => e.value.any((u) => u.trim().isNotEmpty))
              .map((e) => _kv(e.key, e.value.where((u) => u.trim().isNotEmpty).join(', '))),
        const Divider(height: 24),
        Text('Foto (${a.photos.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        const SizedBox(height: 8),
        if (a.photos.isEmpty)
          const Text('Belum ada foto.', style: TextStyle(fontSize: 12, color: Colors.grey))
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: a.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(a.photos[i].path), width: 72, height: 72, fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(fontSize: 12.5, color: AppTheme.textColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final Color border = AppTheme.border(context);
    final Color surface = AppTheme.surface(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: _expanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(padding: const EdgeInsets.all(14), child: widget.child),
        ],
      ),
    );
  }
}