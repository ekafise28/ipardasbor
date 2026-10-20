import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/non_oss/offline/draft_completeness.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';

// Catatan: tampilan tabel lama (SyncTable dan SubmissionRow) sudah diganti
// kartu: lihat sync_ready_card.dart dan sync_draft_card.dart. File ini
// dipertahankan karena dua hal di bawah masih dipakai halaman lain
// (mis. halaman Detail Ajuan).

/// Label dan warna tampilan sebuah ajuan lokal. Satu sumber untuk semua
/// tempat yang menampilkan status ajuan (halaman detail).
({String label, Color color}) submissionStatus(NonOssLocalData d) {
  if (d.isDraft) return (label: 'DRAFT', color: const Color(0xFF6B7280));
  if (d.isFailed) return (label: 'GAGAL', color: const Color(0xFFFF3B30));
  return (label: 'PENDING', color: const Color(0xFFFF9500));
}

/// Daftar bagian form yang belum lengkap, dikelompokkan per section.
/// [compact] = true untuk tampilan yang lebih rapat (font dan jarak lebih kecil).
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