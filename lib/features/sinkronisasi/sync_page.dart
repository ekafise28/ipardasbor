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
                        _buildSummaryCard(),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const _TableLoading()
                        else if (_waitingData.isEmpty)
                          const _EmptyState()
                        else
                          _buildTable(),
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1218273D),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFF9F0A), Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Menunggu Sinkronisasi',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isLoading
                      ? 'Memuat data...'
                      : '${_waitingData.length} data tersimpan aman di perangkat',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _waitingData.isEmpty || _isSyncingAll || _isLoading
                ? null
                : _syncAll,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.surfaceMuted(context),
              disabledForegroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isSyncingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(_isSyncingAll ? 'Proses' : 'Sync Semua'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),
          for (final NonOssLocalData data in _waitingData)
            _SubmissionRow(
              key: ValueKey(data.clientUuid),
              data: data,
              expanded: _expandedUuid == data.clientUuid,
              syncing: _syncingIds.contains(data.clientUuid),
              onToggleExpand: () => _toggleExpand(data.clientUuid),
              onOpenDetail: () => _openDetail(data),
              onSync: () => _syncOne(data),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final TextStyle style = TextStyle(
      color: AppTheme.textSecondary(context),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('NAMA USAHA', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 3, child: Text('TANGGAL', style: style)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  const _SubmissionRow({
    super.key,
    required this.data,
    required this.expanded,
    required this.syncing,
    required this.onToggleExpand,
    required this.onOpenDetail,
    required this.onSync,
  });

  final NonOssLocalData data;
  final bool expanded;
  final bool syncing;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenDetail;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final bool failed = data.isFailed;
    final Color statusColor = failed
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFF9500);

    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border(context)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    data.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        failed ? 'GAGAL' : 'PENDING',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatDate(data.createdAt),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildExpandedContent(context, failed),
          secondChild: const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool failed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldColorDynamic(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (failed && data.lastError != null) ...[
            Text(
              data.lastError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textColor(context),
                    side: BorderSide(color: AppTheme.border(context)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Lihat Detail'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: syncing ? null : onSync,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 17),
                  label: const Text('Sync'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _TableLoading extends StatelessWidget {
  const _TableLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Memuat data tertunda...',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Colors.green),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Semua data sudah tersinkronisasi.',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}