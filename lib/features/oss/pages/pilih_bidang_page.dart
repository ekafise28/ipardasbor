import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

import '../oss_proyek_page.dart';

class _Bidang {
  const _Bidang(this.slug, this.nama, this.icon, this.warna);

  final String slug;
  final String nama;
  final IconData icon;
  final Color warna;
}

/// Pilih jenis usaha pariwisata sebelum masuk ke daftar proyek OSS.
/// Slug harus sama dengan key di config/bidang_usaha_pariwisata.php.
class PilihBidangPage extends StatelessWidget {
  const PilihBidangPage({super.key});

  static const List<_Bidang> _daftar = <_Bidang>[
    _Bidang('transportasi-wisata', 'Jasa Transportasi Wisata',
        Icons.directions_bus_rounded, Color(0xFF1E7BFF)),
    _Bidang('akomodasi', 'Penyediaan Akomodasi', Icons.apartment_rounded,
        Color(0xFF0FA3B8)),
    _Bidang('makanan-minuman', 'Jasa Makanan dan Minuman',
        Icons.restaurant_rounded, Color(0xFFF97316)),
    _Bidang('kawasan-pariwisata', 'Kawasan Pariwisata', Icons.map_outlined,
        Color(0xFF16A34A)),
    _Bidang('konsultan-pariwisata', 'Jasa Konsultan Pariwisata',
        Icons.work_outline_rounded, Color(0xFF8B3CF0)),
    _Bidang('perjalanan-wisata', 'Jasa Perjalanan Wisata',
        Icons.flight_rounded, Color(0xFFE11D48)),
    _Bidang('informasi-pariwisata', 'Jasa Informasi Pariwisata',
        Icons.info_outline_rounded, Color(0xFF0E94B0)),
    _Bidang('pramuwisata', 'Jasa Pramuwisata', Icons.person_outline_rounded,
        Color(0xFF4F46E5)),
    _Bidang('mice-event', 'Penyelenggara MICE dan Event',
        Icons.event_rounded, Color(0xFFD08A00)),
    _Bidang('hiburan-rekreasi', 'Penyelenggaraan Kegiatan Hiburan dan Rekreasi',
        Icons.sports_esports_rounded, Color(0xFFDB2777)),
    _Bidang('daya-tarik-wisata', 'Daya Tarik Wisata',
        Icons.photo_camera_outlined, Color(0xFF0284C7)),
    _Bidang('wisata-tirta', 'Wisata Tirta', Icons.water_drop_outlined,
        Color(0xFF0D9488)),
    _Bidang('spa', 'SPA', Icons.spa_outlined, Color(0xFF9333EA)),
  ];

  void _buka(BuildContext context, _Bidang b) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OssProyekPage(bidang: b.slug, namaBidang: b.nama),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Validasi OSS',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text('Pilih jenis usaha yang akan diverifikasi',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _daftar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final _Bidang b = _daftar[i];
          return Material(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _buka(context, b),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: b.warna,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(b.icon, color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.nama,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buka menu verifikasi',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: b.warna),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}