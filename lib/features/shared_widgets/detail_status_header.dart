import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Satu badge kecil pada header (jenis, status, dsb).
class StatusBadge {
  const StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;
}

/// Kartu header ringkasan di paling atas halaman detail: judul (nama
/// usaha/ajuan), badge-badge (jenis, status), subjudul opsional (mis.
/// tanggal dibuat), dan pesan error opsional (mis. alasan sync gagal).
///
/// Dipakai bersama oleh halaman detail Riwayat dan halaman detail
/// Ajuan/Sinkronisasi supaya tampilan kedua halaman konsisten, walau
/// makna badge-nya berbeda di masing-masing konteks.
class StatusHeaderCard extends StatelessWidget {
  const StatusHeaderCard({
    super.key,
    required this.title,
    required this.badges,
    this.subtitle,
    this.errorMessage,
  });

  final String title;
  final List<StatusBadge> badges;
  final String? subtitle;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final StatusBadge badge in badges) _BadgeChip(badge: badge),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
            if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.error_outline_rounded, size: 15, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final StatusBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge.text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badge.color,
        ),
      ),
    );
  }
}