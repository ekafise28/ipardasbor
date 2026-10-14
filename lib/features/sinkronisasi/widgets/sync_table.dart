import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/non_oss/offline/draft_completeness.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';

// Lebar kolom dipakai bersama header dan baris, supaya selalu sejajar.
const int _flexNama = 5;
const int _flexStatus = 2;
const int _flexTanggal = 3;
const double _lebarPanah = 28;

/// Label dan warna tampilan sebuah ajuan lokal. Satu sumber untuk semua
/// tempat yang menampilkan status ajuan (tabel, halaman detail).
({String label, Color color}) submissionStatus(NonOssLocalData d) {
  if (d.isDraft) return (label: 'DRAFT', color: const Color(0xFF6B7280));
  if (d.isFailed) return (label: 'GAGAL', color: const Color(0xFFFF3B30));
  return (label: 'PENDING', color: const Color(0xFFFF9500));
}

/// Tabel daftar ajuan (menunggu sinkronisasi atau draft), lengkap dengan
/// header kolom dan baris [SubmissionRow] yang bisa di-expand.
class SyncTable extends StatelessWidget {
  const SyncTable({
    super.key,
    required this.items,
    required this.expandedUuid,
    required this.syncingIds,
    required this.onToggleExpand,
    required this.onOpenDetail,
    required this.onSync,
  });

  final List<NonOssLocalData> items;
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
        children: <Widget>[
          const _TableHeader(),
          for (final NonOssLocalData data in items)
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
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
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
        children: <Widget>[
          Expanded(
            flex: _flexNama,
            child: Text('NAMA USAHA', style: style),
          ),
          Expanded(
            flex: _flexStatus,
            child: Text('STATUS', style: style),
          ),
          Expanded(
            flex: _flexTanggal,
            child: Text('TANGGAL', style: style),
          ),
          const SizedBox(width: _lebarPanah),
        ],
      ),
    );
  }
}

/// Satu baris tabel di [SyncTable]. Bisa di-tap untuk expand/collapse
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
    final ({String label, Color color}) status = submissionStatus(data);

    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          expanded: expanded,
          child: InkWell(
            onTap: onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.border(context)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: _flexNama,
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
                    flex: _flexStatus,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _flexTanggal,
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(data.createdAt.toLocal()),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _lebarPanah,
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
        ),
        // Konten expand hanya dibangun saat dibuka (AnimatedCrossFade
        // membangun kedua child, termasuk checklist draft yang tertutup).
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: expanded
              ? _ExpandedContent(
                  data: data,
                  statusColor: status.color,
                  syncing: syncing,
                  onOpenDetail: onOpenDetail,
                  onSync: onSync,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.data,
    required this.statusColor,
    required this.syncing,
    required this.onOpenDetail,
    required this.onSync,
  });

  final NonOssLocalData data;
  final Color statusColor;
  final bool syncing;
  final VoidCallback onOpenDetail;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final bool isDraft = data.isDraft;
    final bool failed = data.isFailed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldColorDynamic(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isDraft && failed && data.lastError != null) ...<Widget>[
            Text(
              data.lastError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 11.5),
            ),
            const SizedBox(height: 10),
          ],
          if (isDraft) ...<Widget>[
            _DraftChecklist(data: data),
            const SizedBox(height: 10),
          ],
          Row(
            children: <Widget>[
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
                        ? statusColor
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
                          isDraft
                              ? Icons.edit_note_rounded
                              : Icons.sync_rounded,
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
}

/// Checklist bagian form yang masih perlu dilengkapi pada sebuah draft.
/// Menggantikan pesan generik lama supaya user langsung tahu apa yang
/// kurang, tanpa perlu membuka form dulu untuk mengetahuinya.
class _DraftChecklist extends StatelessWidget {
  const _DraftChecklist({required this.data});

  final NonOssLocalData data;

  @override
  Widget build(BuildContext context) {
    final List<DraftMissingItem> missing = DraftCompletenessChecker.check(
      data.payload,
      data.photoPaths,
    );

    if (missing.isEmpty) {
      return Text(
        'Semua data sudah lengkap. Tekan "Lanjutkan Isi" untuk meninjau '
        'kembali sebelum dikirim.',
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontSize: 11.5,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bagian yang masih perlu dilengkapi:',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DraftMissingList(items: missing, compact: true),
      ],
    );
  }
}

/// Daftar bagian form yang belum lengkap, dikelompokkan per section.
/// [compact] = true untuk dipakai di dalam tabel (font dan jarak lebih kecil).
class DraftMissingList extends StatelessWidget {
  const DraftMissingList({
    super.key,
    required this.items,
    this.compact = false,
  });

  final List<DraftMissingItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> grouped = <String, List<String>>{};
    for (final DraftMissingItem item in items) {
      grouped.putIfAbsent(item.section, () => <String>[]).add(item.label);
    }

    final double fontSection = compact ? 11 : 12;
    final double fontLabel = compact ? 11.5 : 12;
    final double jarakSection = compact ? 6 : 10;
    final double jarakLabel = compact ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final MapEntry<String, List<String>> entry in grouped.entries)
          Padding(
            padding: EdgeInsets.only(bottom: jarakSection),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.key,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: fontSection,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                for (final String label in entry.value)
                  Padding(
                    padding: EdgeInsets.only(left: 2, bottom: jarakLabel),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 13,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: fontLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
