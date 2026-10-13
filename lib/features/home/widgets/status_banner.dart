import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_banner.dart';
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
    if (serverStatus == ServerConnectionStatus.offline) {
      return _BannerSpec(
        key: 'offline',
        tone: BannerTone.warning,
        icon: Icons.cloud_off_rounded,
        title: 'Mode offline',
        body: offlineCount > 0
            ? 'Server tidak terjangkau. $offlineCount data tersimpan di perangkat.'
            : 'Server tidak terjangkau. Data baru akan disimpan di perangkat.',
      );
    }

    if (serverStatus == ServerConnectionStatus.online && offlineCount > 0) {
      return _BannerSpec(
        key: 'pending',
        tone: BannerTone.info,
        icon: Icons.cloud_upload_rounded,
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
          children: [...previous, ?current],
        ),
        child: spec == null
            ? const SizedBox(key: ValueKey('none'), width: double.infinity)
            : Padding(
                key: ValueKey(spec.key),
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: AppBanner(
                    tone: spec.tone,
                    icon: spec.icon,
                    title: spec.title,
                    message: spec.body,
                    actionLabel: spec.actionLabel,
                    onAction: onTap,
                  ),
                ),
              ),
      ),
    );
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
  });

  final String key;
  final BannerTone tone;
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
}
