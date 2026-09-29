import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Ikon kecil untuk suffixIcon TextField: scan satu field.
class OcrScanIconButton extends StatelessWidget {
  const OcrScanIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Scan dari foto atau screenshot',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.document_scanner_outlined, size: 20),
    );
  }
}

/// Tombol utama: scan semua field sekaligus.
class OcrScanMainButton extends StatelessWidget {
  const OcrScanMainButton({
    super.key,
    required this.onPressed,
    this.label = 'Scan dari foto atau screenshot',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.document_scanner_outlined, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}