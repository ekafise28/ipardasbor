import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/riwayat_item.dart';

/// Kartu ringkasan satu item riwayat pengawasan.
///
/// Menampilkan: jenis (badge), nama usaha, identitas (NIB/OTA), lokasi,
/// petugas, tanggal, dan status (badge) + tombol Detail.
class RiwayatCard extends StatelessWidget {
  const RiwayatCard({super.key, required this.item, required this.onTap});

  final RiwayatItem item;
  final VoidCallback onTap;

  Color _warnaJenis(BuildContext context) {
    switch (item.jenis.toUpperCase()) {
      case 'OSS':
        return AppTheme.menuOss;
      case 'OTA':
        return AppTheme.menuOta;
      case 'NON OSS':
      default:
        return AppTheme.menuNonOss;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color warnaJenis = _warnaJenis(context);
    final String tanggalLabel = item.tanggal != null
        ? _formatTanggal(item.tanggal!)
        : '-';
    final String jamLabel = item.tanggal != null
        ? _formatJam(item.tanggal!)
        : '';

    return Card(
      elevation: 0,
      color: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _Badge(text: item.jenis, color: warnaJenis),
                  const SizedBox(width: 8),
                  _StatusBadge(selesai: item.selesai, label: item.status),
                  const Spacer(),
                  if (tanggalLabel != '-')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          tanggalLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        if (jamLabel.isNotEmpty)
                          Text(
                            jamLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.namaUsaha,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.identitas.ringkasan,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              _IconLine(
                icon: Icons.place_outlined,
                text: item.lokasi.gabungan,
                context: context,
              ),
              const SizedBox(height: 4),
              _IconLine(
                icon: Icons.badge_outlined,
                text: item.petugas,
                context: context,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: const Text('Detail'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.menuDashboard,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTanggal(DateTime tanggal) {
    const List<String> bulan = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  static String _formatJam(DateTime tanggal) {
    final String jam = tanggal.hour.toString().padLeft(2, '0');
    final String menit = tanggal.minute.toString().padLeft(2, '0');

    return '$jam:$menit';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.selesai, required this.label});

  final bool selesai;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color warna = selesai ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            selesai ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
            size: 12,
            color: warna,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    required this.text,
    required this.context,
  });

  final IconData icon;
  final String text;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: AppTheme.textSecondary(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}