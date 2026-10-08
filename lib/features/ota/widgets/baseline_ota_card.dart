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
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tautan ini.')),
        );
      }
    }
  }

  String _tgl(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final Color strip = item.sudahDiverifikasi
        ? const Color(0xFF15803D)
        : const Color(0xFFE0A100);
    final bool adaAlamat = (item.alamat ?? '').trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Stack(
        children: [
          // Strip status di sisi kiri: hijau = terverifikasi, kuning = belum.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 5, color: strip),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.namaListing?.trim().isNotEmpty == true
                            ? item.namaListing!
                            : '(Tanpa nama listing)',
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(sudahDiverifikasi: item.sudahDiverifikasi),
                  ],
                ),
                const SizedBox(height: 8),
                // Baris meta: platform (chip berwarna) + tanggal scraping + ID.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _PlatformChip(platform: item.platformOta),
                    if (item.scrapedAt != null)
                      Text(
                        'Scraping ${_tgl(item.scrapedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    Text(
                      '#${item.id}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (adaAlamat)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: item.alamat!,
                  ),
                _InfoRow(
                  icon: Icons.map_outlined,
                  text: item.wilayahRingkas,
                  redup: adaAlamat,
                ),
                const SizedBox(height: 8),
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
                        flex: 5,
                        child: _VerifButton(
                          label: 'Ada NIB',
                          color: AppTheme.primaryColor,
                          filled: true,
                          onTap: onAdaNib,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: _VerifButton(
                          label: 'Tidak Ada',
                          color: Colors.red.shade700,
                          onTap: onTidakAda,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
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
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.redup = false});
  final IconData icon;
  final String text;

  /// true = baris sekunder, warnanya lebih muted.
  final bool redup;

  @override
  Widget build(BuildContext context) {
    final Color warna = redup
        ? AppTheme.textMuted
        : AppTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: warna),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.3, color: warna),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip platform dengan warna identitas tiap OTA. Platform yang tidak
/// dikenal memakai warna netral.
class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.platform});
  final String? platform;

  Color _warna(BuildContext context) {
    final String p = (platform ?? '').toLowerCase();
    if (p.contains('booking')) return const Color(0xFF003B95);
    if (p.contains('agoda')) return const Color(0xFF5C2D91);
    if (p.contains('traveloka')) return const Color(0xFF0770CD);
    if (p.contains('tiket')) return const Color(0xFF0064D2);
    if (p.contains('airbnb')) return const Color(0xFFE0314B);
    if (p.contains('pegipegi')) return const Color(0xFFE65100);
    return AppTheme.textSecondary(context);
  }

  @override
  Widget build(BuildContext context) {
    final Color warna = _warna(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (platform ?? '-').trim().isEmpty ? '-' : platform!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: warna,
        ),
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
          width: 40,
          height: 40,
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
  const _VerifButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// true = tombol utama (solid), false = tombol sekunder (outline).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
    );
    final textStyle = const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
    );

    return SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: shape,
                textStyle: textStyle,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.55)),
                padding: EdgeInsets.zero,
                shape: shape,
                textStyle: textStyle,
              ),
              child: Text(label),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.sudahDiverifikasi});
  final bool sudahDiverifikasi;

  @override
  Widget build(BuildContext context) {
    final Color bg = sudahDiverifikasi
        ? const Color(0xFFDCF6E7)
        : const Color(0xFFFFF1D6);
    final Color fg = sudahDiverifikasi
        ? const Color(0xFF15803D)
        : const Color(0xFFA96700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sudahDiverifikasi ? Icons.check_circle : Icons.access_time,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            sudahDiverifikasi ? 'Terverifikasi' : 'Belum',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SudahDiverifikasiBox extends StatelessWidget {
  const _SudahDiverifikasiBox({required this.verifikasi});
  final BaselineOtaVerifikasi? verifikasi;

  /// Menerjemahkan nilai status_verifikasi dari backend ke label + warna.
  /// Pemetaan ini berdasarkan asumsi nilainya mengandung kata 'TIDAK TAHU',
  /// 'TIDAK', atau 'NIB'/'ADA'. Sesuaikan kalau nilai aslinya berbeda.
  (String, Color, IconData) _hasil() {
    final String s = (verifikasi?.statusVerifikasi ?? '').toUpperCase();
    final bool punyaNib = (verifikasi?.nib ?? '').trim().isNotEmpty;

    if (s.contains('TIDAK TAHU') || s.contains('TIDAK_TAHU')) {
      return ('Tidak Tahu', Colors.blueGrey.shade600, Icons.help_rounded);
    }
    if (s.contains('TIDAK')) {
      return ('Tidak Ada NIB', Colors.red.shade700, Icons.cancel_rounded);
    }
    if (punyaNib || s.contains('NIB') || s.contains('ADA')) {
      return ('Ada NIB', const Color(0xFF15803D), Icons.check_circle);
    }
    return ('Sudah diverifikasi', const Color(0xFF15803D), Icons.check_circle);
  }

  String? _tanggal() {
    final DateTime? d = verifikasi?.verifiedAt;
    if (d == null) return null;
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (String label, Color warna, IconData ikon) = _hasil();
    final String? tanggal = _tanggal();
    final String? nib = (verifikasi?.nib ?? '').trim().isNotEmpty
        ? verifikasi!.nib
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(ikon, color: warna, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: warna,
                  ),
                ),
                if (nib != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'NIB: $nib',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                if (tanggal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Diverifikasi $tanggal',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary(context),
                      ),
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
