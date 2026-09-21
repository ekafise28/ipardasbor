import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Tampilan error koneksi/gagal-muat yang konsisten dipakai di berbagai
/// halaman (Dashboard, Riwayat, Profil, dll).
///
/// [title] boleh disesuaikan per halaman (mis. "Dashboard gagal dimuat"),
/// dengan default generik "Gagal memuat data" kalau tidak diisi.
/// [onRetry] cukup [VoidCallback] - pemanggil membungkus proses async-nya
/// sendiri lewat closure, mis. `onRetry: () => _muatUlang()`.
class ConnectionErrorState extends StatelessWidget {
  const ConnectionErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Gagal memuat data',
    this.icon = Icons.cloud_off_rounded,
    this.isRetrying = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;

  /// Saat true, tombol menampilkan spinner kecil dan dinonaktifkan.
  /// Opsional - banyak pemanggil langsung mengganti seluruh body ke state
  /// loading penuh saat retry ditekan, sehingga spinner ini mungkin tidak
  /// sempat terlihat lama. Tetap disediakan untuk kasus yang butuh.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: AppTheme.dangerBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.danger, size: 39),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: isRetrying ? null : onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.surfaceMuted(context),
                disabledForegroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: isRetrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                isRetrying ? 'Memuat...' : 'Coba Lagi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}