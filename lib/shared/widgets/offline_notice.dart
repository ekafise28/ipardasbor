import 'package:flutter/material.dart';

import '../../core/network/network_status.dart';

/// Kotak info kecil, hanya tampil saat tidak ada jaringan.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, this.pesan = NetworkGuard.pesanVerifikasi});
  final String pesan;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.instance,
      builder: (_, bool offline, _) {
        if (!offline) return const SizedBox.shrink();
        const Color warna = Color(0xFFB45309);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: warna.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, size: 18, color: warna),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pesan,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: warna,
                    fontWeight: FontWeight.w600,
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