import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../models/oss_proyek_item.dart';

/// Kartu satu usaha pada daftar verifikasi OSS.
///
/// - Strip warna di sisi kiri + satu chip status (Belum / Terverifikasi /
///   Tidak valid) supaya status terbaca sekilas saat scroll.
/// - Seluruh kartu bisa disentuh: belum diverifikasi -> Verifikasi,
///   sudah diverifikasi -> Detail.
/// - NIB dan NKU punya tombol salin.
class OssProyekCard extends StatelessWidget {
  const OssProyekCard({
    super.key,
    required this.item,
    required this.onVerifikasi,
    required this.onDetail,
    this.highlight = false,
  });

  final OssProyekItem item;

  /// True sebentar setelah kartu ini baru selesai diverifikasi: latar kartu
  /// diwarnai tipis dengan warna status lalu kembali normal.
  final bool highlight;
  final VoidCallback onVerifikasi;
  final VoidCallback onDetail;

  /// Aksi utama kartu. Null = kartu tidak bisa ditekan.
  VoidCallback? get _aksiUtama {
    if (!item.sudahDiverifikasi) return onVerifikasi;
    return item.pengawasanId == null ? null : onDetail;
  }

  _StatusUi get _status {
    if (item.tidakValid) {
      return const _StatusUi(
        label: 'Tidak valid',
        color: AppTheme.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (item.sudahDiverifikasi) {
      return const _StatusUi(
        label: 'Terverifikasi',
        color: AppTheme.success,
        icon: Icons.check_circle_rounded,
      );
    }
    return const _StatusUi(
      label: 'Belum diverifikasi',
      color: AppTheme.warning,
      icon: Icons.schedule_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _StatusUi status = _status;
    final BorderRadius radius = BorderRadius.circular(14);

    final String modalRisiko = <String?>[
      item.statusPenanamanModal,
      item.uraianRisiko,
    ].whereType<String>().join(' · ');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: highlight
          ? Color.alphaBlend(
              status.color.withValues(alpha: 0.12),
              AppTheme.surface(context),
            )
          : AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppTheme.border(context)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: _aksiUtama,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Strip status di sisi kiri.
              Container(width: 4, color: status.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.namaPerusahaan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _KodeBlock(nib: item.nib, nku: item.nku),
                      const SizedBox(height: 10),
                      if (modalRisiko.isNotEmpty)
                        _InfoRow(
                          icon: Icons.shield_outlined,
                          text: modalRisiko,
                        ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: item.lokasiRingkas,
                        maxLines: 2,
                      ),
                      if (item.alamat.isNotEmpty)
                        _InfoRow(
                          icon: Icons.home_work_outlined,
                          text: item.alamat,
                          maxLines: 2,
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: item.sudahDiverifikasi
                            ? OutlinedButton.icon(
                                onPressed: item.pengawasanId == null
                                    ? null
                                    : onDetail,
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('Lihat Detail'),
                              )
                            : FilledButton.icon(
                                onPressed: onVerifikasi,
                                icon: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 18,
                                ),
                                label: const Text('Verifikasi'),
                              ),
                      ),
                    ],
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

class _StatusUi {
  const _StatusUi({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _StatusUi status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(status.icon, size: 13, color: status.color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blok kecil berlatar tint berisi NIB dan NKU, masing-masing bisa disalin.
class _KodeBlock extends StatelessWidget {
  const _KodeBlock({required this.nib, required this.nku});

  final String nib;
  final String nku;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          _KodeRow(label: 'NIB', value: nib),
          _KodeRow(label: 'NKU', value: nku),
        ],
      ),
    );
  }
}

class _KodeRow extends StatelessWidget {
  const _KodeRow({required this.label, required this.value});

  final String label;
  final String value;

  Future<void> _salin(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.selectionClick();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label disalin'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool kosong = value.isEmpty;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            kosong ? '-' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 17,
            tooltip: 'Salin $label',
            color: AppTheme.textSecondary(context),
            onPressed: kosong ? null : () => _salin(context),
            icon: const Icon(Icons.copy_rounded),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}