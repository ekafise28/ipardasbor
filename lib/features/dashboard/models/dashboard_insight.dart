import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/format_number.dart';

import 'dashboard_data.dart';

/// Satu temuan singkat yang dihitung otomatis dari data dashboard.
class DashboardInsight {
  const DashboardInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

/// Menghitung sorotan dari data yang sudah ada di memori (tanpa API baru).
/// Setiap sorotan hanya muncul kalau datanya memang tersedia.
List<DashboardInsight> buildDashboardInsights(DashboardData data) {
  final List<DashboardInsight> result = [];
  final int total = data.summary.total;

  // 1. Kabupaten/kota dengan pengawasan terbanyak.
  Map<String, dynamic>? topRow;
  int topTotal = 0;
  for (final Map<String, dynamic> row in data.districtRecap) {
    final int value = _toInt(row['total']);
    if (value > topTotal) {
      topTotal = value;
      topRow = row;
    }
  }

  if (topRow != null && topTotal > 0) {
    final String name = (topRow['nama_kabupaten'] ?? '').toString().trim();
    final String share = total > 0
        ? ' (${_percent(topTotal, total)}% dari total)'
        : '';

    result.add(
      DashboardInsight(
        icon: Icons.emoji_events_outlined,
        color: AppTheme.categoryOss,
        title: 'Pengawasan terbanyak',
        body:
            '${name.isEmpty ? 'Tidak diketahui' : name} - '
            '${formatNumber(topTotal)} usaha$share',
      ),
    );
  }

  // 2. Kepemilikan NIB dan 3. Pendaftaran OTA, dijumlahkan dari rekap.
  int nibYa = 0;
  int nibTidak = 0;
  int nibTidakTahu = 0;
  int otaYa = 0;
  int otaTidak = 0;

  for (final Map<String, dynamic> row in data.districtRecap) {
    nibYa += _toInt(row['nib_ya']);
    nibTidak += _toInt(row['nib_tidak']);
    nibTidakTahu += _toInt(row['nib_tidak_tahu']);
    otaYa += _toInt(row['ota_ya']);
    otaTidak += _toInt(row['ota_tidak']);
  }

  final int nibTotal = nibYa + nibTidak + nibTidakTahu;
  if (nibTotal > 0 && nibTidak > 0) {
    result.add(
      DashboardInsight(
        icon: Icons.badge_outlined,
        color: AppTheme.warning,
        title: 'Belum memiliki NIB',
        body:
            '${_percent(nibTidak, nibTotal)}% usaha '
            '(${formatNumber(nibTidak)} dari ${formatNumber(nibTotal)}) '
            'tercatat tidak memiliki NIB',
      ),
    );
  }

  final int otaTotal = otaYa + otaTidak;
  if (otaTotal > 0 && otaYa > 0) {
    result.add(
      DashboardInsight(
        icon: Icons.travel_explore_rounded,
        color: AppTheme.categoryOta,
        title: 'Terdaftar di platform OTA',
        body:
            '${_percent(otaYa, otaTotal)}% usaha '
            '(${formatNumber(otaYa)} dari ${formatNumber(otaTotal)}) '
            'terdaftar di platform OTA',
      ),
    );
  }

  // 4. Data yang masih draft.
  if (data.summary.draft > 0) {
    result.add(
      DashboardInsight(
        icon: Icons.edit_note_rounded,
        color: AppTheme.warning,
        title: 'Masih draft',
        body:
            '${formatNumber(data.summary.draft)} data belum diselesaikan '
            '(${data.summary.draftPercentage.toStringAsFixed(1)}% dari total)',
      ),
    );
  }

  return result;
}

String _percent(int part, int whole) {
  if (whole <= 0) return '0.0';
  return (part / whole * 100).toStringAsFixed(1);
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}