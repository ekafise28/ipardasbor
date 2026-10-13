import 'package:flutter/material.dart';

/// Dua ikon kecil untuk suffixIcon TextField: tempel dari clipboard dan
/// scan dari foto/screenshot. Salah satu callback null = ikon nonaktif.
class OcrFieldActions extends StatelessWidget {
  const OcrFieldActions({
    super.key,
    required this.onPaste,
    required this.onScan,
  });

  final VoidCallback? onPaste;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPaste,
          tooltip: 'Tempel dari clipboard',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.content_paste_rounded, size: 20),
        ),
        IconButton(
          onPressed: onScan,
          tooltip: 'Scan dari foto atau screenshot',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.document_scanner_outlined, size: 20),
        ),
      ],
    );
  }
}