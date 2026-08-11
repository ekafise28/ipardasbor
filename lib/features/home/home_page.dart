import 'package:flutter/material.dart';

import '../dashboard/dashboard_page.dart';
import '../non_oss/non_oss_form_page.dart';
import 'models/menu_data.dart';
import 'pages/feature_placeholder_page.dart';
import 'widgets/menu_card.dart';
import 'widgets/welcome_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<MenuData> menus = [
    MenuData(
      title: 'Dashboard',
      description: 'Ringkasan statistik pengawasan',
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    MenuData(
      title: 'Pengawasan OSS',
      description: 'Verifikasi proyek dan usaha OSS',
      icon: Icons.fact_check_outlined,
      color: Color(0xFF1565C0),
      backgroundColor: Color(0xFFE8F1FD),
    ),
    MenuData(
      title: 'Pengawasan Non-OSS',
      description: 'Pencatatan usaha di luar OSS',
      icon: Icons.domain_add_outlined,
      color: Color(0xFF00897B),
      backgroundColor: Color(0xFFE2F5F1),
    ),
    MenuData(
      title: 'Pengawasan OTA',
      description: 'Verifikasi usaha dari platform OTA',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFFD84315),
      backgroundColor: Color(0xFFFBE9E7),
    ),
    MenuData(
      title: 'Riwayat',
      description: 'Data pengawasan yang telah dilakukan',
      icon: Icons.history_rounded,
      color: Color(0xFFEF6C00),
      backgroundColor: Color(0xFFFFF1E3),
    ),
    MenuData(
      title: 'Sinkronisasi',
      description: 'Perbarui dan kirim data aplikasi',
      icon: Icons.sync_rounded,
      color: Color(0xFF0277BD),
      backgroundColor: Color(0xFFE1F5FE),
    ),
    MenuData(
      title: 'Profil Petugas',
      description: 'Informasi akun dan profil petugas',
      icon: Icons.account_circle_outlined,
      color: Color(0xFF455A64),
      backgroundColor: Color(0xFFECEFF1),
    ),
  ];

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

      default:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeaturePlaceholderPage(menu: menu),
          ),
        );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_none_rounded, color: Colors.white),
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
              color: const Color(0xFF1565C0),
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WelcomeCard(),
                    const SizedBox(height: 22),
                    _buildSectionHeader(),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menus.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
      title: const Row(
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
                    color: Color(0xFF152238),
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
                    color: Color(0xFF7A879A),
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
        PopupMenuButton<String>(
          tooltip: 'Menu akun',
          position: PopupMenuPosition.under,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              size: 21,
              color: Color(0xFF334155),
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              _logout(context);
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD32F2F),
                      size: 21,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Utama',
                style: TextStyle(
                  color: Color(0xFF17243A),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pilih layanan yang ingin digunakan',
                style: TextStyle(color: Color(0xFF748197), fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(Icons.grid_view_rounded, color: Color(0xFFA1ACBC), size: 21),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.20),
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
            color: const Color(0xFFF0F4F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: const Color(0xFF334155)),
        ),
      ),
    );
  }
}
