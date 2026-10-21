// lib/features/peta_industri/widgets/risiko_warna.dart

import 'package:flutter/material.dart';

/// Warna risiko, sama dengan web: R hijau, MR oranye, MT ungu, T merah.
Color warnaRisiko(String label) {
  switch (label.trim().toLowerCase()) {
    case 'rendah':
      return const Color(0xFF4CAF50);
    case 'menengah rendah':
      return const Color(0xFFFF9800);
    case 'menengah tinggi':
      return const Color(0xFF9C27B0);
    case 'tinggi':
      return const Color(0xFFF44336);
    default:
      return const Color(0xFF90A4AE);
  }
}