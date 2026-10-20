import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Tombol "Sinkronkan Semua Data Siap" yang menempel di bawah layar.
class SyncBottomBar extends StatelessWidget {
  const SyncBottomBar({
    super.key,
    required this.readyCount,
    required this.draftCount,
    required this.isSyncing,
    required this.onSyncAll,
  });

  final int readyCount;

  /// Draft tidak ikut terkirim; diberi catatan kecil kalau ada.
  final int draftCount;

  final bool isSyncing;
  final VoidCallback onSyncAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: isSyncing || readyCount == 0 ? null : onSyncAll,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.surfaceMuted(context),
                  disabledForegroundColor: AppTheme.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  isSyncing
                      ? 'Mengirim data...'
                      : 'Sinkronkan Semua Data Siap ($readyCount)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (draftCount > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$draftCount draft belum lengkap tidak ikut dikirim.',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}