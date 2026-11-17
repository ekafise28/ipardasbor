import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Chip legenda grafik: ketuk untuk menyembunyikan/menampilkan satu garis.
/// [putus] true = garis putus-putus (deret nasional), ditandai kotak pipih.
class LegendChip extends StatelessWidget {
  const LegendChip({
    super.key,
    required this.label,
    required this.warna,
    required this.aktif,
    required this.onTap,
    this.putus = false,
  });

  final String label;
  final Color warna;
  final bool aktif;
  final bool putus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: aktif,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: aktif ? warna.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aktif ? warna : AppTheme.border(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: putus ? 12 : 9,
                height: putus ? 3 : 9,
                decoration: BoxDecoration(
                  color: aktif ? warna : AppTheme.textMuted,
                  shape: putus ? BoxShape.rectangle : BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    decoration: aktif ? null : TextDecoration.lineThrough,
                    color: aktif
                        ? AppTheme.textColor(context)
                        : AppTheme.textSecondary(context),
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