import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/bidang_usaha_constants.dart';
import '../models/riwayat_item.dart';

/// Kartu satu item riwayat pengawasan (OSS / Non-OSS / OTA).
///
/// Anatomi sama dengan kartu OSS dan OTA: strip status di kiri, judul +
/// chip status, baris chip meta, baris info berikon, lalu tombol detail.
class RiwayatCard extends StatelessWidget {
  const RiwayatCard({super.key, required this.item, required this.onTap});

  final RiwayatItem item;
  final VoidCallback onTap;

  /// Warna strip: merah > hijau > kuning.
  Color get _warnaStrip {
    if (item.ossTidakValid) return AppTheme.danger;
    return item.selesai ? AppTheme.success : AppTheme.warning;
  }

  Color _warnaNib(BuildContext context) {
    switch (item.identitas.memilikiNib) {
      case 'YA':
        return AppTheme.success;
      case 'TIDAK TAHU':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary(context); // lihat catatan di bawah
    }
  }

  bool get _terdaftarOta =>
      (item.identitas.terdaftarOta ?? '').toUpperCase() == 'YA';

  @override
  Widget build(BuildContext context) {
    final String? bidang = BidangUsahaOpsi.namaDari(item.bidangUsaha);
    final DateTime? tgl = item.tanggal?.toLocal();

    return StripCard(
      stripColor: _warnaStrip,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.namaUsaha,
            statusLabel: item.selesai ? 'Selesai' : 'Draft',
            statusColor: item.selesai ? AppTheme.success : AppTheme.warning,
            statusIcon: item.selesai
                ? Icons.check_circle_rounded
                : Icons.edit_note_rounded,
          ),
          const SizedBox(height: 8),

          // Chip meta
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              TintChip(
                label: item.jenis,
                color: AppTheme.warnaJenis(item.jenis),
              ),
              if (bidang != null)
                TintChip(label: bidang, color: AppTheme.textSecondary(context)),
              TintChip(
                // BARU
                label: item.identitas.labelNib,
                color: _warnaNib(context),
              ),
              if (_terdaftarOta) // BARU
                const TintChip(
                  label: 'Terdaftar OTA',
                  color: AppTheme.primaryColor,
                ),
              if (item.ossTidakValid)
                const TintChip(
                  label: 'Tidak valid',
                  color: AppTheme.danger,
                  icon: Icons.warning_amber_rounded,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Identitas legalitas
          KodeBlock(
            nib: item.identitas.nib ?? '',
            nku: item.identitas.nku ?? '',
          ),
          const SizedBox(height: 10),

          // Info berikon
          ListInfoRow(
            icon: Icons.location_on_outlined,
            text: item.lokasi.gabungan,
            maxLines: 2,
          ),
          ListInfoRow(icon: Icons.badge_outlined, text: item.petugas),
          if (tgl != null)
            ListInfoRow(
              icon: Icons.event_outlined,
              text: formatTanggalJam(tgl)!,
            ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Lihat Detail'),
            ),
          ),
        ],
      ),
    );
  }
}
