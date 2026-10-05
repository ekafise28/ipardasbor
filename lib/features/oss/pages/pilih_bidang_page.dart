import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/constants/bidang_usaha_constants.dart';

import '../oss_proyek_page.dart';

/// Tampilan visual satu bidang usaha (ikon dan warna kartu).
typedef _Tampilan = ({IconData icon, Color warna});

/// Pilih jenis usaha pariwisata sebelum masuk ke daftar proyek OSS.
///
/// Slug dan nama bidang berasal dari [BidangUsahaOpsi.daftar] (harus sama
/// dengan key di config/bidang_usaha_pariwisata.php). Di sini hanya ikon
/// dan warna yang didefinisikan, di-key dengan slug.
class PilihBidangPage extends StatelessWidget {
  const PilihBidangPage({super.key});

  /// Dipakai kalau ada bidang baru di [BidangUsahaOpsi.daftar] yang belum
  /// didaftarkan di [_tampilan].
  static const _Tampilan _fallback = (
    icon: Icons.business_rounded,
    warna: AppTheme.primaryColor,
  );

  static const Map<String, _Tampilan> _tampilan = <String, _Tampilan>{
    'transportasi-wisata': (
      icon: Icons.directions_bus_rounded,
      warna: Color(0xFF1E7BFF),
    ),
    'akomodasi': (
      icon: Icons.apartment_rounded,
      warna: Color(0xFF0FA3B8),
    ),
    'makanan-minuman': (
      icon: Icons.restaurant_rounded,
      warna: Color(0xFFF97316),
    ),
    'kawasan-pariwisata': (
      icon: Icons.map_outlined,
      warna: Color(0xFF16A34A),
    ),
    'konsultan-pariwisata': (
      icon: Icons.work_outline_rounded,
      warna: Color(0xFF8B3CF0),
    ),
    'perjalanan-wisata': (
      icon: Icons.flight_rounded,
      warna: Color(0xFFE11D48),
    ),
    'informasi-pariwisata': (
      icon: Icons.info_outline_rounded,
      warna: Color(0xFF0E94B0),
    ),
    'pramuwisata': (
      icon: Icons.person_outline_rounded,
      warna: Color(0xFF4F46E5),
    ),
    'mice-event': (
      icon: Icons.event_rounded,
      warna: Color(0xFFD08A00),
    ),
    'hiburan-rekreasi': (
      icon: Icons.sports_esports_rounded,
      warna: Color(0xFFDB2777),
    ),
    'daya-tarik-wisata': (
      icon: Icons.photo_camera_outlined,
      warna: Color(0xFF0284C7),
    ),
    'wisata-tirta': (
      icon: Icons.water_drop_outlined,
      warna: Color(0xFF0D9488),
    ),
    'spa': (
      icon: Icons.spa_outlined,
      warna: Color(0xFF9333EA),
    ),
  };

  void _buka(BuildContext context, BidangUsahaOpsi b) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OssProyekPage(bidang: b.slug, namaBidang: b.nama),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<BidangUsahaOpsi> daftar = BidangUsahaOpsi.daftar;

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
        itemCount: daftar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final BidangUsahaOpsi b = daftar[i];
          final _Tampilan t = _tampilan[b.slug] ?? _fallback;
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
                        color: t.warna,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(t.icon, color: Colors.white, size: 25),
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
                    Icon(Icons.chevron_right_rounded, color: t.warna),
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