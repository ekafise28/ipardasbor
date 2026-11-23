// Panel filter dashboard Profil Pasar Wisman: Tahun, Bulan, Kewarganegaraan,
// Nama Pintu (Kanonik). Tiap kolom membuka lembar pilihan ganda (bisa dicari).

import 'package:flutter/material.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/app_sheet.dart';

import '../../../app/app_theme.dart';

import '../models/rekap_filter.dart';

class RekapFilterPanel extends StatelessWidget {
  const RekapFilterPanel({
    super.key,
    required this.filter,
    required this.options,
    required this.loading,
    required this.onChanged,
    required this.onApply,
    required this.onReset,
  });

  final RekapFilter filter;
  final RekapFilterOptions options;
  final bool loading;
  final ValueChanged<RekapFilter> onChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  static List<OpsiPilihan> _opsi(List<String> values) =>
      values.map((String v) => OpsiPilihan(v, v)).toList();

  @override
  Widget build(BuildContext context) {
    final List<OpsiPilihan> opsiBulan = <OpsiPilihan>[
      for (int i = 0; i < namaBulan.length; i++)
        OpsiPilihan('${i + 1}', namaBulan[i]),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadowCard,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Filter Dashboard',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data Visualisasi',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: loading ? null : onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double lebar = (c.maxWidth - 10) / 2;
              Widget kolom(Widget child) =>
                  SizedBox(width: lebar, child: child);

              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: <Widget>[
                  kolom(
                    MultiSelectField(
                      label: 'Tahun',
                      options: _opsi(options.tahun),
                      selected: filter.tahun,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(tahun: v)),
                    ),
                  ),
                  kolom(
                    MultiSelectField(
                      label: 'Bulan',
                      options: opsiBulan,
                      selected: filter.bulan,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(bulan: v)),
                    ),
                  ),
                  SizedBox(
                    width: c.maxWidth,
                    child: MultiSelectField(
                      label: 'Kewarganegaraan',
                      options: _opsi(options.kewarganegaraan),
                      selected: filter.kewarganegaraan,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(kewarganegaraan: v)),
                    ),
                  ),
                  SizedBox(
                    width: c.maxWidth,
                    child: MultiSelectField(
                      label: 'Nama Pintu (Kanonik)',
                      options: _opsi(options.pintu),
                      selected: filter.namaPintu,
                      onChanged: (List<String> v) =>
                          onChanged(filter.copyWith(namaPintu: v)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.filter_alt_rounded, size: 18),
              label: Text(loading ? 'Memuat...' : 'Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }
}