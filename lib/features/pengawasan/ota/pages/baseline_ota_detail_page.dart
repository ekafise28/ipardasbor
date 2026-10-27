import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/utils/ui_actions.dart';
import 'package:ipardasbor/shared/widgets/app_banner.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../../../../app/app_theme.dart';
import '../models/baseline_ota_item.dart';
import '../widgets/baseline_ota_card.dart';
import '../../../../core/network/network_status.dart';

/// Pilihan verifikasi yang dikembalikan halaman detail ke halaman daftar.
enum BaselineOtaAksi { adaNib, tidakAda, tidakTahu }

class BaselineOtaDetailPage extends StatelessWidget {
  const BaselineOtaDetailPage({super.key, required this.item});

  final BaselineOtaItem item;

  String? get _urlMaps {
    if ((item.urlMaps ?? '').trim().isNotEmpty) return item.urlMaps;
    return mapsUrl(item.latitude, item.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final bool adaNama = (item.namaListing ?? '').trim().isNotEmpty;
    final bool adaAlamat = (item.alamat ?? '').trim().isNotEmpty;
    final BaselineOtaVerifikasi? v = item.verifikasiAktif;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Listing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Header: nama, chip platform/status/jarak, dan alamat.
          DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adaNama ? item.namaListing! : '(Tanpa nama listing)',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OtaPlatformChip(platform: item.platformOta),
                    OtaStatusBadge(sudahDiverifikasi: item.sudahDiverifikasi),
                    if (item.jarakKm != null)
                      DistanceBadge(km: item.jarakKm!)
                    else if (item.latitude == null || item.longitude == null)
                      const Text(
                        'Koordinat tidak tersedia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD08A00),
                        ),
                      ),
                  ],
                ),
                if (adaAlamat) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListInfoRow(
                          icon: Icons.location_on_outlined,
                          text: item.alamat!,
                          maxLines: 3,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 17,
                          tooltip: 'Salin alamat',
                          color: AppTheme.textSecondary(context),
                          onPressed: () =>
                              salinKeClipboard(context, item.alamat!, 'Alamat'),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Hasil verifikasi naik ke atas: ini info terpenting untuk listing
          // yang sudah selesai.
          if (item.sudahDiverifikasi) ...[
            const SizedBox(height: 12),
            DetailCard(
              icon: Icons.fact_check_outlined,
              title: 'Hasil Verifikasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OtaSudahDiverifikasiBox(verifikasi: v),
                  const SizedBox(height: 10),
                  BarisTile(baris: Baris('NIB', v?.nib, salin: true)),
                  BarisTile(
                    baris: Baris('ID Proyek', v?.idProyek, salin: true),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          SectionCard(
            icon: Icons.place_outlined,
            title: 'Lokasi',
            rows: <Baris>[
              Baris('Kelurahan/Desa', item.kelurahan),
              Baris('Kecamatan', item.kecamatan),
              Baris('Kabupaten/Kota', item.kabupaten),
              Baris.koordinat(item.latitude, item.longitude),
            ],
          ),
          const SizedBox(height: 12),

          SectionCard(
            icon: Icons.travel_explore_outlined,
            title: 'Sumber Data',
            rows: <Baris>[
              Baris('Tanggal scraping', formatTanggal(item.scrapedAt)),
              Baris('ID listing', '#${item.id}'),
            ],
            footer: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (item.sourceUrl ?? '').trim().isNotEmpty
                        ? () => bukaTautan(context, item.sourceUrl)
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text(
                      (item.sourceUrl ?? '').trim().isNotEmpty
                          ? 'Listing OTA'
                          : 'Link tidak ada',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _urlMaps != null
                        ? () => bukaTautan(context, _urlMaps)
                        : null,
                    icon: const Icon(Icons.map_rounded, size: 17),
                    label: Text(
                      _urlMaps != null ? 'Buka Maps' : 'Koordinat kosong',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Aksi verifikasi menempel di bawah layar, hanya kalau belum diverifikasi.
      bottomNavigationBar: item.sudahDiverifikasi
          ? null
          : ValueListenableBuilder<bool>(
              valueListenable: NetworkStatus.instance,
              builder: (context, offline, _) {
                VoidCallback? pilih(BaselineOtaAksi aksi) =>
                    offline ? null : () => Navigator.pop(context, aksi);
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    border: Border(
                      top: BorderSide(color: AppTheme.border(context)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (offline)
                            const OfflineNotice(
                              pesan: 'Perlu koneksi internet untuk verifikasi.',
                            ),
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: OtaVerifButton(
                                  label: 'Ada NIB',
                                  color: AppTheme.primaryColor,
                                  filled: true,
                                  onTap: pilih(BaselineOtaAksi.adaNib),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 4,
                                child: OtaVerifButton(
                                  label: 'Tidak Ada',
                                  color: Colors.red.shade700,
                                  onTap: pilih(BaselineOtaAksi.tidakAda),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 4,
                                child: OtaVerifButton(
                                  label: 'Tidak Tahu',
                                  color: Colors.blueGrey.shade600,
                                  onTap: pilih(BaselineOtaAksi.tidakTahu),
                                ),
                              ),
                            ],
                          ),
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
