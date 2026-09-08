import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Pilihan status ketidaksesuaian data — multi-pilih (checkbox), mengikuti
/// form Laravel OSS. Kunci opsi masih sementara/dummy sampai backend
/// validasi lanjutan OSS final.
class StatusKetidaksesuaianSelector extends StatelessWidget {
  const StatusKetidaksesuaianSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.keteranganLainnya,
    required this.onKeteranganChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String keteranganLainnya;
  final ValueChanged<String> onKeteranganChanged;

  static const Map<String, String> options = {
    'TIDAK_BEROPERASI': 'Tidak Beroperasi',
    'ALAMAT_TIDAK_DITEMUKAN': 'Alamat Tidak Ditemukan',
    'MENOLAK_DIVERIFIKASI': 'Menolak Diverifikasi',
    'PINDAH_ALAMAT': 'Pindah Alamat',
    'TUTUP_PERMANEN': 'Tutup Permanen',
    'LAINNYA': 'Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    final bool showKeterangan = selected.contains('LAINNYA');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final bool checked = selected.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: checked,
              onSelected: (v) {
                final next = List<String>.from(selected);
                if (v) {
                  next.add(entry.key);
                } else {
                  next.remove(entry.key);
                }
                onChanged(next);
              },
              selectedColor: AppTheme.textOnBrandBadge,
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: checked
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary(context),
              ),
              side: BorderSide(
                color: checked ? AppTheme.primaryColor : AppTheme.border(context),
              ),
              backgroundColor: AppTheme.scaffoldColorDynamic(context),
            );
          }).toList(),
        ),
        if (showKeterangan) ...[
          const SizedBox(height: 12),
          TextFormField(
            initialValue: keteranganLainnya,
            decoration: InputDecoration(
              labelText: 'Keterangan Lainnya *',
              hintText: 'Jelaskan ketidaksesuaian lainnya',
              filled: true,
              fillColor: AppTheme.scaffoldColorDynamic(context),
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
            ),
            maxLines: 3,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Wajib diisi.'
                : null,
            onChanged: onKeteranganChanged,
          ),
        ],
      ],
    );
  }
}