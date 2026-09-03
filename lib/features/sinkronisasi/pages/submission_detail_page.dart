import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/features/sinkronisasi/widget/widget_submission/detail_field.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../non_oss/offline/non_oss_local_data.dart';
import '../../non_oss/offline/offline_database.dart';
import '../../non_oss/offline/offline_queue_service.dart';
import '../../non_oss/offline/sync_service.dart';
import '../../non_oss/offline/wilayah_local_database.dart';
import '../../non_oss/non_oss_form_page.dart';

import '../widget/widget_submission/detail_header_card.dart';
import '../widget/widget_submission/detail_ota_section.dart';
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
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hapus'),
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
            icon: Icon(
              Icons.edit_outlined,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            DetailHeaderCard(
              displayName: _data.displayName,
              createdAtText: _formatDateTime(_data.createdAt),
              statusColor: statusColor,
              failed: failed,
              lastError: _data.lastError,
            ),
            const SizedBox(height: 18),
            if (_data.photoPaths.isNotEmpty) ...[
              DetailPhotoSection(
                photoPaths: _data.photoPaths,
                onOpenPhoto: _openPhotoViewer,
              ),
              const SizedBox(height: 18),
            ],
            DetailFieldsCard(fields: _buildDetailFields()),
            const SizedBox(height: 18),
            DetailOtaSection(
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
              foregroundColor: AppTheme.danger,
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
                : const Icon(Icons.delete_outline_rounded, size: 19),
            label: Text(_isDeleting ? 'Menghapus...' : 'Hapus'),
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

  /// Membangun daftar [DetailField] yang siap ditampilkan oleh
  /// [DetailFieldsCard], berdasarkan urutan field pada form Non-OSS.
  /// `client_uuid` disembunyikan karena hanya identitas internal.
  List<DetailField> _buildDetailFields() {
    const List<String> knownOrder = <String>[
      'memiliki_nib',
      'nama_pemilik',
      'nama_brand',
      'jenis_produk',
      'alamat',
      'provinsi_id',
      'kabupaten_id',
      'kecamatan_id',
      'kelurahan_id',
      'latitude',
      'longitude',
      'npwpd',
      'website',
      'no_hp',
      'email',
      'terdaftar_ota',
      'ota_lainnya_nama',
      'status_pengawasan',
      'tanggal_pengawasan',
      'keterangan',
      'catatan_petugas',
    ];

    final Map<String, String> payload = Map<String, String>.from(_data.payload)
      ..remove('client_uuid')
      ..removeWhere(
        (key, _) =>
            key.startsWith('platform_ota[') ||
            key.startsWith('ota_urls[') ||
            key == 'ota_lainnya_nama',
      );

    final List<MapEntry<String, String>> ordered = <MapEntry<String, String>>[];

    for (final String key in knownOrder) {
      if (payload.containsKey(key)) {
        ordered.add(MapEntry<String, String>(key, payload[key]!));
        payload.remove(key);
      }
    }

    final List<String> remainingKeys = payload.keys.toList()..sort();
    for (final String key in remainingKeys) {
      ordered.add(MapEntry<String, String>(key, payload[key]!));
    }

    return ordered
        .map(
          (entry) => DetailField(
            label: _fieldLabel(entry.key),
            value: _displayValue(entry.key, entry.value),
          ),
        )
        .toList();
  }

  static const Map<String, String> _labelMap = <String, String>{
    'memiliki_nib': 'Memiliki NIB',
    'nama_pemilik': 'Nama Pemilik',
    'nama_brand': 'Nama Brand/Usaha',
    'jenis_produk': 'Jenis Produk',
    'alamat': 'Alamat',
    'provinsi_id': 'Provinsi',
    'kabupaten_id': 'Kabupaten/Kota',
    'kecamatan_id': 'Kecamatan',
    'kelurahan_id': 'Kelurahan',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
    'npwpd': 'NPWPD',
    'website': 'Website',
    'no_hp': 'No. HP',
    'email': 'Email',
    'terdaftar_ota': 'Terdaftar OTA',
    'ota_lainnya_nama': 'Nama OTA Lainnya',
    'status_pengawasan': 'Status Pengawasan',
    'tanggal_pengawasan': 'Tanggal Pengawasan',
    'keterangan': 'Keterangan',
    'catatan_petugas': 'Catatan Petugas',
  };

  static const Set<String> _wilayahIdKeys = <String>{
    'provinsi_id',
    'kabupaten_id',
    'kecamatan_id',
    'kelurahan_id',
  };

  String _displayValue(String key, String rawValue) {
    if (_wilayahIdKeys.contains(key)) {
      return _regionNames[key] ?? rawValue;
    }
    return rawValue;
  }

  String _fieldLabel(String key) {
    if (_labelMap.containsKey(key)) {
      return _labelMap[key]!;
    }

    // Menangani key dinamis seperti platform_ota[0] atau ota_urls[booking_com][0]
    final String base = key.split('[').first;
    final String baseLabel =
        _labelMap[base] ??
        base
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');

    return key.contains('[')
        ? '$baseLabel ${key.substring(base.length)}'
        : baseLabel;
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