import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../home/models/menu_data.dart';
import '../home/widgets/menu_list_tile.dart';
import '../industri_pariwisata/industri_pariwisata_page.dart';
import '../okupansi_akomodasi/okupansi_akomodasi_page.dart';
import '../profil_pasar_wisman/profil_pasar_wisman_page.dart';
import '../wisatawan_mancanegara/wisatawan_mancanegara_page.dart';
import 'dashboard_page.dart';
import '../../../shared/widgets/list_parts.dart';

class _HubItem {
  const _HubItem(this.menu, this.builder);

  final MenuData menu;
  final WidgetBuilder builder;
}

class DashboardHubPage extends StatelessWidget {
  const DashboardHubPage({super.key});

  static final List<_HubItem> _items = [
    _HubItem(
      const MenuData(
        title: 'Ringkasan Statistik',
        description: 'Ringkasan statistik pengawasan',
        icon: Icons.bar_chart_rounded,
        color: AppTheme.menuDashboard,
        backgroundColor: AppTheme.menuDashboardBg,
      ),
      (_) => const DashboardPage(),
    ),
    _HubItem(
      const MenuData(
        title: 'Industri Pariwisata',
        description: 'Data usaha & industri pariwisata',
        icon: Icons.apartment_rounded,
        color: AppTheme.menuNonOss,
        backgroundColor: AppTheme.menuNonOssBg,
      ),
      (_) => const IndustriPariwisataPage(),
    ),
    _HubItem(
      const MenuData(
        title: 'Wisatawan Mancanegara',
        description: 'Kunjungan wisman',
        icon: Icons.flight_land_rounded,
        color: AppTheme.menuOta,
        backgroundColor: AppTheme.menuOtaBg,
      ),
      (_) => const WisatawanMancanegaraPage(),
    ),
    _HubItem(
      const MenuData(
        title: 'Profil Pasar Wisatawan Mancanegara',
        description: 'Profil pasar wisatawan mancanegara',
        icon: Icons.pie_chart_rounded,
        color: AppTheme.menuRiwayat,
        backgroundColor: AppTheme.menuRiwayatBg,
      ),
      (_) => const ProfilPasarWismanPage(),
    ),
    _HubItem(
      const MenuData(
        title: 'Okupansi Akomodasi',
        description: 'Tingkat hunian akomodasi',
        icon: Icons.hotel_rounded,
        color: AppTheme.menuSinkronisasi,
        backgroundColor: AppTheme.menuSinkronisasiBg,
      ),
      (_) => const OkupansiAkomodasiPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const TwoLineTitle(
          title: 'Dashboard',
          subtitle: 'Pilih Menu Dashboard',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Card disusun ke bawah, satu per baris.
            for (int i = 0; i < _items.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == _items.length - 1 ? 0 : 10,
                ),
                child: MenuListTile(
                  menu: _items[i].menu,
                  badgeCount: 0,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: _items[i].builder)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
