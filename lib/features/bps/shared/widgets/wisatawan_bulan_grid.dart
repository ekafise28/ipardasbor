import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart'
    show bulanSingkat, formatNumber, formatRingkas;

/// Grid 12 bulan (4 kolom x 3 baris) berisi jumlah wisatawan. [bulan] harus
/// 12 elemen; null atau 0 tampil "-". Warna sel mengikuti besarnya nilai
/// dibanding bulan tertinggi pada kartu yang sama.
class WisatawanBulanGrid extends StatelessWidget {
  const WisatawanBulanGrid({super.key, required this.bulan});

  final List<int?> bulan;

  @override
  Widget build(BuildContext context) {
    int puncak = 0;
    for (final int? v in bulan) {
      if (v != null && v > puncak) puncak = v;
    }

    return Column(
      children: <Widget>[
        for (int baris = 0; baris < 3; baris++) ...<Widget>[
          if (baris > 0) const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (int k = 0; k < 4; k++) ...<Widget>[
                if (k > 0) const SizedBox(width: 6),
                Expanded(
                  child: _SelBulan(
                    nama: bulanSingkat[baris * 4 + k],
                    nilai: bulan[baris * 4 + k],
                    puncak: puncak,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _SelBulan extends StatelessWidget {
  const _SelBulan({
    required this.nama,
    required this.nilai,
    required this.puncak,
  });

  final String nama;
  final int? nilai;
  final int puncak;

  @override
  Widget build(BuildContext context) {
    final int? n = nilai;
    final bool kosong = n == null || n == 0;
    final double skala = (kosong || puncak == 0) ? 0 : n / puncak;
    final String lengkap = kosong ? 'belum ada data' : formatNumber(n);

    return Semantics(
      label: '$nama: $lengkap',
      excludeSemantics: true,
      child: Tooltip(
        message: '$nama: $lengkap',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: kosong
                ? AppTheme.surfaceMuted(context)
                : AppTheme.primaryColor.withValues(alpha: 0.06 + 0.24 * skala),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kosong
                  ? AppTheme.border(context)
                  : AppTheme.primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                nama,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kosong ? '-' : formatRingkas(n.toDouble()),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: kosong
                      ? AppTheme.textMuted
                      : AppTheme.textColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}