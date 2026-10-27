import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/non_oss_local_data.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/non_oss_queue_store.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/offline_queue_service.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/sync_service.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/services/non_oss_service.dart';
import 'package:ipardasbor/features/sinkronisasi/pages/sync_submission_detail_page.dart';
import 'package:ipardasbor/features/sinkronisasi/sync_page.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart'
    show StatusFilterBar, StatusFilterOption;
import 'package:ipardasbor/shared/widgets/page_states.dart' show EmptyListState;
import 'package:ipardasbor/shared/widgets/skeleton.dart'
    show NotificationSkeleton;

import '../../../app/app_theme.dart';
import '../../../core/api/api_client.dart';
import 'models/notification_item.dart';
import 'services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final NonOssSyncService _syncService;
  late final OfflineQueueService _queueService;

  List<NotificationItem> _items = <NotificationItem>[];
  NotificationType? _filter;
  bool _loading = true;
  bool _bukaFilterBelumDibaca = false;

  @override
  void initState() {
    super.initState();
    _syncService = NonOssSyncService(remote: NonOssService(ApiClient()));
    _queueService = OfflineQueueService(database: NonOssQueueStore.instance);
    _muat();
  }

  static const String _kunciBelumDibaca = 'belum_dibaca';

  /// Kunci chip yang sedang aktif; null = Semua.
  String? get _kunciFilter {
    if (_bukaFilterBelumDibaca) return _kunciBelumDibaca;
    return _filter?.name;
  }

  void _pilihFilter(String? kunci) {
    if (kunci == _kunciFilter) return;
    setState(() {
      _bukaFilterBelumDibaca = kunci == _kunciBelumDibaca;
      _filter = NotificationType.values
          .where((NotificationType t) => t.name == kunci)
          .firstOrNull;
    });
    _muat();
  }

  Future<void> _muat() async {
    final List<NotificationItem> semua = await NotificationService.instance
        .list(type: _filter, limit: 200);
    if (!mounted) return;
    setState(() {
      _items = _bukaFilterBelumDibaca
          ? semua.where((n) => !n.isRead).toList()
          : semua;
      _loading = false;
    });
  }

  Future<void> _tandaiSemuaDibaca() async {
    await NotificationService.instance.markAllRead();
    await _muat();
  }

  Future<void> _bukaNotifikasi(NotificationItem item) async {
    if (item.id != null && !item.isRead) {
      await NotificationService.instance.markRead(item.id!);
    }

    if (!mounted) return;

    switch (item.targetType) {
      case 'submission_detail':
        await _bukaDetailAjuan(item.targetId);
        break;
      case 'sync_page':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SyncPage()));
        break;
      default:
        break;
    }

    if (!mounted) return;
    await _muat();
  }

  Future<void> _bukaDetailAjuan(String? clientUuid) async {
    if (clientUuid == null) return;

    final NonOssLocalData? data = await NonOssQueueStore.instance
        .getByClientUuid(clientUuid);

    if (data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajuan ini sudah tidak ada (mungkin sudah terkirim atau dihapus).',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubmissionDetailPage(
          data: data,
          syncService: _syncService,
          queueService: _queueService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: _items.any((n) => !n.isRead) ? _tandaiSemuaDibaca : null,
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const NotificationSkeleton()
                : _items.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _muat,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _NotificationTile(
                        item: _items[i],
                        onTap: () => _bukaNotifikasi(_items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StatusFilterBar(
        selected: _kunciFilter,
        onChanged: _pilihFilter,
        options: <StatusFilterOption>[
          const StatusFilterOption(
            value: null,
            label: 'Semua',
            color: AppTheme.primaryColor,
          ),
          const StatusFilterOption(
            value: _kunciBelumDibaca,
            label: 'Belum dibaca',
            color: AppTheme.primaryColor,
          ),
          StatusFilterOption(
            value: NotificationType.syncFailed.name,
            label: 'Gagal Sync',
            color: AppTheme.danger,
          ),
          StatusFilterOption(
            value: NotificationType.waitingTooLong.name,
            label: 'Menunggu Lama',
            color: AppTheme.warning,
          ),
          StatusFilterOption(
            value: NotificationType.draftLingering.name,
            label: 'Draft',
            color: AppTheme.menuTentang,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final bool adaFilter = _kunciFilter != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        EmptyListState(
          icon: Icons.notifications_none_rounded,
          title: adaFilter ? 'Tidak ada yang cocok' : 'Belum ada notifikasi',
          message: adaFilter
              ? 'Tidak ada notifikasi untuk filter ini.'
              : 'Pemberitahuan sinkronisasi dan draft akan muncul di sini.',
          actionLabel: adaFilter ? 'Tampilkan semua' : null,
          actionIcon: Icons.restart_alt_rounded,
          onAction: adaFilter ? () => _pilihFilter(null) : null,
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  (IconData, Color) get _tampilan => switch (item.type) {
    NotificationType.syncFailed => (Icons.error_outline_rounded, Colors.red),
    NotificationType.syncSuccess => (
      Icons.check_circle_outline_rounded,
      Colors.green,
    ),
    NotificationType.waitingTooLong => (Icons.cloud_off_rounded, Colors.orange),
    NotificationType.draftLingering => (
      Icons.edit_note_rounded,
      Colors.blueGrey,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _tampilan;

    return Material(
      color: item.isRead
          ? AppTheme.surface(context)
          : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        fontSize: 13.5,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(item.createdAt.toLocal()),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 6, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
