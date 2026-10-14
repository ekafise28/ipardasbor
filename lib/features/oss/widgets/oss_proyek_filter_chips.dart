import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/widgets/list_filters.dart';

import '../../../app/app_theme.dart';
import '../models/oss_proyek_filter.dart';
import '../models/oss_proyek_page_result.dart';

/// Baris chip filter cepat status verifikasi (Semua / Belum / Terverifikasi /
/// Tidak valid). Pembungkus [StatusFilterBar] dengan opsi khas OSS.
class OssStatusFilterBar extends StatelessWidget {
  const OssStatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.ringkasan,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  /// Hitungan per status; kalau null chip tampil tanpa angka.
  final OssProyekRingkasan? ringkasan;

  @override
  Widget build(BuildContext context) {
    final OssProyekRingkasan? r = ringkasan;

    return StatusFilterBar(
      selected: selected,
      onChanged: onChanged,
      options: <StatusFilterOption>[
        StatusFilterOption(
          value: null,
          label: 'Semua',
          color: AppTheme.primaryColor,
          count: r?.total,
        ),
        StatusFilterOption(
          value: OssProyekOpsi.statusBelum,
          label: 'Belum',
          color: AppTheme.warning,
          count: r?.belum,
        ),
        StatusFilterOption(
          value: OssProyekOpsi.statusSudah,
          label: 'Terverifikasi',
          color: AppTheme.success,
          count: r?.sudah,
        ),
        StatusFilterOption(
          value: OssProyekOpsi.statusTidakValid,
          label: 'Tidak valid',
          color: AppTheme.danger,
          count: r?.tidakValid,
        ),
      ],
    );
  }
}