import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/proyek_data_item.dart';

String rupiahProyek(int? v) => v == null ? '-' : 'Rp ${formatNumber(v)}';

class DataProyekCard extends StatelessWidget {
  const DataProyekCard({super.key, required this.item, required this.onTap});

  final ProyekDataItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.warnaRisiko(item.risiko);
    final String tenagaKerja = item.jumlahTenagaKerja == null
        ? '-'
        : formatNumber(item.jumlahTenagaKerja!);

    return StripCard(
      stripColor: warna,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CardTitleRow(
            title: item.namaPerusahaan,
            statusLabel: item.risiko ?? 'Risiko -',
            statusColor: warna,
          ),
          const SizedBox(height: 10),
          MutedPanel(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            child: Column(
              children: <Widget>[
                KodeRow(label: 'NIB', value: item.nib),
                KodeRow(label: 'KBLI', value: item.kbli),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (item.judulKbli != null)
            ListInfoRow(
              icon: Icons.category_outlined,
              text: item.judulKbli!,
              maxLines: 2,
            ),
          ListInfoRow(
            icon: Icons.place_outlined,
            text: item.lokasi,
            maxLines: 2,
          ),
          ListInfoRow(
            icon: Icons.payments_outlined,
            text:
                '${rupiahProyek(item.jumlahInvestasi)} · $tenagaKerja tenaga kerja',
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (item.statusModal != null)
                TintChip(label: item.statusModal!, color: AppTheme.primaryColor),
              if (item.skalaUsaha != null)
                TintChip(
                  label: item.skalaUsaha!,
                  color: AppTheme.secondaryColor,
                ),
              if (item.versiKbli != null)
                TintChip(
                  label: 'KBLI ${item.versiKbli}',
                  color: AppTheme.textSecondary(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}