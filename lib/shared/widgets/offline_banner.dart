import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/cache/cache_status.dart';

/// Strip kuning tipis, hanya tampil saat data berasal dari cache.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: CacheStatus.instance,
      builder: (_, DateTime? waktu, _) {
        if (waktu == null) return const SizedBox.shrink();
        const Color warna = Color(0xFFB45309);
        return Container(
          width: double.infinity,
          color: warna.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, size: 15, color: warna),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode offline · data per '
                  '${DateFormat('dd MMM, HH:mm').format(waktu)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: warna,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}