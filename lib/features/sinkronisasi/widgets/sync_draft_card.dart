import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/draft_completeness.dart';
import 'package:ipardasbor/features/pengawasan/non_oss/offline/non_oss_local_data.dart';

import 'sync_formatters.dart';

/// Ikon tiap bagian form, urutannya sama dengan
/// [DraftCompletenessChecker.checkModules].
const List<IconData> _ikonBagian = <IconData>[
  Icons.store_outlined,
  Icons.location_city_outlined,
  Icons.gps_fixed_rounded,
  Icons.contact_phone_outlined,
  Icons.travel_explore_rounded,
  Icons.fact_check_outlined,
  Icons.photo_camera_outlined,
];

/// Kartu satu draft. Bisa dilipat: saat terbuka menampilkan progres
/// kelengkapan form dan rincian tiap bagian.
class SyncDraftCard extends StatelessWidget {
  const SyncDraftCard({
    super.key,
    required this.data,
    required this.expanded,
    required this.onToggleExpand,
    required this.onOpenDetail,
    required this.onContinue,
  });

  final NonOssLocalData data;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenDetail;

  /// Membuka form untuk melanjutkan pengisian draft ini.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const Color draftColor = Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.tintBackground(
                          context,
                          draftColor,
                          AppTheme.menuTentangBg,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: draftColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            data.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Diubah ${formatTanggal(data.updatedAt.toLocal())}'
                            ' · Draft Offline',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: draftColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(
                          color: draftColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textMuted,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Isi hanya dibangun saat terbuka, supaya pemeriksaan kelengkapan
          // tidak jalan untuk draft yang tertutup.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: expanded
                ? _DraftBody(
                    data: data,
                    onOpenDetail: onOpenDetail,
                    onContinue: onContinue,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _DraftBody extends StatelessWidget {
  const _DraftBody({
    required this.data,
    required this.onOpenDetail,
    required this.onContinue,
  });

  final NonOssLocalData data;
  final VoidCallback onOpenDetail;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final List<DraftModule> modules = DraftCompletenessChecker.checkModules(
      data.payload,
      data.photoPaths,
    );
    final int total = modules.length;
    final int lengkap = modules.where((DraftModule m) => m.isComplete).length;
    final int persen = total == 0 ? 0 : ((lengkap / total) * 100).round();
    final Color progressColor = lengkap == total
        ? AppTheme.success
        : AppTheme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Progres Kelengkapan Formulir',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$persen%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : lengkap / total,
              minHeight: 7,
              color: progressColor,
              backgroundColor: AppTheme.border(context),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '$lengkap dari $total bagian lengkap',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${total - lengkap} bagian tertunda',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'RINCIAN BAGIAN FORMULIR',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < modules.length; i++)
            _ModuleRow(
              nomor: i + 1,
              module: modules[i],
              icon: i < _ikonBagian.length
                  ? _ikonBagian[i]
                  : Icons.circle_outlined,
            ),
          if (lengkap == total) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Semua bagian sudah lengkap. Buka formulir untuk meninjau '
              'kembali, lalu simpan agar data ikut dikirim.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text(
                'Lanjutkan Isi Formulir',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: onOpenDetail,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary(context),
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 16),
              label: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.nomor,
    required this.module,
    required this.icon,
  });

  final int nomor;
  final DraftModule module;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool lengkap = module.isComplete;
    final Color color = lengkap ? AppTheme.success : AppTheme.warning;

    final String keterangan = lengkap
        ? (module.completeNote ?? 'Sudah lengkap')
        : 'Belum diisi: ${module.missing.join(', ')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: lengkap
            ? AppTheme.tintBackground(
                context,
                AppTheme.success,
                AppTheme.menuKeamananBg,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              lengkap ? Icons.check_rounded : icon,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$nomor. ${module.title}',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  keterangan,
                  style: TextStyle(
                    color: lengkap
                        ? AppTheme.textSecondary(context)
                        : AppTheme.warning,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}