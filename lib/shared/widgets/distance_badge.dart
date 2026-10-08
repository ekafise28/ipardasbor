import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// "350 m", "2,4 km", "12 km".
String formatJarak(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

class DistanceBadge extends StatelessWidget {
  const DistanceBadge({super.key, required this.km});
  final double km;

  @override
  Widget build(BuildContext context) {
    final Color warna = AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.near_me_rounded, size: 12, color: warna),
          const SizedBox(width: 4),
          Text(
            formatJarak(km),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: warna),
          ),
        ],
      ),
    );
  }
}