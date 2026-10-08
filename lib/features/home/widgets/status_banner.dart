import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import 'welcome_card.dart' show ServerConnectionStatus;

/// Strip informasi di bawah kartu sambutan. Hanya muncul saat ada hal yang
/// perlu diketahui petugas:
///  - Server tidak terjangkau  -> "Mode offline"
///  - Online tapi ada data lokal belum terkirim -> "N data menunggu dikirim"
/// Saat semuanya beres (atau status masih dicek), banner tidak tampil.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.serverStatus,
    required this.offlineCount,
    this.onTap,
  });

  final ServerConnectionStatus serverStatus;
  final int offlineCount;

  /// Dipanggil saat tombol aksi ditekan (hanya ada di banner "menunggu dikirim").
  final VoidCallback? onTap;

  _BannerSpec? _resolve(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (serverStatus == ServerConnectionStatus.offline) {
      return _BannerSpec(
        key: 'offline',
        icon: Icons.cloud_off_rounded,
        accent: AppTheme.warning,
        background: AppTheme.warningSurface(context),
        titleColor: AppTheme.warningTitle(context),
        bodyColor: AppTheme.warningBody(context),
        title: 'Mode offline',
        body: offlineCount > 0
            ? 'Server tidak terjangkau. $offlineCount data tersimpan di perangkat.'
            : 'Server tidak terjangkau. Data baru akan disimpan di perangkat.',
      );
    }

    if (serverStatus == ServerConnectionStatus.online && offlineCount > 0) {
      final Color accent =
          isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
      return _BannerSpec(
        key: 'pending',
        icon: Icons.cloud_upload_rounded,
        accent: accent,
        background:
            isDark ? const Color(0xFF16263A) : const Color(0xFFE8F1FD),
        titleColor: AppTheme.textColor(context),
        bodyColor: AppTheme.textSecondary(context),
        title: '$offlineCount data menunggu dikirim',
        body: 'Kirim sekarang agar data tersinkron ke server.',
        actionLabel: 'Kirim',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final _BannerSpec? spec = _resolve(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        child: spec == null
            ? const SizedBox(key: ValueKey('none'), width: double.infinity)
            : Padding(
                key: ValueKey(spec.key),
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: _BannerBody(spec: spec, onTap: onTap),
                ),
              ),
      ),
    );
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.key,
    required this.icon,
    required this.accent,
    required this.background,
    required this.titleColor,
    required this.bodyColor,
    required this.title,
    required this.body,
    this.actionLabel,
  });

  final String key;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color titleColor;
  final Color bodyColor;
  final String title;
  final String body;
  final String? actionLabel;
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({required this.spec, this.onTap});

  final _BannerSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: spec.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: spec.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.icon, size: 18, color: spec.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: TextStyle(
                    color: spec.titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.body,
                  style: TextStyle(
                    color: spec.bodyColor,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (spec.actionLabel != null && onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: spec.accent,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                spec.actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}