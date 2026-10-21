import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/proyek_data_item.dart';
import 'data_proyek_card.dart';

/// Detail satu proyek. Semua datanya sudah ada di baris daftar, jadi tidak
/// ada request tambahan.
Future<void> showDataProyekDetailSheet(
  BuildContext context,
  ProyekDataItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) =>
          _DetailIsi(item: item, controller: controller),
    ),
  );
}

class _DetailIsi extends StatelessWidget {
  const _DetailIsi({required this.item, required this.controller});

  final ProyekDataItem item;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final Color warna = warnaRisikoProyek(item.risiko);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: <Widget>[
        Text(
          item.namaPerusahaan,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            TintChip(label: item.risiko ?? 'Risiko -', color: warna),
            if (item.statusModal != null)
              TintChip(label: item.statusModal!, color: AppTheme.primaryColor),
            if (item.skalaUsaha != null)
              TintChip(label: item.skalaUsaha!, color: AppTheme.secondaryColor),
          ],
        ),
        const SizedBox(height: 14),
        MutedPanel(
          padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
          child: Column(
            children: <Widget>[
              KodeRow(label: 'NIB', value: item.nib),
              KodeRow(label: 'KBLI', value: item.kbli),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Baris(
          label: 'Judul KBLI',
          value: item.judulKbli == null
              ? '-'
              : item.versiKbli == null
              ? item.judulKbli!
              : '${item.judulKbli} (KBLI ${item.versiKbli})',
        ),
        _Baris(label: 'Investasi', value: rupiahProyek(item.jumlahInvestasi)),
        _Baris(
          label: 'Tenaga kerja',
          value: item.jumlahTenagaKerja == null
              ? '-'
              : '${formatNumber(item.jumlahTenagaKerja!)} orang',
        ),
        _Baris(label: 'Alamat usaha', value: item.alamat ?? '-'),
        _Baris(label: 'Kabupaten/Kota', value: item.kabKota ?? '-'),
        _Baris(label: 'Provinsi', value: item.provinsi ?? '-'),
      ],
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}