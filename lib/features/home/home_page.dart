import 'package:flutter/material.dart';
import 'package:ipardasbor/features/non_oss/services/wilayah_akses_service.dart';
import 'package:ipardasbor/features/oss/pages/pilih_bidang_page.dart';
import 'package:ipardasbor/features/ota/pages/baseline_ota_page.dart';
import 'package:ipardasbor/features/notifications/notification_page.dart';
import 'package:ipardasbor/features/notifications/services/notification_service.dart';

import '../../app/app_theme.dart';
import '../dashboard/dashboard_page.dart';

import '../sinkronisasi/sync_page.dart';
import '../riwayat/riwayat_page.dart';

import 'models/menu_data.dart';
import 'pages/feature_placeholder_page.dart';

import '../profile/profile_page.dart';
import '../settings/settings_page.dart';

import 'widgets/menu_card.dart';
import 'widgets/menu_list_tile.dart';
import 'widgets/status_banner.dart';
import 'widgets/welcome_card.dart';

import '../../core/api/api_client.dart';
import '../non_oss/offline/offline_database.dart';
import '../non_oss/services/non_oss_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isGridView = true;

  late final ApiClient _api;
  late final NonOssService _nonOssService;
  final OfflineDatabase _database = OfflineDatabase.instance;

  // Animasi masuk bertahap (kartu sambutan + menu).
  late final AnimationController _entrance;

  ServerConnectionStatus _serverStatus = ServerConnectionStatus.checking;
  int _offlineCount = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WilayahAksesService.instance.refresh(); // tanpa await, berjalan di latar
    _api = ApiClient();
    _nonOssService = NonOssService(_api);

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _refreshSyncStatus();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _api.close();
    super.dispose();
  }

  /// Mengecek status koneksi ke SERVER (ping asli, bukan cuma jaringan
  /// device) dan menghitung seluruh data tersimpan lokal yang belum synced
  /// (draft + pending + failed). Dipanggil saat halaman dibuka, tiap 60
  /// detik, saat pull-to-refresh, dan setelah kembali dari halaman lain
  /// yang mungkin mengubah antrean (mis. Sinkronisasi, form Non-OSS).
  Future<void> _refreshSyncStatus() async {
    final bool online = await _nonOssService.isServerAvailable();
    final int count = await _database.countUnsynced();
    final int unread = await NotificationService.instance.countUnread();

    if (!mounted) return;
    setState(() {
      _serverStatus = online
          ? ServerConnectionStatus.online
          : ServerConnectionStatus.offline;
      _offlineCount = count;
      _unreadNotifications = unread;
    });
  }

  // ---- Definisi menu ----
  static const MenuData _mDashboard = MenuData(
    title: 'Dashboard',
    description: 'Ringkasan statistik pengawasan',
    icon: Icons.bar_chart_rounded,
    color: AppTheme.menuDashboard,
    backgroundColor: AppTheme.menuDashboardBg,
  );

  static const MenuData _mOss = MenuData(
    title: 'Validasi OSS',
    description: 'Verifikasi proyek dan usaha OSS',
    icon: Icons.fact_check_outlined,
    color: AppTheme.menuOss,
    backgroundColor: AppTheme.menuOssBg,
  );

  static const MenuData _mNonOss = MenuData(
    title: 'Pengawasan Non-OSS',
    description: 'Pencatatan usaha di luar OSS',
    icon: Icons.domain_add_outlined,
    color: AppTheme.menuNonOss,
    backgroundColor: AppTheme.menuNonOssBg,
  );

  static const MenuData _mOta = MenuData(
    title: 'Pengawasan OTA',
    description: 'Verifikasi usaha dari platform OTA',
    icon: Icons.travel_explore_rounded,
    color: AppTheme.menuOta,
    backgroundColor: AppTheme.menuOtaBg,
  );

  static const MenuData _mRiwayat = MenuData(
    title: 'Riwayat',
    description: 'Data pengawasan yang telah dilakukan',
    icon: Icons.history_rounded,
    color: AppTheme.menuRiwayat,
    backgroundColor: AppTheme.menuRiwayatBg,
  );

  static const MenuData _mSinkronisasi = MenuData(
    title: 'Sinkronisasi',
    description: 'Perbarui dan kirim data aplikasi',
    icon: Icons.sync_rounded,
    color: AppTheme.menuSinkronisasi,
    backgroundColor: AppTheme.menuSinkronisasiBg,
  );

  static const MenuData _mProfil = MenuData(
    title: 'Profil Petugas',
    description: 'Informasi akun dan profil petugas',
    icon: Icons.account_circle_outlined,
    color: AppTheme.menuProfil,
    backgroundColor: AppTheme.menuProfilBg,
  );

  // 3 + 4 menu: pas mengisi grid 4 kolom tanpa baris yang timpang.
  static const List<_MenuGroup> _groups = [
    _MenuGroup('Pengawasan', [_mOss, _mNonOss, _mOta]),
    _MenuGroup('Data & Akun', [
      _mDashboard,
      _mRiwayat,
      _mSinkronisasi,
      _mProfil,
    ]),
  ];

  /// Angka badge per menu. Saat ini hanya Sinkronisasi (data belum terkirim).
  int _badgeFor(MenuData menu) {
    if (menu.title == 'Sinkronisasi') return _offlineCount;
    return 0;
  }

  // Menu Fitur
  Future<void> _openMenu(BuildContext context, MenuData menu) async {
    switch (menu.title) {
      case 'Dashboard':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const DashboardPage()));
        break;

      case 'Validasi OSS':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PilihBidangPage()),
        );
        break;

      case 'Pengawasan Non-OSS':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PilihBidangPage(tujuan: TujuanBidang.nonOss),
          ),
        );
        break;

      case 'Pengawasan OTA':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BaselineOtaPage()),
        );
        break;

      case 'Profil Petugas':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
        break;

      case 'Riwayat':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RiwayatPage()));
        break;

      case 'Sinkronisasi':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SyncPage()));
        break;

      default:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeaturePlaceholderPage(menu: menu),
          ),
        );
    }

    await _refreshSyncStatus();
  }

  Future<void> _openSync() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const SyncPage()));
    await _refreshSyncStatus();
  }

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationPage()));
    await _refreshSyncStatus();
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
              onRefresh: _refreshSyncStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Staggered(
                      animation: _entrance,
                      index: 0,
                      child: WelcomeCard(
                        serverStatus: _serverStatus,
                        offlineCount: _offlineCount,
                        onTapSyncStatus: _openSync,
                      ),
                    ),
                    StatusBanner(
                      serverStatus: _serverStatus,
                      offlineCount: _offlineCount,
                      onTap: _openSync,
                    ),
                    const SizedBox(height: 22),
                    _buildSectionHeader(),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildGroups(crossAxisCount),
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

  /// Menu dikelompokkan per kategori. Indeks dihitung berurutan supaya
  /// animasi masuk berjalan satu per satu dari atas ke bawah.
  Widget _buildGroups(int crossAxisCount) {
    int index = 1; // 0 dipakai kartu sambutan
    final List<Widget> children = [];

    for (final _MenuGroup group in _groups) {
      final int startIndex = index;

      children.add(
        _Staggered(
          animation: _entrance,
          index: startIndex,
          child: _GroupHeader(title: group.title),
        ),
      );

      if (_isGridView) {
        children.add(
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 122,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              final MenuData menu = group.items[i];
              return _Staggered(
                animation: _entrance,
                index: startIndex + i,
                child: MenuCard(
                  menu: menu,
                  badgeCount: _badgeFor(menu),
                  onTap: () => _openMenu(context, menu),
                ),
              );
            },
          ),
        );
      } else {
        children.add(
          Column(
            children: List.generate(group.items.length, (i) {
              final MenuData menu = group.items[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == group.items.length - 1 ? 0 : 10,
                ),
                child: _Staggered(
                  animation: _entrance,
                  index: startIndex + i,
                  child: MenuListTile(
                    menu: menu,
                    badgeCount: _badgeFor(menu),
                    onTap: () => _openMenu(context, menu),
                  ),
                ),
              );
            }),
          ),
        );
      }

      children.add(const SizedBox(height: 18));
      index += group.items.length;
    }

    return Column(
      key: ValueKey<bool>(_isGridView),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
          badgeCount: _unreadNotifications,
          onPressed: () => _openNotifications(context),
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

// ======================================================================
// Pendukung
// ======================================================================

class _MenuGroup {
  const _MenuGroup(this.title, this.items);

  final String title;
  final List<MenuData> items;
}

/// Judul kecil per kelompok menu: label + garis tipis.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: AppTheme.border(context)),
          ),
        ],
      ),
    );
  }
}

/// Fade + geser sedikit ke atas, tertunda sesuai [index]. Dipakai bersama
/// satu AnimationController supaya semua item bergerak berurutan.
/// Dilewati jika pengguna mematikan animasi di pengaturan perangkat.
class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final double start = (index * 0.07).clamp(0.0, 0.55);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final Animation<double> eased = animation.drive(
      CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );

    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(
          Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero),
        ),
        child: child,
      ),
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
      child: const Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppTheme.textColor(context)),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.surface(context),
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
