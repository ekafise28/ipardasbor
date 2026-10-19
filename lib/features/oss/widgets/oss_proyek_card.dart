import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../../../core/network/network_status.dart';

import '../../../app/app_theme.dart';
import '../models/oss_proyek_item.dart';

/// Kartu satu usaha pada daftar verifikasi OSS.
///
/// - Strip warna di sisi kiri + satu chip status (Belum / Terverifikasi /
///   Tidak valid) supaya status terbaca sekilas saat scroll.
/// - Seluruh kartu bisa disentuh: belum diverifikasi -> Verifikasi,
///   sudah diverifikasi -> Detail.
/// - NIB dan NKU punya tombol salin.
class OssProyekCard extends StatelessWidget {
  const OssProyekCard({
    super.key,
    required this.item,
    required this.onVerifikasi,
    required this.onDetail,
    this.highlight = false,
  });

  final OssProyekItem item;

  /// True sebentar setelah kartu ini baru selesai diverifikasi: latar kartu
  /// diwarnai tipis dengan warna status lalu kembali normal.
  final bool highlight;
  final VoidCallback onVerifikasi;
  final VoidCallback onDetail;

  _StatusUi get _status {
    if (item.tidakValid) {
      return const _StatusUi(
        label: 'Tidak valid',
        color: AppTheme.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (item.sudahDiverifikasi) {
      return const _StatusUi(
        label: 'Terverifikasi',
        color: AppTheme.success,
        icon: Icons.check_circle_rounded,
      );
    }
    return const _StatusUi(
      label: 'Belum diverifikasi',
      color: AppTheme.warning,
      icon: Icons.schedule_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _StatusUi status = _status;

    final String modalRisiko = <String?>[
      item.statusPenanamanModal,
      item.uraianRisiko,
    ].whereType<String>().join(' · ');

    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.instance,
      builder: (context, offline, _) {
        // Aksi dihitung sekali di sini, dipakai kartu dan tombolnya.
        final VoidCallback? aksiDetail = item.pengawasanId == null
            ? null
            : onDetail;
        final VoidCallback? aksiVerifikasi = offline ? null : onVerifikasi;

        return StripCard(
          stripColor: status.color,
          onTap: item.sudahDiverifikasi ? aksiDetail : aksiVerifikasi,
          background: highlight
              ? Color.alphaBlend(
                  status.color.withValues(alpha: 0.12),
                  AppTheme.surface(context),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CardTitleRow(
                title: item.namaPerusahaan,
                statusLabel: status.label,
                statusColor: status.color,
                statusIcon: status.icon,
              ),
              const SizedBox(height: 10),
              KodeBlock(nib: item.nib, nku: item.nku),
              const SizedBox(height: 10),
              if (modalRisiko.isNotEmpty)
                ListInfoRow(icon: Icons.shield_outlined, text: modalRisiko),
              ListInfoRow(
                icon: Icons.location_on_outlined,
                text: item.lokasiRingkas,
                maxLines: 2,
              ),
              if (item.alamat.isNotEmpty)
                ListInfoRow(
                  icon: Icons.home_work_outlined,
                  text: item.alamat,
                  maxLines: 2,
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: item.sudahDiverifikasi
                    ? OutlinedButton.icon(
                        onPressed: aksiDetail,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Lihat Detail'),
                      )
                    : FilledButton.icon(
                        onPressed: aksiVerifikasi,
                        icon: Icon(
                          offline
                              ? Icons.cloud_off_rounded
                              : Icons.verified_user_outlined,
                          size: 18,
                        ),
                        label: Text(offline ? 'Perlu koneksi' : 'Verifikasi'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusUi {
  const _StatusUi({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}