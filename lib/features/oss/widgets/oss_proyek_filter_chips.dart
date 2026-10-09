import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../models/oss_proyek_filter.dart';
import '../models/oss_proyek_page_result.dart';

/// Baris chip filter cepat status verifikasi (Semua / Belum / Terverifikasi /
/// Tidak valid). Memakai warna yang sama dengan chip status di kartu.
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

  String _label(_Opsi o) {
    final OssProyekRingkasan? r = ringkasan;
    if (r == null) return o.label;

    final int n = switch (o.nilai) {
      OssProyekOpsi.statusBelum => r.belum,
      OssProyekOpsi.statusSudah => r.sudah,
      OssProyekOpsi.statusTidakValid => r.tidakValid,
      _ => r.total,
    };
    return '${o.label} ${_fmt(n)}';
  }

  static String _fmt(int angka) {
    final String s = angka.toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static const List<_Opsi> _opsi = <_Opsi>[
    _Opsi(null, 'Semua', AppTheme.primaryColor),
    _Opsi(OssProyekOpsi.statusBelum, 'Belum', AppTheme.warning),
    _Opsi(OssProyekOpsi.statusSudah, 'Terverifikasi', AppTheme.success),
    _Opsi(OssProyekOpsi.statusTidakValid, 'Tidak valid', AppTheme.danger),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _opsi.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final _Opsi o = _opsi[i];
          final bool aktif = o.nilai == selected;

          return ChoiceChip(
            label: Text(_label(o)),
            selected: aktif,
            showCheckmark: false,
            onSelected: (_) => onChanged(o.nilai),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: aktif ? o.warna : AppTheme.textSecondary(context),
            ),
            selectedColor: o.warna.withValues(alpha: 0.14),
            backgroundColor: AppTheme.surface(context),
            side: BorderSide(
              color: aktif ? o.warna : AppTheme.border(context),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _Opsi {
  const _Opsi(this.nilai, this.label, this.warna);

  final String? nilai;
  final String label;
  final Color warna;
}

/// Data satu chip filter aktif.
class OssFilterChipData {
  const OssFilterChipData({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}

/// Chip filter aktif; tiap chip bisa dihapus dengan satu ketukan.
class OssActiveFilterChips extends StatelessWidget {
  const OssActiveFilterChips({
    super.key,
    required this.chips,
    required this.onResetAll,
  });

  final List<OssFilterChipData> chips;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          for (final OssFilterChipData c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(c.label),
                onDeleted: c.onRemove,
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                deleteButtonTooltipMessage: 'Hapus filter ${c.label}',
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.10),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (chips.length > 1)
            TextButton(
              onPressed: onResetAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Reset'),
            ),
        ],
      ),
    );
  }
}