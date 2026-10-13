import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/cache/cache_status.dart';
import 'package:ipardasbor/core/network/network_status.dart';

enum BannerTone { warning, info }

enum BannerLayout { strip, card }

/// Komponen banner dasar. Strip = garis tipis, card = kartu dengan ikon bulat.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.layout = BannerLayout.card,
    this.actionLabel,
    this.onAction,
  });

  final BannerTone tone;
  final String message;
  final String? title;
  final IconData icon;
  final BannerLayout layout;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color accent, Color surface, Color titleColor, Color bodyColor) =
        switch (tone) {
      BannerTone.warning => (
        AppTheme.warning,
        AppTheme.warningSurface(context),
        AppTheme.warningTitle(context),
        AppTheme.warningBody(context),
      ),
      BannerTone.info => (
        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
        isDark ? const Color(0xFF16263A) : const Color(0xFFE8F1FD),
        AppTheme.textColor(context),
        AppTheme.textSecondary(context),
      ),
    };

    if (layout == BannerLayout.strip) {
      return Container(
        width: double.infinity,
        color: surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: title != null ? bodyColor : titleColor,
                    fontSize: title != null ? 11.5 : 12.5,
                    height: 1.25,
                    fontWeight:
                        title != null ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

/// Strip tipis, hanya tampil saat data berasal dari cache.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: CacheStatus.instance,
      builder: (_, DateTime? waktu, _) {
        if (waktu == null) return const SizedBox.shrink();
        return AppBanner(
          tone: BannerTone.warning,
          layout: BannerLayout.strip,
          icon: Icons.cloud_off_rounded,
          message:
              'Mode offline · data per ${DateFormat('dd MMM, HH:mm').format(waktu)}',
        );
      },
    );
  }
}

/// Kotak info, hanya tampil saat tidak ada jaringan.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, this.pesan = NetworkGuard.pesanVerifikasi});
  final String pesan;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.instance,
      builder: (_, bool offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AppBanner(
            tone: BannerTone.warning,
            icon: Icons.cloud_off_rounded,
            message: pesan,
          ),
        );
      },
    );
  }
}