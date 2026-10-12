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