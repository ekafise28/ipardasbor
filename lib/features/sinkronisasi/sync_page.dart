import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_queue_store.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/skeleton.dart' show SyncReadySkeleton;

import '../../app/app_theme.dart';
import '../../core/api/api_client.dart';

import '../non_oss/offline/non_oss_local_data.dart';
import '../non_oss/offline/offline_queue_service.dart';
import '../non_oss/offline/sync_service.dart';
import '../non_oss/services/non_oss_service.dart';
import '../non_oss/non_oss_form_page.dart';
import '../oss/models/oss_jenis_produk_akomodasi.dart';
import '../riwayat/riwayat_page.dart';

import 'pages/sync_submission_detail_page.dart';
import 'widgets/sync_bottom_bar.dart';
import 'widgets/sync_connection_banner.dart';
import 'widgets/sync_draft_card.dart';
import 'widgets/sync_formatters.dart';
import 'widgets/sync_ready_card.dart';
import 'widgets/sync_summary_card.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final ApiClient _api;
  late final NonOssSyncService _syncService;
  late final OfflineQueueService _queueService;
  final NonOssQueueStore _database = NonOssQueueStore.instance;

  List<NonOssLocalData> _waitingData = <NonOssLocalData>[];
  List<NonOssLocalData> _draftData = <NonOssLocalData>[];
  final Set<String> _syncingIds = <String>{};
  String? _expandedUuid;

  /// bidang -> (kode produk -> label), untuk menampilkan nama jenis produk.
  Map<String, Map<String, String>> _produkLabels =
      <String, Map<String, String>>{};
  DateTime? _lastSyncedAt;

  bool _isLoading = true;
  bool _isSyncingAll = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _syncService = NonOssSyncService(remote: NonOssService(_api));
    _queueService = OfflineQueueService(database: _database);
    _loadAllData();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadAllData({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      await _database.restoreInterruptedSyncs();
      final List<NonOssLocalData> waiting = await _database.getWaiting(
        limit: 500,
      );
      final List<NonOssLocalData> drafts = await _database.getDrafts(
        limit: 200,
      );

      // Dua data tambahan ini hanya hiasan tampilan; gagal memuatnya tidak
      // boleh membuat daftar data ikut gagal tampil.
      final DateTime? terakhir = await _muatWaktuSyncTerakhir();
      final Map<String, Map<String, String>> labels = await _muatLabelProduk(
        <NonOssLocalData>[...waiting, ...drafts],
      );

      if (!mounted) return;
      setState(() {
        _waitingData = waiting;
        _draftData = drafts;
        _lastSyncedAt = terakhir;
        _produkLabels = labels;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<DateTime?> _muatWaktuSyncTerakhir() async {
    try {
      return await _database.lastSyncedAt();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Map<String, String>>> _muatLabelProduk(
    List<NonOssLocalData> items,
  ) async {
    final Map<String, Map<String, String>> hasil =
        <String, Map<String, String>>{};

    try {
      for (final String bidang in items.map(bidangSlugOf).toSet()) {
        final List<MapEntry<String, String>> daftar = bidang == 'akomodasi'
            ? JenisProdukAkomodasi.options
            : await NonOssService.jenisProdukTersimpan(bidang);

        hasil[bidang] = <String, String>{
          for (final MapEntry<String, String> e in daftar) e.key: e.value,
        };
      }
    } catch (_) {
      // Label tidak tersedia: kartu cukup tidak menampilkan baris Produk.
    }

    return hasil;
  }

  Future<void> _syncAll() async {
    if (_isSyncingAll || _waitingData.isEmpty) return;
    setState(() => _isSyncingAll = true);

    final int before = _waitingData.length;
    int synced = 0;

    try {
      await _syncService
          .syncWaiting(limit: 500)
          .timeout(const Duration(seconds: 60));
      await _loadAllData(showLoading: false);
      synced = before - _waitingData.length;
    } on TimeoutException {
      synced = 0;
    } catch (_) {
      synced = 0;
    } finally {
      if (mounted) setState(() => _isSyncingAll = false);
    }

    if (!mounted) return;

    _showMessage(
      synced > 0
          ? '$synced data berhasil disinkronkan.'
          : 'Belum ada data yang terkirim. Periksa internet/server.',
      success: synced > 0,
    );
  }

  Future<void> _syncOne(NonOssLocalData data) async {
    if (_syncingIds.contains(data.clientUuid)) return;

    setState(() => _syncingIds.add(data.clientUuid));

    bool success = false;
    try {
      success = await _syncService
          .syncOne(data)
          .timeout(const Duration(seconds: 30));
      await _loadAllData(showLoading: false);
    } on TimeoutException {
      success = false;
    } catch (_) {
      success = false;
    } finally {
      if (mounted) {
        setState(() => _syncingIds.remove(data.clientUuid));
      }
    }

    if (!mounted) return;

    _showMessage(
      success
          ? '${data.displayName} berhasil disinkronkan.'
          : 'Sinkronisasi gagal. Periksa internet atau server lalu coba lagi.',
      success: success,
    );
  }

  Future<void> _continueDraft(NonOssLocalData data) async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => NonOssFormPage(editingData: data),
      ),
    );
    // Form draft selalu pop lewat popUntil(isFirst) atau submit biasa;
    // baik hasilnya apa pun, muat ulang supaya daftar tetap sinkron.
    await _loadAllData(showLoading: false);
  }

  Future<void> _openDetail(NonOssLocalData data) async {
    final Object? result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => SubmissionDetailPage(
          data: data,
          syncService: _syncService,
          queueService: _queueService,
        ),
      ),
    );

    if (result == 'synced' || result == 'deleted' || result == 'edited') {
      await _loadAllData(showLoading: false);
    }
  }

  Future<void> _openRiwayat() async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(builder: (_) => const RiwayatPage()),
    );
    await _loadAllData(showLoading: false);
  }

  void _toggleExpand(String clientUuid) {
    setState(() {
      _expandedUuid = _expandedUuid == clientUuid ? null : clientUuid;
    });
  }

  void _showMessage(
    String message, {
    required bool success,
    Color textColor = Colors.white,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: textColor)),
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

  @override
  Widget build(BuildContext context) {
    final bool tampilkanTombolSemua =
        !_isLoading && (_waitingData.isNotEmpty || _isSyncingAll);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        titleSpacing: 4,
        title: const Text(
          'Antrean Sinkronisasi',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : () => _loadAllData(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: tampilkanTombolSemua
          ? SyncBottomBar(
              readyCount: _waitingData.length,
              draftCount: _draftData.length,
              isSyncing: _isSyncingAll,
              onSyncAll: _syncAll,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () => _loadAllData(showLoading: false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double contentWidth = constraints.maxWidth >= 1100
                  ? 1080
                  : constraints.maxWidth;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SyncConnectionBanner(
                          lastSyncText: lastSyncLabel(_lastSyncedAt),
                        ),
                        const SizedBox(height: 14),
                        SyncSummaryCard(
                          isLoading: _isLoading,
                          waitingCount: _waitingData.length,
                          draftCount: _draftData.length,
                        ),
                        const SizedBox(height: 22),
                        _buildSectionHeader(
                          context,
                          'Siap Sinkronisasi',
                          count: _isLoading ? null : _waitingData.length,
                        ),
                        const SizedBox(height: 10),
                        if (_isLoading)
                          const SyncReadySkeleton()
                        else if (_waitingData.isEmpty) ...<Widget>[
                          const AppBanner(
                            tone: BannerTone.success,
                            icon: Icons.check_circle_rounded,
                            message: 'Semua data siap sync sudah terkirim.',
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: _openRiwayat,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Lihat Riwayat'),
                          ),
                        ] else ...<Widget>[
                          for (final NonOssLocalData data in _waitingData)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SyncReadyCard(
                                key: ValueKey<String>(data.clientUuid),
                                data: data,
                                produkLabels: _produkLabels,
                                syncing:
                                    _isSyncingAll ||
                                    _syncingIds.contains(data.clientUuid),
                                onOpenDetail: () => _openDetail(data),
                                onSync: () => _syncOne(data),
                              ),
                            ),
                        ],
                        if (!_isLoading && _draftData.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          _buildSectionHeader(
                            context,
                            'Draft Belum Lengkap',
                            count: _draftData.length,
                            subtitle:
                                'Lengkapi data berikut agar dapat diikutsertakan '
                                'dalam sinkronisasi server.',
                          ),
                          const SizedBox(height: 10),
                          for (final NonOssLocalData data in _draftData)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SyncDraftCard(
                                key: ValueKey<String>(data.clientUuid),
                                data: data,
                                expanded: _expandedUuid == data.clientUuid,
                                onToggleExpand: () =>
                                    _toggleExpand(data.clientUuid),
                                onOpenDetail: () => _openDetail(data),
                                onContinue: () => _continueDraft(data),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    int? count,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
