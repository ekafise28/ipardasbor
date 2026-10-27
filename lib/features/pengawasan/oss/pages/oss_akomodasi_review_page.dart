import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart'
    show BarisTile, Baris, KotakBaris;

import '../../../../app/app_theme.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/network/network_status.dart';

import '../../../../shared/region/models/region_option.dart';
import '../../../../shared/region/services/region_service.dart';

import '../models/oss_akomodasi_item_data.dart';
import '../models/oss_jenis_produk_akomodasi.dart';
import '../models/oss_form_data.dart';

import '../services/oss_akomodasi_service.dart';

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
  final RegionService _regions = RegionService();
  late final AkomodasiService _service;
  late final ApiClient _api;

  bool _loadingWilayah = true;
  bool _saving = false;

  String _wilayahTahap1 = '-';
  final List<String> _wilayahAkomodasi = [];

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _service = AkomodasiService(_api);
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
    final provinsi = provinces.firstWhere(
      (r) => r.id == provinsiId,
      orElse: () => kosong,
    );

    String kabupaten = '-', kecamatan = '-', kelurahan = '-';

    if (kabupatenId != null) {
      final regencies = await _regions.regencies(provinsiId);
      kabupaten = regencies
          .firstWhere((r) => r.id == kabupatenId, orElse: () => kosong)
          .name;
    }
    if (kecamatanId != null && kabupatenId != null) {
      final districts = await _regions.districts(kabupatenId);
      kecamatan = districts
          .firstWhere((r) => r.id == kecamatanId, orElse: () => kosong)
          .name;
    }
    if (kelurahanId != null && kecamatanId != null) {
      final villages = await _regions.villages(kecamatanId);
      kelurahan = villages
          .firstWhere((r) => r.id == kelurahanId, orElse: () => kosong)
          .name;
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
      item.add(
        await _resolveWilayah(
          provinsiId: a.provinsiId,
          kabupatenId: a.kabupatenId,
          kecamatanId: a.kecamatanId,
          kelurahanId: a.kelurahanId,
        ),
      );
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
    if (!await NetworkGuard.pastikanOnline(
      context,
      pesan: 'Perlu koneksi internet untuk menyimpan Manajemen Akomodasi.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await _service.submit(tahap1: widget.tahap1, akomodasi: widget.akomodasi);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
          title: const Text('Berhasil'),
          content: const Text(
            'Data Manajemen Akomodasi berhasil disimpan ke server.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        final NavigatorState nav = Navigator.of(context);
        nav.pop(); // AkomodasiReviewPage
        nav.pop(); // AkomodasiFormPage
        nav.pop(true); // OssFormPage -> OssValidasiPage menerima true
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data. Periksa koneksi internet.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Review Sebelum Simpan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loadingWilayah
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const OfflineNotice(
                  pesan:
                      'Perlu koneksi internet untuk menyimpan. Data isian tetap aman di halaman ini.',
                ),
                _ReviewSection(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Tahap 1 - Identitas Manajemen Akomodasi',
                  rows: _tahap1Rows(),
                ),
                for (int i = 0; i < widget.akomodasi.length; i++)
                  _ReviewSection(
                    icon: Icons.apartment_rounded,
                    title:
                        'Akomodasi ${i + 1} - ${widget.akomodasi[i].namaBrand.trim().isEmpty ? '(belum ada nama)' : widget.akomodasi[i].namaBrand}',
                    initiallyExpanded: false,
                    rows: _akomodasiRows(
                      widget.akomodasi[i],
                      _wilayahAkomodasi[i],
                    ),
                    footer: _fotoStrip(widget.akomodasi[i]),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(
                      'Kembali',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: NetworkStatus.instance,
                  builder: (context, offline, _) => SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: (_saving || offline) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              offline
                                  ? Icons.cloud_off_rounded
                                  : Icons.cloud_upload_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _saving
                            ? 'Menyimpan data...'
                            : (offline
                                  ? 'Perlu koneksi internet'
                                  : 'Simpan Manajemen Akomodasi'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Baris> _tahap1Rows() {
    final t = widget.tahap1;
    return <Baris>[
      Baris('NIB', t.nib, kode: true),
      Baris('KBLI', t.kbli, kode: true),
      Baris('NKU', t.nku, kode: true),
      Baris(
        'Status Validasi',
        t.isValid ? 'Valid' : 'Tidak Valid',
        warnaLencana: t.isValid ? AppTheme.success : AppTheme.danger,
      ),
      if (!t.isValid)
        Baris.chips('Status Ketidaksesuaian', t.statusKetidaksesuaian),
      if (!t.isValid && t.keteranganKetidaksesuaian.trim().isNotEmpty)
        Baris(
          'Keterangan',
          t.keteranganKetidaksesuaian,
          kotak: KotakBaris.netral,
        ),
      Baris('Nama Pemilik', t.namaPemilik),
      Baris('Nama Brand', t.namaBrand),
      Baris('Wilayah', _wilayahTahap1, kotak: KotakBaris.netral),
      Baris('Alamat', t.alamat, kotak: KotakBaris.netral),
      Baris.koordinat(t.latitude, t.longitude),
      Baris('NPWPD', t.npwpd),
      Baris('Website', t.website),
      Baris('No. HP', t.noHp),
      Baris('Email', t.email),
      Baris(
        'Tanggal Pengawasan',
        DateFormat('dd-MM-yyyy').format(t.tanggalPengawasan),
      ),
    ];
  }

  List<Baris> _akomodasiRows(AkomodasiItemData a, String wilayah) {
    final String jenisProdukLabel = JenisProdukAkomodasi.options
        .firstWhere(
          (e) => e.key == a.jenisProduk,
          orElse: () => MapEntry(a.jenisProduk, a.jenisProduk),
        )
        .value;

    return <Baris>[
      Baris('Kepemilikan NIB', a.memilikiNib),
      if (a.memilikiNibYa) ...<Baris>[
        Baris('NIB', a.nib, kode: true),
        Baris('KBLI', a.kbli, kode: true),
        Baris('NKU', a.nku, kode: true),
        Baris(
          'Status Live-Check',
          switch (a.validasiStatus) {
            AkomodasiValidasiStatus.valid => 'Valid',
            AkomodasiValidasiStatus.tidakValid => 'Tidak Valid',
            _ => 'Belum dicek',
          },
          warnaLencana: switch (a.validasiStatus) {
            AkomodasiValidasiStatus.valid => AppTheme.success,
            AkomodasiValidasiStatus.tidakValid => AppTheme.danger,
            _ => null,
          },
        ),
      ],
      if (a.statusKetidaksesuaian.isNotEmpty)
        Baris.chips('Status Ketidaksesuaian', a.statusKetidaksesuaian),
      if (a.keteranganKetidaksesuaian.trim().isNotEmpty)
        Baris(
          'Keterangan',
          a.keteranganKetidaksesuaian,
          kotak: KotakBaris.netral,
        ),
      Baris('Nama Pemilik', a.namaPemilik),
      Baris('Nama Brand', a.namaBrand),
      Baris('Jenis Produk', jenisProdukLabel),
      Baris('Wilayah', wilayah, kotak: KotakBaris.netral),
      Baris('Alamat', a.alamat, kotak: KotakBaris.netral),
      Baris.koordinat(a.latitude, a.longitude),
      Baris('NPWPD', a.npwpd),
      Baris('Website', a.website),
      Baris('No. HP', a.noHp),
      Baris('Email', a.email),
      Baris('Terdaftar OTA', a.terdaftarOta),
      if (a.terdaftarOtaYa)
        for (final e in a.otaUrls.entries)
          if (e.value.any((u) => u.trim().isNotEmpty))
            Baris(
              OtaPlatform.labelDari(e.key),
              e.value.where((u) => u.trim().isNotEmpty).join('\n'),
              kotak: KotakBaris.netral,
            ),
    ];
  }

  Widget _fotoStrip(AkomodasiItemData a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Foto (${a.photos.length})',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        if (a.photos.isEmpty)
          Text(
            'Belum ada foto.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          )
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: a.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(a.photos[i].path),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.rows,
    this.footer,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Baris> rows;
  final Widget? footer;
  final bool initiallyExpanded;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.tintBackground(
                        context,
                        AppTheme.primaryColor,
                        AppTheme.menuDashboardBg,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
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
          if (_expanded) ...<Widget>[
            Divider(height: 1, color: AppTheme.border(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < widget.rows.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: AppTheme.border(context).withValues(alpha: 0.7),
                      ),
                    BarisTile(baris: widget.rows[i]),
                  ],
                  if (widget.footer != null) ...<Widget>[
                    const SizedBox(height: 12),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
