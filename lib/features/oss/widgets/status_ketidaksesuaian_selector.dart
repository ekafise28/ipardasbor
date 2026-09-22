import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Selector status ketidaksesuaian/hasil pengawasan - multi-pilih
/// (checkbox). Generik: dipakai OSS (status ketidaksesuaian validasi) dan
/// Non-OSS (status hasil pengawasan sesuai kondisi NIB), dengan [options]
/// dan [keteranganKey] berbeda untuk masing-masing.
class StatusKetidaksesuaianSelector extends StatelessWidget {
  const StatusKetidaksesuaianSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.keteranganLainnya,
    required this.onKeteranganChanged,
    this.keteranganKey = 'LAINNYA',
    this.keteranganLabel = 'Keterangan Lainnya *',
  });

  /// Kunci -> label yang ditampilkan sebagai checkbox.
  final Map<String, String> options;

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Kunci di [options] yang memunculkan field Keterangan (wajib diisi).
  final String keteranganKey;
  final String keteranganLainnya;
  final ValueChanged<String> onKeteranganChanged;
  final String keteranganLabel;

  /// Status Hasil Pengawasan OSS - muncul hanya saat hasil validasi
  /// TIDAK_VALID. Disimpan ke kolom status_ketidaksesuaian, persis
  /// mengikuti $statusList di OssValidasiLanjutanController (web).
  static const Map<String, String> ossStatusHasilOptions = {
    'NIB_ADA_KBLI_SESUAI_NKU_ADA_TIDAK_VALID':
        'NIB ada, KBLI Sesuai, NKU ada tetapi tidak valid',
    'KBLI_TIDAK_ADA': 'KBLI tidak ada',
    'NKU_TIDAK_ADA': 'NKU tidak ada',
    'KBLI_NKU_TIDAK_ADA': 'KBLI dan NKU tidak ada',
    'KBLI_TIDAK_SESUAI': 'KBLI tidak sesuai',
    'KBLI_PENDUKUNG': 'KBLI pendukung',
    'IZIN_BELUM_TERVERIFIKASI': 'Izin belum terbit/terverifikasi',
    'LAINNYA': 'Lainnya',
  };

  /// Status hasil pengawasan Non-OSS saat memiliki_nib == 'TIDAK TAHU'.
  /// Untuk 'TIDAK', hanya ada satu pilihan tetap (lihat non_oss_form_page).
  static const Map<String, String> nonOssTidakTahuOptions = {
    'TIDAK_BERTEMU_PEMILIK': 'Tidak Bertemu Pemilik',
    'PENGELOLA_TIDAK_BISA_MEMBERIKAN_DATA':
        'Pengelola Tidak Bisa Memberikan Data',
    'LAINNYA': 'Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    final bool showKeterangan = selected.contains(keteranganKey);

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
                color: checked
                    ? AppTheme.primaryColor
                    : AppTheme.border(context),
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
              labelText: keteranganLabel,
              hintText: 'Jelaskan ketidaksesuaian lainnya',
              filled: true,
              fillColor: AppTheme.scaffoldColorDynamic(context),
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
            ),
            maxLines: 3,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
            onChanged: onKeteranganChanged,
          ),
        ],
      ],
    );
  }
}
