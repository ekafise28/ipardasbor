import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/network/network_status.dart';

/// Banner status koneksi di puncak halaman Sinkronisasi, beserta waktu
/// sinkronisasi terakhir. Mengikuti [NetworkStatus] secara langsung.
///
/// Status ini hanya menandakan ada/tidaknya jaringan di perangkat; server
/// tetap dicek saat proses kirim berjalan.
class SyncConnectionBanner extends StatelessWidget {
  const SyncConnectionBanner({super.key, required this.lastSyncText});

  final String lastSyncText;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatus.instance,
      builder: (BuildContext context, bool offline, Widget? _) {
        final Color color = offline ? AppTheme.warning : AppTheme.success;
        final Color lightBackground = offline
            ? AppTheme.warningBackground
            : AppTheme.menuKeamananBg;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.tintBackground(context, color, lightBackground),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            offline
                                ? 'Tidak ada koneksi'
                                : 'Terhubung ke Internet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                          size: 15,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offline
                          ? 'Data dikirim setelah perangkat online'
                          : 'Siap mengirim data ke server',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Terakhir Sync',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastSyncText,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}