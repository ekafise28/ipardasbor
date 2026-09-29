import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';
import 'package:ipardasbor/features/non_oss/offline/offline_database.dart';
import 'package:ipardasbor/features/non_oss/offline/offline_queue_service.dart';
import 'package:ipardasbor/features/non_oss/offline/sync_service.dart';
import 'package:ipardasbor/features/non_oss/services/non_oss_service.dart';
import 'package:ipardasbor/features/sinkronisasi/pages/submission_detail_page.dart';
import 'package:ipardasbor/features/sinkronisasi/sync_page.dart';

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
    _queueService = OfflineQueueService(database: OfflineDatabase.instance);
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final List<NotificationItem> semua =
        await NotificationService.instance.list(type: _filter, limit: 200);
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

    switch (item.targetType) {
      case 'submission_detail':
        await _bukaDetailAjuan(item.targetId);
        break;
      case 'sync_page':
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const SyncPage()));
        break;
      default:
        break;
    }

    await _muat();
  }

  Future<void> _bukaDetailAjuan(String? clientUuid) async {
    if (clientUuid == null) return;

    final NonOssLocalData? data =
        await OfflineDatabase.instance.getByClientUuid(clientUuid);

    if (data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajuan ini sudah tidak ada (mungkin sudah terkirim atau dihapus).'),
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
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _muat,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _NotificationTile(item: _items[i], onTap: () => _bukaNotifikasi(_items[i])),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final Map<String, VoidCallback> chips = {
      'Semua': () {
        setState(() {
          _filter = null;
          _bukaFilterBelumDibaca = false;
        });
        _muat();
      },
      'Belum dibaca': () {
        setState(() {
          _filter = null;
          _bukaFilterBelumDibaca = true;
        });
        _muat();
      },
      'Gagal Sync': () {
        setState(() {
          _filter = NotificationType.syncFailed;
          _bukaFilterBelumDibaca = false;
        });
        _muat();
      },
      'Menunggu Lama': () {
        setState(() {
          _filter = NotificationType.waitingTooLong;
          _bukaFilterBelumDibaca = false;
        });
        _muat();
      },
      'Draft': () {
        setState(() {
          _filter = NotificationType.draftLingering;
          _bukaFilterBelumDibaca = false;
        });
        _muat();
      },
    };

    bool selected(String label) {
      if (label == 'Semua') return _filter == null && !_bukaFilterBelumDibaca;
      if (label == 'Belum dibaca') return _bukaFilterBelumDibaca;
      if (label == 'Gagal Sync') return _filter == NotificationType.syncFailed;
      if (label == 'Menunggu Lama') return _filter == NotificationType.waitingTooLong;
      if (label == 'Draft') return _filter == NotificationType.draftLingering;
      return false;
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: chips.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.key),
                    selected: selected(e.key),
                    onSelected: (_) => e.value(),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Belum ada notifikasi.',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
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
        NotificationType.syncSuccess => (Icons.check_circle_outline_rounded, Colors.green),
        NotificationType.waitingTooLong => (Icons.cloud_off_rounded, Colors.orange),
        NotificationType.draftLingering => (Icons.edit_note_rounded, Colors.blueGrey),
      };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _tampilan;

    return Material(
      color: item.isRead ? AppTheme.surface(context) : color.withValues(alpha: 0.08),
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
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 13.5,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt.toLocal()),
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 6, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}