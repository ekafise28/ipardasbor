import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/bidang_usaha_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    final String? bidang = BidangUsahaOpsi.namaDari(item.bidangUsaha);
    final String? nib = (item.identitas.nib ?? '').trim().isEmpty
        ? null
        : item.identitas.nib;
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
                TintChip(
                  label: bidang,
                  color: AppTheme.textSecondary(context),
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
          _IdentitasBlock(ringkasan: item.identitas.ringkasan, nib: nib),
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

/// Blok berlatar muted: ringkasan status NIB/OTA, plus NIB bila ada.
class _IdentitasBlock extends StatelessWidget {
  const _IdentitasBlock({required this.ringkasan, this.nib});

  final String ringkasan;
  final String? nib;

  @override
  Widget build(BuildContext context) {
    return MutedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ringkasan,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          if (nib != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'NIB $nib',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}