import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../models/baseline_ota_item.dart';

/// Satu kartu listing baseline OTA, padanan satu baris tabel di
/// oss_baseline_ota.index (web). Tombol verifikasi disembunyikan dan
/// diganti kotak info hijau kalau [item.sudahDiverifikasi].
class BaselineOtaCard extends StatelessWidget {
  const BaselineOtaCard({
    super.key,
    required this.item,
    required this.onAdaNib,
    required this.onTidakAda,
    required this.onTidakTahu,
  });

  final BaselineOtaItem item;
  final VoidCallback onAdaNib;
  final VoidCallback onTidakAda;
  final VoidCallback onTidakTahu;

  Future<void> _buka(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tautan ini.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaListing?.trim().isNotEmpty == true
                          ? item.namaListing!
                          : '(Tanpa nama listing)',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.public, size: 12, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 4),
                        Text(
                          item.platformOta ?? '-',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context)),
                        ),
                        const SizedBox(width: 6),
                        Text('· ID #${item.id}',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(sudahDiverifikasi: item.sudahDiverifikasi),
            ],
          ),
          const SizedBox(height: 10),
          if ((item.alamat ?? '').trim().isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: item.alamat!),
          _InfoRow(icon: Icons.map_outlined, text: item.wilayahRingkas),
          _InfoRow(
            icon: item.memilikiKoordinat ? Icons.gps_fixed : Icons.gps_off,
            text: item.memilikiKoordinat
                ? 'Lat ${item.latitude}, Lng ${item.longitude}'
                : 'Koordinat belum tersedia',
            color: item.memilikiKoordinat ? null : const Color(0xFFD08A00),
          ),
          if (item.scrapedAt != null)
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: 'Scraping: ${item.scrapedAt!.day.toString().padLeft(2, '0')}-'
                  '${item.scrapedAt!.month.toString().padLeft(2, '0')}-'
                  '${item.scrapedAt!.year}',
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LinkButton(
                icon: Icons.open_in_new_rounded,
                enabled: (item.sourceUrl ?? '').trim().isNotEmpty,
                tooltip: 'Buka listing OTA',
                onTap: () => _buka(context, item.sourceUrl),
              ),
              const SizedBox(width: 8),
              _LinkButton(
                icon: Icons.map_rounded,
                enabled: (item.urlMaps ?? '').trim().isNotEmpty,
                tooltip: 'Buka di Maps',
                onTap: () => _buka(context, item.urlMaps),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (item.sudahDiverifikasi)
            _SudahDiverifikasiBox(verifikasi: item.verifikasiAktif)
          else
            Row(
              children: [
                Expanded(
                  child: _VerifButton(
                    label: 'Ada NIB',
                    color: const Color(0xFFB8860B),
                    onTap: onAdaNib,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _VerifButton(
                    label: 'Tidak Ada',
                    color: Colors.red.shade700,
                    onTap: onTidakAda,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _VerifButton(
                    label: 'Tidak Tahu',
                    color: Colors.blueGrey.shade600,
                    onTap: onTidakTahu,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color ?? AppTheme.textSecondary(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: color ?? AppTheme.textSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border(context)),
            borderRadius: BorderRadius.circular(10),
            color: enabled ? null : AppTheme.surfaceMuted(context),
          ),
          child: Icon(
            icon,
            size: 17,
            color: enabled ? AppTheme.primaryColor : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _VerifButton extends StatelessWidget {
  const _VerifButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.sudahDiverifikasi});
  final bool sudahDiverifikasi;

  @override
  Widget build(BuildContext context) {
    final Color bg = sudahDiverifikasi ? const Color(0xFFDCF6E7) : const Color(0xFFFFF1D6);
    final Color fg = sudahDiverifikasi ? const Color(0xFF15803D) : const Color(0xFFA96700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sudahDiverifikasi ? Icons.check_circle : Icons.access_time, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            sudahDiverifikasi ? 'Sudah' : 'Belum',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

class _SudahDiverifikasiBox extends StatelessWidget {
  const _SudahDiverifikasiBox({required this.verifikasi});
  final BaselineOtaVerifikasi? verifikasi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBDE7CD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sudah diverifikasi',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                ),
                if ((verifikasi?.nib ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'NIB: ${verifikasi!.nib}',
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF5B7B68)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}