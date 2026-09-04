import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/detail_section_card.dart';
import '../../../shared/widgets/detail_status_header.dart';
import '../../non_oss/offline/non_oss_local_data.dart';
import '../../non_oss/offline/offline_database.dart';
import '../../non_oss/offline/offline_queue_service.dart';
import '../../non_oss/offline/sync_service.dart';
import '../../non_oss/offline/wilayah_local_database.dart';
import '../../non_oss/non_oss_form_page.dart';

import '../widget/widget_submission/detail_photo_section.dart';
import '../widget/widget_submission/ota_tile.dart';
import '../widget/widget_submission/photo_viewer.dart';

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
      Baris('Nama Pemilik', p['nama_pemilik']),
      Baris('Nama Brand', p['nama_brand']),
      Baris('Jenis Produk', p['jenis_produk']),
      Baris('Website', p['website'], url: _normalisasiUrl(p['website'])),
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
        url: _mapsUrlFromLatLng(lat, lng),
      ),
    ];
  }

  List<Baris> _hasilPengawasanRows() {
    final Map<String, String> p = _data.payload;
    return <Baris>[
      Baris('Status Pengawasan', p['status_pengawasan']),
      Baris('Keterangan', p['keterangan']),
      Baris('Catatan Petugas', p['catatan_petugas']),
      Baris('Tanggal Pengawasan', p['tanggal_pengawasan']),
    ];
  }

  String? _normalisasiUrl(String? website) {
    if (website == null || website.trim().isEmpty) {
      return null;
    }
    final String bersih = website.trim();
    if (bersih.startsWith('http://') || bersih.startsWith('https://')) {
      return bersih;
    }
    return 'https://$bersih';
  }

  String? _mapsUrlFromLatLng(String? lat, String? lng) {
    if (lat == null || lng == null || lat.trim().isEmpty || lng.trim().isEmpty) {
      return null;
    }
    return 'https://www.google.com/maps?q=$lat,$lng';
  }

  Future<void> _sync() async {
    if (_isSyncing || _isDeleting) return;

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
      _showMessage('Ajuan berhasil disinkronkan.', success: true);
      Navigator.of(context).pop('synced');
    } else {
      _showMessage(
        'Sinkronisasi gagal. Periksa internet atau server lalu coba lagi.',
        success: false,
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
                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
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
      _showMessage('Ajuan berhasil dihapus.', success: true);
      Navigator.of(context).pop('deleted');
    } else {
      _showMessage('Gagal menghapus ajuan. Silakan coba lagi.', success: false);
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

  void _showMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? const Color(0xFF238636)
              : const Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Tautan tidak valid.', success: false);
      return;
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      _showMessage('Tidak dapat membuka tautan.', success: false);
    }
  }

  @override
    @override
  Widget build(BuildContext context) {
    final bool failed = _data.isFailed;
    final Color statusColor = failed
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFF9500);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        surfaceTintColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 4,
        title: Text(
          'Detail Ajuan',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _isSyncing || _isDeleting ? null : _openEdit,
            icon: Icon(Icons.edit_outlined, color: AppTheme.textColor(context)),
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
              subtitle: _formatDateTime(_data.createdAt),
              errorMessage: failed ? _data.lastError : null,
              badges: <StatusBadge>[
                StatusBadge(text: 'NON OSS', color: AppTheme.menuNonOss),
                StatusBadge(
                  text: failed ? 'Gagal Sync' : 'Menunggu Sync',
                  color: statusColor,
                ),
              ],
            ),
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
              onTapUrl: _openUrl,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context, failed),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool failed) {
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
                : const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.white),
            label: Text(_isDeleting ? 'Menghapus...' : 'Hapus', 
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSyncing || _isDeleting ? null : _sync,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
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
                : const Icon(Icons.sync_rounded, size: 19),
            label: Text(
              _isSyncing
                  ? 'Menyinkronkan...'
                  : (failed ? 'Coba Sync Lagi' : 'Sync Sekarang'),
            ),
          ),
        ),
      ],
    );
  }

  static const Map<String, String> _otaPlatformLabels = <String, String>{
    'booking_com': 'Booking.com',
    'tiket_com': 'Tiket.com',
    'traveloka': 'Traveloka',
    'oyo': 'OYO',
    'agoda': 'Agoda',
    'expedia': 'Expedia',
    'trip_com': 'Trip.com',
    'reddoorz': 'RedDoorz',
  };

  List<OtaEntry> _parseOtaEntries() {
    final Map<String, String> payload = _data.payload;
    final RegExp platformKeyRegex = RegExp(r'^platform_ota\[\d+\]$');
    final RegExp urlKeyRegex = RegExp(r'^ota_urls\[([^\]]+)\]\[\d+\]$');

    final List<String> platforms = <String>[];
    for (final MapEntry<String, String> entry in payload.entries) {
      if (platformKeyRegex.hasMatch(entry.key)) {
        platforms.add(entry.value);
      }
    }

    final Map<String, List<String>> urlsByPlatform = <String, List<String>>{};
    for (final MapEntry<String, String> entry in payload.entries) {
      final Match? match = urlKeyRegex.firstMatch(entry.key);
      if (match != null) {
        urlsByPlatform
            .putIfAbsent(match.group(1)!, () => <String>[])
            .add(entry.value);
      }
    }

    return platforms.map((String platform) {
      final String displayName = platform == 'lainnya'
          ? (payload['ota_lainnya_nama']?.trim().isNotEmpty == true
                ? payload['ota_lainnya_nama']!.trim()
                : 'Lainnya')
          : (_otaPlatformLabels[platform] ?? platform);

      return OtaEntry(
        name: displayName,
        urls: urlsByPlatform[platform] ?? const <String>[],
      );
    }).toList();
  }
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Kartu section OTA bergaya sama dengan halaman detail Riwayat, tapi
/// data submission cuma punya nama platform + daftar URL (tanpa status,
/// harga, rating — karena itu semua diisi lewat proses verifikasi OSS
/// yang belum berlaku untuk ajuan yang masih di antrean lokal).
class _SubmissionOtaSection extends StatelessWidget {
  const _SubmissionOtaSection({required this.entries, required this.onTapUrl});

  final List<OtaEntry> entries;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.travel_explore_outlined,
                  size: 18,
                  color: AppTheme.menuDashboard,
                ),
                const SizedBox(width: 8),
                Text(
                  'Platform OTA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${entries.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < entries.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 20),
              _SubmissionOtaTile(entry: entries[i], onTapUrl: onTapUrl),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionOtaTile extends StatelessWidget {
  const _SubmissionOtaTile({required this.entry, required this.onTapUrl});

  final OtaEntry entry;
  final ValueChanged<String> onTapUrl;

  @override
  Widget build(BuildContext context) {
    final List<String> urls =
        entry.urls.where((String u) => u.trim().isNotEmpty).toList();

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
                _LinkButtonSubmission(
                  icon: Icons.open_in_new_rounded,
                  label: urls.length > 1 ? 'Buka Link ${i + 1}' : 'Buka Listing',
                  onTap: () => onTapUrl(urls[i]),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinkButtonSubmission extends StatelessWidget {
  const _LinkButtonSubmission({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.menuDashboard,
        side: BorderSide(color: AppTheme.menuDashboard.withOpacity(0.4)),
      ),
    );
  }
}