import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

/// Warna tiap jenis pintu masuk. Nama tak dikenal memakai warna netral.
Color warnaPintu(String pintu) {
  switch (pintu) {
    case 'Pintu Udara':
      return const Color(0xFF1565C0);
    case 'Pintu Laut':
      return const Color(0xFF00897B);
    case 'Pintu Darat':
      return const Color(0xFFEF6C00);
    default:
      return AppTheme.menuProfil;
  }
}

IconData ikonPintu(String pintu) {
  switch (pintu) {
    case 'Pintu Udara':
      return Icons.flight_rounded;
    case 'Pintu Laut':
      return Icons.directions_boat_rounded;
    case 'Pintu Darat':
      return Icons.directions_bus_rounded;
    default:
      return Icons.login_rounded;
  }
}