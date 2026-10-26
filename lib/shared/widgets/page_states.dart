import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Isi yang selalu bisa ditarik (pull-to-refresh) dan minimal setinggi
/// area yang tersedia. Dipakai untuk state error di dalam RefreshIndicator,
/// karena RefreshIndicator butuh anak yang bisa di-scroll.
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tampilan daftar kosong. Letakkan sebagai item di dalam ListView.
///
/// Tombol aksi hanya muncul kalau [actionLabel] dan [onAction] diisi,
/// misalnya "Hapus semua filter" saat kosong karena filter.
class EmptyListState extends StatelessWidget {
  const EmptyListState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.filter_alt_off_rounded,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bool adaAksi = actionLabel != null && onAction != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 56, color: AppTheme.textSecondary(context)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary(context),
            ),
          ),
          if (adaAksi) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Footer infinite scroll: spinner saat memuat, atau pesan + tombol
/// "Coba lagi" kalau halaman berikutnya gagal dimuat.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.gagal,
    required this.onCobaLagi,
    this.pesan,
  });

  final bool gagal;
  final String? pesan;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    if (!gagal) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
      child: Column(
        children: <Widget>[
          Text(
            pesan ?? 'Gagal memuat data berikutnya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onCobaLagi,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

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