import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/core/constants/ota_platform_constants.dart';
import 'package:ipardasbor/features/sinkronisasi/widgets/submission_photos.dart';
import 'package:ipardasbor/features/oss/models/oss_jenis_produk_akomodasi.dart';
import 'package:ipardasbor/features/sinkronisasi/widgets/sync_table.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/ota_utils.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart';
import '../../non_oss/services/non_oss_service.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/detail_cards.dart';

import '../../non_oss/offline/non_oss_local_data.dart';
import '../../non_oss/offline/offline_database.dart';
import '../../non_oss/offline/offline_queue_service.dart';
import '../../non_oss/offline/sync_service.dart';
import '../../../shared/region/data/wilayah_local_database.dart';
import '../../non_oss/non_oss_form_page.dart';
import '../../non_oss/offline/draft_completeness.dart';

import '../../../core/constants/bidang_usaha_constants.dart';

/// Halaman detail satu ajuan Non-OSS yang berada di antrean lokal.
///
/// Menampilkan seluruh isi payload form, status sinkronisasi, dan
/// menyediakan aksi Sync satuan serta Hapus ajuan.
///
/// Mengembalikan nilai melalui Navigator.pop:
/// - 'synced'  : ajuan berhasil disinkronkan
/// - 'deleted' : ajuan dihapus dari antrean
/// - null      : tidak ada perubahan (kembali biasa)
class SubmissionDetailPage extends StatefulWidget {
  const SubmissionDetailPage({
    super.key,
    required this.data,
    required this.syncService,
    required this.queueService,
  });

  final NonOssLocalData data;
  final NonOssSyncService syncService;
  final OfflineQueueService queueService;

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  late NonOssLocalData _data;
  bool _isSyncing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _loadRegionNames();
    _muatLabelJenisProduk();
  }

  String? _labelJenisProdukTampil;

  Future<void> _muatLabelJenisProduk() async {
    final String? kode = _data.payload['jenis_produk'];
    if (kode == null || kode.trim().isEmpty) return;

    final String bidang = _data.payload['bidang_usaha'] ?? 'akomodasi';

    final List<MapEntry<String, String>> daftar = bidang == 'akomodasi'
        ? JenisProdukAkomodasi.options
        : await NonOssService.jenisProdukTersimpan(bidang);

    for (final e in daftar) {
      if (e.key == kode) {
        if (mounted) {
          setState(
            () => _labelJenisProdukTampil = e.value.startsWith(e.key)
                ? e.value
                : '${e.key} - ${e.value}',
          );
        }
        return;
      }
    }
  }

  Map<String, String> _regionNames = <String, String>{};

  Future<void> _loadRegionNames() async {
    final WilayahLocalDatabase db = WilayahLocalDatabase.instance;
    final Map<String, String> resolved = <String, String>{};

    final int? provinceId = int.tryParse(_data.payload['provinsi_id'] ?? '');
    final int? regencyId = int.tryParse(_data.payload['kabupaten_id'] ?? '');
    final int? districtId = int.tryParse(_data.payload['kecamatan_id'] ?? '');
    final int? villageId = int.tryParse(_data.payload['kelurahan_id'] ?? '');

    if (provinceId != null) {
      final String? name = await db.provinceName(provinceId);
      if (name != null) resolved['provinsi_id'] = name;
    }
    if (regencyId != null) {
      final String? name = await db.regencyName(regencyId);
      if (name != null) resolved['kabupaten_id'] = name;
    }
    if (districtId != null) {
      final String? name = await db.districtName(districtId);
      if (name != null) resolved['kecamatan_id'] = name;
    }
    if (villageId != null) {
      final String? name = await db.villageName(villageId);
      if (name != null) resolved['kelurahan_id'] = name;
    }

    if (mounted) setState(() => _regionNames = resolved);
  }

  List<Baris> _informasiUsahaRows() {
    final Map<String, String> p = _data.payload;
    return <Baris>[
      Baris(
        'Bidang Usaha',
        BidangUsahaOpsi.namaDari(p['bidang_usaha'] ?? 'akomodasi'),
      ),
      Baris('Nama Pemilik', p['nama_pemilik']),
      Baris('Nama Brand', p['nama_brand']),
      Baris('Jenis Produk', _labelJenisProdukTampil ?? p['jenis_produk']),
      Baris('Website', p['website'], url: normalisasiUrl(p['website'])),
      Baris('No. HP', p['no_hp']),
      Baris('Email', p['email']),
    ];
  }

  List<Baris> _legalitasRows() {
    final Map<String, String> p = _data.payload;
    return <Baris>[
      Baris('Memiliki NIB', p['memiliki_nib']),
      Baris('NPWPD', p['npwpd']),
      Baris('Terdaftar OTA', p['terdaftar_ota']),
    ];
  }

  List<Baris> _lokasiRows() {
    final Map<String, String> p = _data.payload;
    final String? lat = p['latitude'];
    final String? lng = p['longitude'];

    return <Baris>[
      Baris('Provinsi', _regionNames['provinsi_id']),
      Baris('Kabupaten/Kota', _regionNames['kabupaten_id']),
      Baris('Kecamatan', _regionNames['kecamatan_id']),
      Baris('Kelurahan', _regionNames['kelurahan_id']),
      Baris('Alamat', p['alamat']),
      Baris(
        'Koordinat',
        (lat != null && lng != null && lat.isNotEmpty && lng.isNotEmpty)
            ? '$lat, $lng'
            : null,
        url: mapsUrl(lat, lng),
      ),
    ];
  }

  static const Map<String, String> _labelStatus = <String, String>{
    'NIB_TIDAK_DITEMUKAN': 'Tidak Punya NIB',
    'TIDAK_BERTEMU_PEMILIK': 'Tidak bertemu pemilik',
    'PENGELOLA_TIDAK_BISA_MEMBERIKAN_DATA':
        'Pengelola tidak bisa memberikan data',
    'LAINNYA': 'Lainnya',
  };

  /// Gabungan semua status_ketidaksesuaian[i] dari payload, urut indeks.
  String? _statusPengawasanTampil() {
    final RegExp pola = RegExp(r'^status_ketidaksesuaian\[(\d+)\]$');
    final Map<int, String> byIndex = <int, String>{};

    for (final MapEntry<String, String> e in _data.payload.entries) {
      final Match? m = pola.firstMatch(e.key);
      if (m != null && e.value.trim().isNotEmpty) {
        byIndex[int.parse(m.group(1)!)] = e.value.trim();
      }
    }

    // Data "Tidak" selalu bernilai tetap, walau draft lama belum menyimpannya.
    if (byIndex.isEmpty &&
        (_data.payload['memiliki_nib'] ?? '').toUpperCase() == 'TIDAK') {
      return _labelStatus['NIB_TIDAK_DITEMUKAN'];
    }
    if (byIndex.isEmpty) return null;

    final List<int> urut = byIndex.keys.toList()..sort();
    return urut
        .map((int i) => _labelStatus[byIndex[i]] ?? byIndex[i]!)
        .join(', ');
  }

  List<Baris> _hasilPengawasanRows() {
    final Map<String, String> p = _data.payload;
    return <Baris>[
      Baris('Status Pengawasan', _statusPengawasanTampil()),
      Baris('Keterangan', p['keterangan']),
      Baris('Catatan Petugas', p['catatan_petugas']),
      Baris('Tanggal Pengawasan', p['tanggal_pengawasan']),
    ];
  }

  Future<void> _sync() async {
    if (_isSyncing || _isDeleting || _data.isDraft) return;

    setState(() => _isSyncing = true);

    bool success = false;
    try {
      success = await widget.syncService
          .syncOne(_data)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      success = false;
    } catch (_) {
      success = false;
    }

    // Ambil ulang data dari database: syncOne() sudah mengubah
    // last_attempt_at (dan retry_count kalau gagal) lewat markSyncing /
    // markFailed. Tanpa refetch ini, angka di layar tetap versi lama
    // karena _data cuma snapshot saat halaman pertama dibuka.
    if (mounted) {
      final NonOssLocalData? refreshed = await OfflineDatabase.instance
          .getByClientUuid(_data.clientUuid);
      if (refreshed != null) {
        setState(() => _data = refreshed);
      }
    }

    if (mounted) setState(() => _isSyncing = false);
    if (!mounted) return;

    if (success) {
      tampilkanPesan(context, 'Ajuan berhasil disinkronkan.', sukses: true);
      Navigator.of(context).pop('synced');
    } else {
      tampilkanPesan(
        context,
        'Sinkronisasi gagal. Periksa internet atau server lalu coba lagi.',
        sukses: false,
      );
    }
  }

  Future<void> _openEdit() async {
    final Object? result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => NonOssFormPage(editingData: _data),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop('edited');
    }
  }

  Future<void> _confirmDelete() async {
    if (_isSyncing || _isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(context),
          surfaceTintColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Hapus ajuan ini?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          content: Text(
            'Data "${_data.displayName}" akan dihapus permanen dari '
            'perangkat ini beserta foto yang tersimpan. Tindakan ini '
            'tidak dapat dibatalkan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textColor(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    bool success = false;
    try {
      await widget.queueService.delete(_data);
      success = true;
    } catch (_) {
      success = false;
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }

    if (!mounted) return;

    if (success) {
      tampilkanPesan(context, 'Ajuan berhasil dihapus.', sukses: true);
      Navigator.of(context).pop('deleted');
    } else {
      tampilkanPesan(
        context,
        'Gagal menghapus ajuan. Silakan coba lagi.',
        sukses: false,
      );
    }
  }

  void _openPhotoViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: PhotoViewerPage(
              photoPaths: _data.photoPaths,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool failed = _data.isFailed;
    final bool isDraft = _data.isDraft;
    final Color statusColor = submissionStatus(_data).color;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        surfaceTintColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 4,
        title: Text(
          'Detail Ajuan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _isSyncing || _isDeleting ? null : _openEdit,
            icon: Icon(Icons.edit_outlined, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            StatusHeaderCard(
              title: _data.displayName,
              subtitle: 'Dibuat ${formatTanggalJam(_data.createdAt.toLocal())}',
              errorMessage: (!isDraft && failed) ? _data.lastError : null,
              badges: <StatusBadge>[
                StatusBadge(text: 'NON OSS', color: AppTheme.menuNonOss),
                StatusBadge(
                  text: isDraft
                      ? 'Draft'
                      : (failed ? 'Gagal Sync' : 'Menunggu Sync'),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isDraft) ...[
              _DraftChecklistCard(data: _data),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            if (_data.photoPaths.isNotEmpty) ...[
              DetailPhotoSection(
                photoPaths: _data.photoPaths,
                onOpenPhoto: _openPhotoViewer,
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              icon: Icons.storefront_outlined,
              title: 'Informasi Usaha',
              rows: _informasiUsahaRows(),
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.verified_outlined,
              title: 'Legalitas',
              rows: _legalitasRows(),
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.place_outlined,
              title: 'Lokasi',
              rows: _lokasiRows(),
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.fact_check_outlined,
              title: 'Hasil Pengawasan',
              rows: _hasilPengawasanRows(),
            ),
            const SizedBox(height: 12),
            _SubmissionOtaSection(
              entries: _parseOtaEntries(),
              onTapUrl: (String u) => bukaTautan(context, u),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(context, failed, isDraft),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool failed, bool isDraft) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDeleting || _isSyncing ? null : _confirmDelete,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
            label: Text(
              _isDeleting ? 'Menghapus...' : 'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSyncing || _isDeleting
                ? null
                : (isDraft ? _openEdit : _sync),
            style: FilledButton.styleFrom(
              backgroundColor: isDraft
                  ? submissionStatus(_data).color
                  : const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isDraft ? Icons.edit_note_rounded : Icons.sync_rounded,
                    size: 19,
                  ),
            label: Text(
              _isSyncing
                  ? 'Menyinkronkan...'
                  : (isDraft
                        ? 'Lanjutkan Isi'
                        : (failed ? 'Coba Sync Lagi' : 'Sync Sekarang')),
            ),
          ),
        ),
      ],
    );
  }

  List<OtaEntry> _parseOtaEntries() {
    final Map<String, String> payload = _data.payload;
    final String lainnyaNama = payload['ota_lainnya_nama'] ?? '';

    return OtaFields.parse(payload).entries
        .map(
          (MapEntry<String, List<String>> e) => OtaEntry(
            name: OtaPlatform.labelTampil(e.key, lainnyaNama: lainnyaNama),
            urls: e.value,
          ),
        )
        .toList();
  }
}

/// Kartu section OTA bergaya sama dengan halaman detail Riwayat, tapi
/// data submission cuma punya nama platform + daftar URL (tanpa status,
/// harga, rating - karena itu semua diisi lewat proses verifikasi OSS
/// yang belum berlaku untuk ajuan yang masih di antrean lokal).
class _SubmissionOtaSection extends StatelessWidget {
  const _SubmissionOtaSection({required this.entries, required this.onTapUrl});

  final List<OtaEntry> entries;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return DetailCard(
      icon: Icons.travel_explore_outlined,
      title: 'Platform OTA',
      count: entries.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < entries.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 20),
            _SubmissionOtaTile(entry: entries[i], onTapUrl: onTapUrl),
          ],
        ],
      ),
    );
  }
}

/// Satu platform OTA beserta daftar URL yang terdaftar untuknya.
class OtaEntry {
  const OtaEntry({required this.name, required this.urls});

  final String name;
  final List<String> urls;
}

class _SubmissionOtaTile extends StatelessWidget {
  const _SubmissionOtaTile({required this.entry, required this.onTapUrl});

  final OtaEntry entry;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    final List<String> urls = entry.urls
        .where((String u) => u.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          entry.name,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor(context),
          ),
        ),
        if (urls.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              for (int i = 0; i < urls.length; i++)
                LinkButton(
                  icon: Icons.open_in_new_rounded,
                  label: urls.length > 1
                      ? 'Buka Link ${i + 1}'
                      : 'Buka Listing',
                  onTap: () => onTapUrl(urls[i]),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Checklist bagian form yang masih perlu dilengkapi.
class _DraftChecklistCard extends StatelessWidget {
  const _DraftChecklistCard({required this.data});

  final NonOssLocalData data;

  @override
  Widget build(BuildContext context) {
    final List<DraftMissingItem> missing = DraftCompletenessChecker.check(
      data.payload,
      data.photoPaths,
    );

    return DetailCard(
      icon: Icons.checklist_rounded,
      title: 'Data Yang Belum Lengkap',
      child: missing.isEmpty
          ? Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF238636),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Semua data sudah lengkap. Tekan "Lanjutkan Isi" untuk '
                    'meninjau kembali sebelum dikirim.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            )
          : DraftMissingList(items: missing),
    );
  }
}
