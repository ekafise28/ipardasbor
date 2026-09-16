import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

/// Kartu ringkasan di puncak [SyncPage]: jumlah data yang menunggu
/// sinkronisasi dan tombol "Sync Semua".
class SyncSummaryCard extends StatelessWidget {
  const SyncSummaryCard({
    super.key,
    required this.isLoading,
    required this.isSyncingAll,
    required this.waitingCount,
    required this.draftCount,
    required this.onSyncAll,
  });

  final bool isLoading;
  final bool isSyncingAll;
  final int waitingCount;

  /// Jumlah draft (belum lengkap, TIDAK ikut diproses tombol "Sync
  /// Semua"). Disebutkan terpisah di pesan supaya user tidak bingung
  /// kenapa jumlah yang benar-benar terkirim beda dari total data yang
  /// tersimpan di perangkat.
  final int draftCount;

  final VoidCallback onSyncAll;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (isLoading)
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  )
                else ...[
                  Text(
                    waitingCount == 0
                        ? '✅ Semua data siap sync sudah terkirim.'
                        : '🔃 $waitingCount data tersimpan aman di perangkat.',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  if (draftCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📝 $draftCount draft belum lengkap - lihat di bagian '
                      'Draft di bawah.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: waitingCount == 0 || isSyncingAll || isLoading
                ? null
                : onSyncAll,
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
            icon: isSyncingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: Text(isSyncingAll ? 'Proses' : 'Sync Semua'),
          ),
        ],
      ),
    );
  }
}