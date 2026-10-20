import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// Kartu ringkasan di puncak halaman Sinkronisasi: jumlah data yang siap
/// dikirim dan jumlah draft yang belum lengkap.
///
/// Tombol "Sinkronkan Semua" tidak lagi di sini; letaknya di
/// [SyncBottomBar] supaya selalu terjangkau saat daftar panjang.
class SyncSummaryCard extends StatelessWidget {
  const SyncSummaryCard({
    super.key,
    required this.isLoading,
    required this.waitingCount,
    required this.draftCount,
  });

  final bool isLoading;
  final int waitingCount;

  /// Draft TIDAK ikut diproses tombol "Sinkronkan Semua", jadi dihitung
  /// terpisah supaya petugas tahu kenapa jumlah yang terkirim berbeda dari
  /// total data di perangkat.
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    final int total = waitingCount + draftCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1218273D),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Ringkasan Antrean',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLoading
                          ? 'Memuat data...'
                          : '$waitingCount laporan siap dikirim, '
                                '$draftCount formulir belum lengkap.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.tintBackground(
                      context,
                      AppTheme.primaryColor,
                      AppTheme.menuDashboardBg,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total Berkas',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // IntrinsicHeight wajib: Row dengan stretch di dalam Column yang
          // tingginya tak terbatas (isi SingleChildScrollView) akan
          // mendapat constraint tinggi tak hingga dan merusak layout.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _SummaryBox(
                    title: 'Siap Dikirim',
                    icon: Icons.check_circle_outline_rounded,
                    count: isLoading ? null : waitingCount,
                    unit: 'Data Valid',
                    description: 'Tersimpan aman di penyimpanan lokal',
                    color: AppTheme.primaryColor,
                    lightBackground: AppTheme.menuDashboardBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryBox(
                    title: 'Belum Lengkap',
                    icon: Icons.edit_note_rounded,
                    count: isLoading ? null : draftCount,
                    unit: 'Draft Terbuka',
                    description: 'Perlu dilengkapi sebelum sinkronisasi',
                    color: AppTheme.warning,
                    lightBackground: AppTheme.warningBackground,
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

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.title,
    required this.icon,
    required this.count,
    required this.unit,
    required this.description,
    required this.color,
    required this.lightBackground,
  });

  final String title;
  final IconData icon;

  /// null = masih memuat.
  final int? count;
  final String unit;
  final String description;
  final Color color;
  final Color lightBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.tintBackground(context, color, lightBackground),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                count?.toString() ?? '-',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}