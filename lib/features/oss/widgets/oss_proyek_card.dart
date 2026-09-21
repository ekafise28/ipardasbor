import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/oss_proyek_item.dart';

/// Kartu satu usaha pada daftar verifikasi OSS.
///
/// Belum diverifikasi -> tombol "Verifikasi".
/// Sudah diverifikasi -> tombol "Detail" (membuka hasil pengawasan).
class OssProyekCard extends StatelessWidget {
  const OssProyekCard({
    super.key,
    required this.item,
    required this.onVerifikasi,
    required this.onDetail,
  });

  final OssProyekItem item;
  final VoidCallback onVerifikasi;
  final VoidCallback onDetail;

  static const Color _hijau = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final String modalRisiko = <String?>[
      item.statusPenanamanModal,
      item.uraianRisiko,
    ].whereType<String>().join(' · ');

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.namaPerusahaan,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if (item.sudahDiverifikasi)
                  const _Chip(
                    text: 'Sudah',
                    color: _hijau,
                    icon: Icons.check_circle_rounded,
                  )
                else
                  const _Chip(
                    text: 'Belum',
                    color: AppTheme.warning,
                    icon: Icons.schedule_rounded,
                  ),
                if (item.tidakValid)
                  const _Chip(
                    text: 'Tidak valid',
                    color: AppTheme.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _Kode(label: 'NIB', value: item.nib),
            const SizedBox(height: 2),
            _Kode(label: 'NKU', value: item.nku),
            const SizedBox(height: 10),
            if (modalRisiko.isNotEmpty)
              _InfoRow(icon: Icons.shield_outlined, text: modalRisiko),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: item.lokasiRingkas,
            ),
            if (item.alamat.isNotEmpty)
              _InfoRow(
                icon: Icons.home_work_outlined,
                text: item.alamat,
                maxLines: 2,
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: item.sudahDiverifikasi
                  ? OutlinedButton.icon(
                      onPressed: item.pengawasanId == null ? null : onDetail,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Detail'),
                    )
                  : FilledButton.icon(
                      onPressed: onVerifikasi,
                      icon: const Icon(Icons.verified_user_outlined, size: 18),
                      label: const Text('Verifikasi'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Kode extends StatelessWidget {
  const _Kode({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${value.isEmpty ? '-' : value}',
      style: TextStyle(
        fontSize: 12,
        color: AppTheme.textSecondary(context),
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary(context),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}