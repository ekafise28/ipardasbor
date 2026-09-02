import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api/api_client.dart';

import '../non_oss/offline/non_oss_local_data.dart';
import '../non_oss/offline/offline_database.dart';
import '../non_oss/offline/offline_queue_service.dart';
import '../non_oss/offline/sync_service.dart';
import '../non_oss/services/non_oss_service.dart';

import 'pages/submission_detail_page.dart';
import 'widget/widget_sync/empty_state.dart';
import 'widget/widget_sync/sync_summary_card.dart';
import 'widget/widget_sync/sync_table.dart';
import 'widget/widget_sync/table_loading.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final ApiClient _api;
  late final NonOssSyncService _syncService;
  late final OfflineQueueService _queueService;
  final OfflineDatabase _database = OfflineDatabase.instance;

  List<NonOssLocalData> _waitingData = <NonOssLocalData>[];
  final Set<String> _syncingIds = <String>{};
  String? _expandedUuid;

  bool _isLoading = true;
  bool _isSyncingAll = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _syncService = NonOssSyncService(remote: NonOssService(_api));
    _queueService = OfflineQueueService(database: _database);
    _loadWaitingData();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadWaitingData({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      await _database.restoreInterruptedSyncs();
      final List<NonOssLocalData> result = await _database.getWaiting(
        limit: 500,
      );

      if (!mounted) return;
      setState(() {
        _waitingData = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAll() async {
    if (_isSyncingAll || _waitingData.isEmpty) return;
    setState(() => _isSyncingAll = true);

    final int before = _waitingData.length;
    int synced = 0;

    try {
      await _syncService.syncWaiting(limit: 500).timeout(
        const Duration(seconds: 60),
      );
      await _loadWaitingData(showLoading: false);
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
      await _loadWaitingData(showLoading: false);
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

    if (result == 'synced' || result == 'deleted') {
      await _loadWaitingData(showLoading: false);
    }
  }

  void _toggleExpand(String clientUuid) {
    setState(() {
      _expandedUuid = _expandedUuid == clientUuid ? null : clientUuid;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        surfaceTintColor: AppTheme.surface(context),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textColor(context),
          ),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sinkronisasi',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Kirim data pengawasan yang tersimpan offline',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : () => _loadWaitingData(),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () => _loadWaitingData(showLoading: false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double contentWidth = constraints.maxWidth >= 1100
                  ? 1080
                  : constraints.maxWidth;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SyncSummaryCard(
                          isLoading: _isLoading,
                          isSyncingAll: _isSyncingAll,
                          waitingCount: _waitingData.length,
                          onSyncAll: _syncAll,
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const TableLoading()
                        else if (_waitingData.isEmpty)
                          const EmptyState()
                        else
                          SyncTable(
                            waitingData: _waitingData,
                            expandedUuid: _expandedUuid,
                            syncingIds: _syncingIds,
                            onToggleExpand: _toggleExpand,
                            onOpenDetail: _openDetail,
                            onSync: _syncOne,
                          ),
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
}