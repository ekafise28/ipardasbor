import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../non_oss/offline/non_oss_local_data.dart';
import 'submission_row.dart';

/// Tabel daftar ajuan yang menunggu sinkronisasi, lengkap dengan header
/// kolom dan baris [SubmissionRow] yang bisa di-expand.
class SyncTable extends StatelessWidget {
  const SyncTable({
    super.key,
    required this.waitingData,
    required this.expandedUuid,
    required this.syncingIds,
    required this.onToggleExpand,
    required this.onOpenDetail,
    required this.onSync,
  });

  final List<NonOssLocalData> waitingData;
  final String? expandedUuid;
  final Set<String> syncingIds;
  final ValueChanged<String> onToggleExpand;
  final ValueChanged<NonOssLocalData> onOpenDetail;
  final ValueChanged<NonOssLocalData> onSync;

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(context),
          for (final NonOssLocalData data in waitingData)
            SubmissionRow(
              key: ValueKey(data.clientUuid),
              data: data,
              expanded: expandedUuid == data.clientUuid,
              syncing: syncingIds.contains(data.clientUuid),
              onToggleExpand: () => onToggleExpand(data.clientUuid),
              onOpenDetail: () => onOpenDetail(data),
              onSync: () => onSync(data),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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