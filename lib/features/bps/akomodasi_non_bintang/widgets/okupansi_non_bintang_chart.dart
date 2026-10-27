import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/hotel/okupansi_hotel/okupansi_hotel_style.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../models/okupansi_non_bintang_data.dart';

/// Warna per tahun (urutan naik). Palet di okupansi_hotel_style.dart
/// bersifat private, jadi enam warna pertamanya disalin di sini.
const List<Color> _warnaTahun = <Color>[
  Color(0xFF1565C0),
  Color(0xFFEF6C00),
  Color(0xFF2E7D32),
  Color(0xFF8E24AA),
  Color(0xFFD32F2F),
  Color(0xFF00ACC1),
];

/// Jumlah provinsi yang tampil sebelum "Tampilkan semua".
const int _batasAwal = 10;

Color _warna(int i) => _warnaTahun[i % _warnaTahun.length];

class OkupansiNonBintangChartCard extends StatefulWidget {
  const OkupansiNonBintangChartCard({super.key, required this.chart});

  final OkupansiNonBintangChart chart;

  @override
  State<OkupansiNonBintangChartCard> createState() =>
      _OkupansiNonBintangChartCardState();
}

class _OkupansiNonBintangChartCardState
    extends State<OkupansiNonBintangChartCard> {
  bool _semua = false;

  @override
  Widget build(BuildContext context) {
    final List<int> tahun = widget.chart.tahun;
    final List<OkupansiNonBintangBaris> baris = widget.chart.baris;
    final List<OkupansiNonBintangBaris> tampil = _semua
        ? baris
        : baris.take(_batasAwal).toList();

    return DetailCard(
      icon: Icons.bar_chart_rounded,
      title: 'Grafik Okupansi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          if (baris.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data okupansi untuk pilihan ini.',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          else ...<Widget>[
            if (tahun.length > 1)
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: <Widget>[
                  for (int i = 0; i < tahun.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _warna(i),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${tahun[i]}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                'Diurutkan dari okupansi tertinggi pada ${tahun.last}.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
            for (final OkupansiNonBintangBaris b in tampil)
              _BarisProvinsi(baris: b, tahun: tahun),
            if (baris.length > _batasAwal)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _semua = !_semua),
                  child: Text(
                    _semua
                        ? 'Tampilkan lebih sedikit'
                        : 'Tampilkan semua (${baris.length} provinsi)',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BarisProvinsi extends StatelessWidget {
  const _BarisProvinsi({required this.baris, required this.tahun});

  final OkupansiNonBintangBaris baris;
  final List<int> tahun;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            baris.provinsi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
          for (int i = 0; i < tahun.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: <Widget>[
                  if (tahun.length > 1)
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${tahun[i]}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _Batang(
                      nilai: i < baris.values.length ? baris.values[i] : null,
                      warna: _warna(i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      fmtPersen(
                        i < baris.values.length ? baris.values[i] : null,
                        desimal: 2,
                      ),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
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

/// Satu batang pada skala 0-100%. Nilai null = lintasan kosong.
class _Batang extends StatelessWidget {
  const _Batang({required this.nilai, required this.warna});

  final double? nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final double f = ((nilai ?? 0) / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(5),
      ),
      child: nilai == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: f,
                child: Container(
                  decoration: BoxDecoration(
                    color: warna,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
    );
  }
}