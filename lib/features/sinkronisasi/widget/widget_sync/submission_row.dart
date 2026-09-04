import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../non_oss/offline/non_oss_local_data.dart';

/// Satu baris tabel di [SyncPage]. Bisa di-tap untuk expand/collapse
/// menampilkan tombol "Lihat Detail" dan "Sync" (atau "Lanjutkan Isi"
/// untuk data berstatus draft).
class SubmissionRow extends StatelessWidget {
  const SubmissionRow({
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

  /// Untuk data biasa: memicu proses sync ke server.
  /// Untuk data draft: memicu buka form untuk melanjutkan pengisian.
  /// Perbedaan perilaku ditentukan oleh pemanggil ([SyncPage]) berdasarkan
  /// [NonOssLocalData.isDraft], bukan oleh widget ini.
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final bool isDraft = data.isDraft;
    final bool failed = data.isFailed;

    final Color statusColor = isDraft
        ? const Color(0xFF6B7280)
        : (failed ? const Color(0xFFFF3B30) : const Color(0xFFFF9500));

    final String statusLabel = isDraft
        ? 'DRAFT'
        : (failed ? 'GAGAL' : 'PENDING');

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
                        statusLabel,
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
          firstChild: _buildExpandedContent(context, isDraft, failed),
          secondChild: const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isDraft, bool failed) {
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
          if (!isDraft && failed && data.lastError != null) ...[
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
          if (isDraft) ...[
            Text(
              'Data ini belum lengkap dan belum ikut proses sinkronisasi.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
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
                    backgroundColor: isDraft
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF007AFF),
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
                      : Icon(
                          isDraft ? Icons.edit_note_rounded : Icons.sync_rounded,
                          size: 17,
                        ),
                  label: Text(isDraft ? 'Lanjutkan Isi' : 'Sync'),
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