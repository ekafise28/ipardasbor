import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../app/app_theme.dart';

/// Status koneksi ke server saat ini, dipakai untuk warna & ikon awan di
/// kartu sambutan Home. BERBEDA dari `SyncStatus` di
/// `offline/sync_status.dart` (status per-ajuan seperti draft/pending/
/// synced) - enum ini soal bisa/tidaknya SERVER dijangkau sekarang,
/// dicek lewat ping (NonOssService.isServerAvailable), bukan cuma status
/// jaringan device.
enum ServerConnectionStatus { checking, online, offline }

class WelcomeCard extends StatefulWidget {
  const WelcomeCard({
    super.key,
    this.serverStatus = ServerConnectionStatus.checking,
    this.offlineCount = 0,
    this.onTapSyncStatus,
  });

  final ServerConnectionStatus serverStatus;
  final int offlineCount;

  /// Dipanggil saat icon status sync ditekan. Kalau null, icon tetap
  /// tampil tapi tidak bisa ditekan (mis. dipakai di tempat lain tanpa
  /// perlu navigasi).
  final VoidCallback? onTapSyncStatus;

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  String _userName = 'Petugas Pengawasan';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final List<String?> userData = await Future.wait([
      SecureStorage.getUserName(),
      SecureStorage.getUserRole(),
    ]);

    if (!mounted) return;

    setState(() {
      final String? storedName = userData[0];
      final String? storedRole = userData[1];

      if (storedName != null && storedName.trim().isNotEmpty) {
        _userName = storedName.trim();
      }

      if (storedRole != null && storedRole.trim().isNotEmpty) {
        _userRole = storedRole.trim();
      }
    });
  }

  String get _formattedRole {
    if (_userRole.trim().isEmpty) {
      return 'Petugas Pengawasan';
    }

    return _userRole
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get _greeting {
    final int hour = DateTime.now().hour;

    if (hour < 11) {
      return 'Selamat pagi';
    }

    if (hour < 15) {
      return 'Selamat siang';
    }

    if (hour < 18) {
      return 'Selamat sore';
    }

    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppTheme.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -38,
            right: -25,
            child: _DecorationCircle(size: 130, color: Color(0x16FFFFFF)),
          ),
          const Positioned(
            bottom: -45,
            right: 55,
            child: _DecorationCircle(size: 100, color: Color(0x0FFFFFFF)),
          ),
          Positioned(
            right: 15,
            bottom: -12,
            child: Icon(
              Icons.fact_check_rounded,
              size: 82,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 57,
                  height: 57,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_greeting,',
                            style: const TextStyle(
                              color: Color(0xFFDCEBFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.waving_hand_rounded,
                            color: Color(0xFFFFD166),
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppTheme.textOnBrandBadge,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _formattedRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textOnBrandBadge,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SyncStatusChip(
                  status: widget.serverStatus,
                  offlineCount: widget.offlineCount,
                  onTap: widget.onTapSyncStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ikon terhubung dengan internet
// ikon status koneksi server + jumlah data tersimpan offline
class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({
    required this.status,
    required this.offlineCount,
    this.onTap,
  });

  final ServerConnectionStatus status;
  final int offlineCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _ChipStyle style = _resolveStyle();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(style.icon, color: style.iconColor, size: 21),
            ),
          ),
        ),
        if (offlineCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
                child: Text(
                  offlineCount > 99 ? '99+' : '$offlineCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  _ChipStyle _resolveStyle() {
    switch (status) {
      case ServerConnectionStatus.checking:
        return const _ChipStyle(
          icon: Icons.cloud_sync_rounded,
          iconColor: Color(0xFFE0E0E0),
        );
      case ServerConnectionStatus.offline:
        return const _ChipStyle(
          icon: Icons.cloud_off_rounded,
          iconColor: Color(0xFFFF8A80),
        );
      case ServerConnectionStatus.online:
        return offlineCount > 0
            ? const _ChipStyle(
                icon: Icons.cloud_upload_rounded,
                iconColor: Color(0xFFFFD166),
              )
            : const _ChipStyle(
                icon: Icons.cloud_done_rounded,
                iconColor: Color(0xFFB9F6CA),
              );
    }
  }
}

class _ChipStyle {
  const _ChipStyle({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;
}

class _DecorationCircle extends StatelessWidget {
  const _DecorationCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
