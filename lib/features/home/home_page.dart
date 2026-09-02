import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../dashboard/dashboard_page.dart';
import '../non_oss/non_oss_form_page.dart';
import '../sinkronisasi/sync_page.dart';
import '../riwayat/riwayat_page.dart';

import 'models/menu_data.dart';
import 'pages/feature_placeholder_page.dart';

import '../profile/profile_page.dart';
import '../settings/pages/settings_page.dart';

import 'widgets/menu_card.dart';
import 'widgets/menu_list_tile.dart';
import 'widgets/welcome_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGridView = true;

  static const List<MenuData> menus = [
    MenuData(
      title: 'Dashboard',
      description: 'Ringkasan statistik pengawasan',
      icon: Icons.bar_chart_rounded,
      color: AppTheme.menuDashboard,
      backgroundColor: AppTheme.menuDashboardBg,
    ),
    MenuData(
      title: 'Pengawasan OSS',
      description: 'Verifikasi proyek dan usaha OSS',
      icon: Icons.fact_check_outlined,
      color: AppTheme.menuOss,
      backgroundColor: AppTheme.menuOssBg,
    ),
    MenuData(
      title: 'Pengawasan Non-OSS',
      description: 'Pencatatan usaha di luar OSS',
      icon: Icons.domain_add_outlined,
      color: AppTheme.menuNonOss,
      backgroundColor: AppTheme.menuNonOssBg,
    ),
    MenuData(
      title: 'Pengawasan OTA',
      description: 'Verifikasi usaha dari platform OTA',
      icon: Icons.travel_explore_rounded,
      color: AppTheme.menuOta,
      backgroundColor: AppTheme.menuOtaBg,
    ),
    MenuData(
      title: 'Riwayat',
      description: 'Data pengawasan yang telah dilakukan',
      icon: Icons.history_rounded,
      color: AppTheme.menuRiwayat,
      backgroundColor: AppTheme.menuRiwayatBg,
    ),
    MenuData(
      title: 'Sinkronisasi',
      description: 'Perbarui dan kirim data aplikasi',
      icon: Icons.sync_rounded,
      color: AppTheme.menuSinkronisasi,
      backgroundColor: AppTheme.menuSinkronisasiBg,
    ),
    MenuData(
      title: 'Profil Petugas',
      description: 'Informasi akun dan profil petugas',
      icon: Icons.account_circle_outlined,
      color: AppTheme.menuProfil,
      backgroundColor: AppTheme.menuProfilBg,
    ),
  ];

  // Menu Fitur
  void _openMenu(BuildContext context, MenuData menu) {
    switch (menu.title) {
      case 'Dashboard':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const DashboardPage()));
        return;

      case 'Pengawasan Non-OSS':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const NonOssFormPage()));
        return;

      case 'Profil Petugas':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
        return;

      case 'Riwayat':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RiwayatPage()));
        return;

      case 'Sinkronisasi':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SyncPage()));
        return;

      default:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeaturePlaceholderPage(menu: menu),
          ),
        );
    }
  }

  void _showNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.surfaceMuted(context),
            ),
            SizedBox(width: 12),
            Text('Belum ada notifikasi baru.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final int crossAxisCount;

            if (constraints.maxWidth >= 1000) {
              crossAxisCount = 6;
            } else if (constraints.maxWidth >= 700) {
              crossAxisCount = 5;
            } else {
              crossAxisCount = 4;
            }

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WelcomeCard(),
                    const SizedBox(height: 22),
                    _buildSectionHeader(),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isGridView
                          ? GridView.builder(
                              key: const ValueKey('grid'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: menus.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisExtent: 122,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 8,
                                  ),
                              itemBuilder: (context, index) {
                                final MenuData menu = menus[index];

                                return MenuCard(
                                  menu: menu,
                                  onTap: () => _openMenu(context, menu),
                                );
                              },
                            )
                          : ListView.separated(
                              key: const ValueKey('list'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: menus.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final MenuData menu = menus[index];

                                return MenuListTile(
                                  menu: menu,
                                  onTap: () => _openMenu(context, menu),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      titleSpacing: 16,
      title: Row(
        children: [
          _AppLogo(),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I-PAR Mobile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sistem Pengawasan Pariwisata',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _AppBarAction(
          tooltip: 'Notifikasi',
          icon: Icons.notifications_none_rounded,
          onPressed: () => _showNotification(context),
        ),
        _AppBarAction(
          tooltip: 'Pengaturan',
          icon: Icons.account_circle_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // Menu Utama Section
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Utama',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pilih layanan yang ingin digunakan',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _toggleView,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  key: ValueKey(_isGridView),
                  color: AppTheme.textMuted,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 23),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: AppTheme.textColor(context)),
        ),
      ),
    );
  }
}
