import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../authentication/models/auth_user.dart';
import '../../authentication/services/auth_service.dart';
import '../../profile/profile_page.dart';
import '../../profile/services/profile_services.dart';

import '../../home/models/menu_data.dart';
import '../../home/pages/feature_placeholder_page.dart';
import '../../home/widgets/menu_list_tile.dart';

import '../widgets/profile_preview_card.dart';

import '../../non_oss/offline/auto_sync_controller.dart';
import '../../non_oss/offline/sync_service.dart';
import '../../non_oss/services/non_oss_service.dart';
import '../../../core/api/api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProfileService _profileService = ProfileService();
  late Future<AuthUser> _profileFuture;

  // List Menu preferensi yang ditampilkan di halaman pengaturan.
  static const List<MenuData> _preferenceMenus = [
    MenuData(
      title: 'Notifikasi',
      description: 'Atur preferensi notifikasi aplikasi',
      icon: Icons.notifications_none_rounded,
      color: AppTheme.menuNotifikasi,
      backgroundColor: AppTheme.menuNotifikasiBg,
    ),
    MenuData(
      title: 'Keamanan',
      description: 'Kelola PIN, biometrik, dan sesi login',
      icon: Icons.security_rounded,
      color: AppTheme.menuKeamanan,
      backgroundColor: AppTheme.menuKeamananBg,
    ),
  ];

  Widget _buildDarkModeTile() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        final bool isDark = themeMode == ThemeMode.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.menuTampilanBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                  color: AppTheme.menuTampilan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Tampilan (Alpha)',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Mode gelap aktif' : 'Mode terang aktif',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                activeTrackColor: AppTheme.menuTampilan,
                onChanged: (value) {
                  ThemeController.instance.setDarkMode(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Menu "Tentang Aplikasi" yang ditampilkan di halaman pengaturan.
  static const MenuData _aboutMenu = MenuData(
    title: 'Tentang Aplikasi',
    description: 'Versi aplikasi, kebijakan, dan bantuan',
    icon: Icons.info_outline_rounded,
    color: AppTheme.menuTentang,
    backgroundColor: AppTheme.menuTentangBg,
  );

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getProfile();
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }

  // Navigasi ke halaman menu yang dipilih.
  void _openMenu(MenuData menu) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeaturePlaceholderPage(menu: menu),
      ),
    );
  }

  // Navigasi ke halaman profil pengguna.
  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
  }

  // Menampilkan dialog konfirmasi untuk keluar dari akun.
  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(context),
          surfaceTintColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Keluar dari akun?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          content: Text(
            'Anda perlu masuk kembali untuk mengakses aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textColor(context),
                  side: BorderSide(color: AppTheme.border(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Keluar'),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildAutoSyncTile() {
    return ValueListenableBuilder<bool>(
      valueListenable: AutoSyncController.instance,
      builder: (context, isAuto, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.menuSinkronisasiBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAuto ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                  color: AppTheme.menuSinkronisasi,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinkronisasi Otomatis',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuto
                          ? 'Data terkirim otomatis saat ada internet'
                          : 'Data hanya terkirim saat Anda menekan Sync',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAuto,
                activeTrackColor: AppTheme.menuTampilan,
                onChanged: (value) async {
                  await AutoSyncController.instance.setEnabled(value);

                  // Kalau baru saja dinyalakan, coba sync sekali di tempat
                  // supaya data PENDING yang sudah menumpuk tidak perlu
                  // menunggu app dibuka ulang / koneksi berubah dulu.
                  if (value) {
                    final NonOssSyncService syncService = NonOssSyncService(
                      remote: NonOssService(ApiClient()),
                    );
                    unawaited(syncService.syncWaiting().catchError((_) {}));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<AuthUser>(
          future: _profileFuture,
          builder: (context, snapshot) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                ProfilePreviewCard(
                  user: snapshot.data,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  onTap: _openProfile,
                ),
                const SizedBox(height: 22),
                const _SectionLabel('Preferensi'),
                const SizedBox(height: 10),
                _buildDarkModeTile(),
                const SizedBox(height: 10),
                _buildAutoSyncTile(),
                const SizedBox(height: 10),
                for (final menu in _preferenceMenus) ...[
                  MenuListTile(menu: menu, onTap: () => _openMenu(menu)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                const _SectionLabel('Lainnya'),
                const SizedBox(height: 10),
                MenuListTile(
                  menu: _aboutMenu,
                  onTap: () => _openMenu(_aboutMenu),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Widget untuk menampilkan label bagian di halaman pengaturan.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.textSecondary(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}
