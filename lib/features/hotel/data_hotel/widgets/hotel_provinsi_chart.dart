import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/hotel_page_result.dart';

/// Grafik batang horizontal jumlah hotel per provinsi. Ketuk batang untuk
/// memilih/melepas provinsi (memfilter daftar). Banyak provinsi bisa dipilih.
class HotelProvinsiChart extends StatefulWidget {
  const HotelProvinsiChart({
    super.key,
    required this.data,
    required this.selected,
    required this.onToggle,
    this.onReset,
    this.batasAwal = 8,
  });

  final List<HotelChartPoint> data;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  /// Null = tombol "Hapus pilihan" tidak ditampilkan.
  final VoidCallback? onReset;
  final int batasAwal;

  @override
  State<HotelProvinsiChart> createState() => _HotelProvinsiChartState();
}

class _HotelProvinsiChartState extends State<HotelProvinsiChart> {
  bool _semua = false;

  @override
  Widget build(BuildContext context) {
    final List<HotelChartPoint> data = widget.data;
    final int totalHotel = data.fold(0, (int a, HotelChartPoint e) => a + e.value);
    final int maks = data.isEmpty ? 1 : data.map((HotelChartPoint e) => e.value).reduce(math.max);

    final List<HotelChartPoint> tampil = _semua
        ? data
        : <HotelChartPoint>[
            for (int i = 0; i < data.length; i++)
              if (i < widget.batasAwal || widget.selected.contains(data[i].label)) data[i],
          ];
    final bool bisaLipat = data.length > widget.batasAwal;
    final bool adaPilihan = widget.selected.isNotEmpty;

    return DetailCard(
      icon: Icons.bar_chart_rounded,
      title: 'Hotel per Provinsi',
      count: totalHotel,
      countSuffix: ' hotel',
      child: data.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data hotel.',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Ketuk batang untuk memfilter daftar',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                      if (adaPilihan && widget.onReset != null)
                        TextButton(
                          onPressed: widget.onReset,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Hapus pilihan'),
                        ),
                    ],
                  ),
                ),
                for (final HotelChartPoint p in tampil)
                  _BarRow(
                    key: ValueKey<String>(p.label),
                    label: p.label,
                    value: p.value,
                    fraction: maks == 0 ? 0 : p.value / maks,
                    aktif: widget.selected.contains(p.label),
                    redup: adaPilihan && !widget.selected.contains(p.label),
                    onTap: () => widget.onToggle(p.label),
                  ),
                if (bisaLipat)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _semua = !_semua),
                      icon: Icon(
                        _semua ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _semua
                            ? 'Ringkas'
                            : 'Tampilkan semua (${formatNumber(data.length)} provinsi)',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    required this.aktif,
    required this.redup,
    required this.onTap,
  });

  final String label;
  final int value;
  final double fraction;
  final bool aktif;
  final bool redup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.primaryColor.withValues(alpha: redup ? 0.30 : 1);

    return Semantics(
      button: true,
      selected: aktif,
      label: '$label, ${formatNumber(value)} hotel',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (aktif) ...<Widget>[
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.primaryColor),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: aktif ? FontWeight.w800 : FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatNumber(value),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: aktif ? AppTheme.primaryColor : AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 9,
                  width: double.infinity,
                  color: AppTheme.surfaceMuted(context),
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double f, _) => FractionallySizedBox(
                      widthFactor: value == 0 ? 0 : math.max(f, 0.02),
                      child: Container(color: warna),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}